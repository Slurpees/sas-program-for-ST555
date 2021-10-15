/******** Readme*********

Programmed by: Kaida Lou
Programmed on: 2021-09-05
Programmed to: Create solution to ST555-Homework01

Modified by: N/A
Modified on: N/A
Modified to: N/A
*/

x "cd L:\st555\Data";
libname InputDS ".";/* the library points to the provided data sets*/
x "cd S:\.";/* any results will output to this directory*/
libname HW1 ".";/* the library points to any data sets SAS creats*/
ods _all_ close;
ods pdf file = "HW1 Lou IPUMS Report.pdf" style = Plateau STARTPAGE = bygroup;/* outputing result as a pdf file with a specified style*/
ods noproctitle;/* suppress the writing of system procedure title */
options nodate;
/*ods trace on;*/
footnote;
ods exclude EngineHost;

* ouput the first tables to show information about dataset;
proc contents data = InputDS.Ipums2005Basic varnum;
  title "Descriptor Information Before Sorting";
run;

* creat a sorted dataset and it will be used by other procedures;
proc sort data = InputDS.Ipums2005Basic out = HW1.Ipums2005Basic;
  by DESCENDING Ownership state METRO City;
run;

* output sorted dataset information;
ods exclude EngineHost;
proc contents data = HW1.Ipums2005Basic varnum;
  title "Descriptor Information After Sorting";
run;

proc format;
  value HomeValueFmt
  low - 95000       = "Tier 1"
  95000 <- 162500   = "Tier 2"
  162500 <- 350000  = "Tier 3"
  350000 <- 1000000 = "Tier 4"
  9999999           = "NA"
  ;
*set sup a cityFmt used to update the city variable when it is not identifiable;
  value $ cityFmt 
  "Not in identifiable city (or size group)" = "N/A" 
  ;
run;

footnote1 j = l "Only for North and South Carolina";
footnote2 j = l "Only for Metro values of 2 and 4";
footnote3 j = l "Only for households with income between $165,000 and $175,000 (inclusive)";
footnote4 j = l "Tier 1=Up to $95,000, Tier 2=Up to $162,500, Tier 3=Up to $350,000, Tier 4=Up to $1,000,000,";
footnote5 j = l "NA = $9,999,999";
title "Listing of Payments, Income, and Home Value";
title2 HEIGHT = 8PT "Including Ownership and State within Ownership Totals" ;

proc print data = HW1.Ipums2005Basic noobs label;
  label metro     = "Metro Code" 
        HH_income = "Household's Income"
		State = "State Name"
		Ownership = "Ownership Category"
		City = "City Name"
		Home_Value = "Home Value"
		Mortgage_Payment = "Mortgage Payment"
  ;
  by DESCENDING Ownership state metro city;
  id Ownership state METRO City;
* when metro and preceding varibales are different SAS will print a new page;
    pageby METRO;
  var HH_Income Home_Value Mortgage_Payment;
  sum HH_Income Mortgage_Payment; 
    sumby state;
  where state in ("North Carolina" "South Carolina") 
        and (metro = 2 or metro = 4) 
        and (HH_income le 175000 and HH_income ge 165000)
  ;
  format HH_income dollar11. 
         home_value HomeValueFmt. 
         Mortgage_Payment dollar8.
         city          $cityFmt40. /*maybe format of city makes the length of city update 
		                             3, so I update the length to 40 in oder to make sure 
		                             whole city variable could be print*/
  ;
run;

title1 "Selected Numerical Summaries of US Census IPUMS Data";
title2 height = 8 pt "by Ownership and Home Value Classification" ;
footnote  j = l "Excluding Alaska and Hawaii";
footnote2 j = l "Tier 1=Up to $95,000, Tier 2=Up to $162,500, Tier 3=Up to $350,000, Tier 4=Up to $1,000,000,";
footnote3 j = l "NA = $9,999,999";

proc means data = HW1.Ipums2005Basic nonobs n min q1 median q3 max maxdec = 1 ;
  label HH_income        = "Household's Income"
        Mortgage_Payment = "Mortgage Payment"
		Ownership        = "Ownership Category"
        Home_Value       = "Home Value"
  ;
  class Ownership Home_value;
  var HH_income Mortgage_Payment;
  where state notin  ("Alaska", "Hawaii");
  format home_value HomeValueFmt. ;
run;
title1 "Total Population by Ownership and Ownership by Metro";
title2 "and Ownership by Home Value Classification" ;

proc freq data = HW1.Ipums2005Basic ;
  table Ownership  ;
  table Ownership*metro /format = comma13. ;
  label Ownership  = "Ownership Category"
        Metro      = "Metro Code"
		Home_value = Home Value
  ;
  where state notin  ("Alaska", "Hawaii") and metro ne 1;
  table Ownership*home_value/ norow nocol format = comma13.;
  weight CITYPOP;
  format home_value homeValueFmt.;
run;

/*ods trace off;*/
footnote;
title;
ods pdf close; 
ods exclude none;


quit;
