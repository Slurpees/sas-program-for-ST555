/******** Readme*********

Programmed by: Kaida Lou
Programmed on: 2021-10-20
Programmed to: Create solution to ST555-Homework06

Modified by: N/A
Modified on: N/A
Modified to: N/A

*/

/* using reative path to refer some libraries and filepaths*/
x "cd L:\st555\Data";
libname InputDS ".";
filename RawData ".";
x "cd L:\st555\Results";
libname Results ".";
x "cd S:\SAS Working Directory\hw6";
/*my leadproject has been saved in HW4*/
libname HW6 ".";
filename HW6 ".";
/* set up some global statements(no other destination except listig and pdf,
no proc title, no system date)*/ 
ods _all_ close;
ods noproctitle;
options nodate;

/*this macro variable is used to set options for proc compare*/
%let CompOpts = outbase 
                outcompare
                outdiff
                outnoequal
                noprint
                method = absolute
                criterion = 1E-15;

/* read in Cities.txt*/
data hw6.cities(drop = _City);
  infile Rawdata("Cities.txt") firstobs = 2 dlm ="09"x;
  attrib City length = $40.;
  input _City : $50. CityPop : comma.;
  City = tranwrd(_City,"/","-");
run;

/* read in States.txt*/
data hw6.states;
  infile Rawdata("States.txt") firstobs = 2 dlm ="0920"x;
  input Serial State & $20. City & $char40.;
run;

/* read in Contract.txt, set up variables attributes and order in advance*/
data hw6.contract;
  attrib Serial label = "Household Serial Number"
         CountyFIPS length = $3. label = "County FIPS Code"
         Metro label = "Metro Status Code"
         MetroDesc length = $32. label = "Metro Status Description"
         CityPop format = comma6. label = "City Population (in 100s)"
         MortPay format = dollar6. label = "Monthly Mortgage Payment"
         HHI     format = dollar10. label = "Household Income"
         HomeVal format = dollar10. label = "Home Value"
         State length = $20. label = "State, District, or Territory"
         City length = $40. label = "City Name"
         MortStat length = $45. label = "Mortgage Status"
         Ownership length = $6. label = "Ownership Status";
  infile Rawdata("Contract.txt") firstobs = 2 dlm = "09"x truncover;
  input Serial Metro CountyFIPS $ MortPay : comma. HHI : comma. HomeVal : comma.;
run;

/*read in Mortgaged.txt*/
data hw6.mortgaged;
  infile Rawdata("Mortgaged.txt") firstobs = 2 dlm = "09"x truncover;
  input Serial Metro CountyFIPS : $3. MortPay : comma. HHI : comma. HomeVal : comma.;
run;

/*creat custom fromats which will be used for cleaning and dealing with data later*/
proc format library = hw6;
  value MetroDesc
    0 = "Indeterminable"
    1 = "Not in a Metro Area"
    2 = "In Central/Principal City"
    3 = "Not in Central/Principal City"
    4 = "Central/Principal Indeterminable"
  ;
run;

options FMTSEARCH = (HW6);

/*vartical joins (concatenate) and clean data*/
data hw6._01HW6LouIpums2005(drop = FIPS);
  set hw6.contract(in = incontract)
      hw6.mortgaged(in = inmortgaged)
      InputDS.freeclear(in = infreeclear)
      InputDS.renters(in = inrenters);
  if not missing(FIPS) 
    then CountyFIPS = FIPS; 
  if missing(HomeVal)
    then HomeVal = .M;
  if inrenters eq 0 
    then Ownership = "Owned";
  select;
    when(incontract)  MortStat = "Yes, contract to purchase";
    when(inmortgaged) MortStat = "Yes, mortgaged/ deed of trust or similar debt";
    when(infreeclear) MortStat = "No, owned free and clear";
    when(inrenters) do;
      MortStat = "N/A";
      HomeVal  = .R;
      Ownership = "Rented";
    end;
  end;
  MetroDesc = put(Metro, MetroDesc.);
run;

/*sort the data set by serial for merging data later*/
proc sort data = hw6._01HW6LouIpums2005 out = hw6._02HW6LouIpums2005;
  by serial;
run;

/*sort the city data set by city for merging data later*/
proc sort data = hw6.cities out = hw6.sortedcities;
  by city;
run;

/*sort the state data set by city for merging data later*/
proc sort data = hw6.states out = hw6.sortedstates;
  by city;
run;

/* march merge (one-to-many)*/
data hw6.citiesandstates;
  merge hw6.sortedcities
        hw6.sortedstates;
  by city;
run;

/* sort city and state dataset for merging with the main dataset later*/
proc sort data = hw6.citiesandstates;
  by serial;
run;

/*match merge (one-to-one)*/
data hw6.HW6LouIpums2005;
  merge hw6._02HW6LouIpums2005 hw6.citiesandstates;
run;

/*ouput my data set variables attributes*/
ods output position = hw6.louprodesc(drop = member); 
proc contents data = hw6.HW6LouIpums2005 varnum;
run;

/*electronically validate my descriptor portion against Duggins'*/
proc compare base = results.Hw6dugginsdesc 
             compare = hw6.louprodesc
             out = HW6.diffa
             &CompOpts
;

/*electronically validate my content portion against Duggins'*/
proc compare base = results.Hw6dugginsipums2005 
             compare = hw6.HW6LouIpums2005
             out = HW6.diffb
             &CompOpts
;
run;

/*set up pdf parameters for reporting my data set, including not insert page break and title*/
ods pdf dpi = 300 file = "HW6 Lou IPUMS Reprot.pdf";
ods pdf startpage = NEVER;
title "Listing of Households in NC with Incomes Over $500,000";

/*using report procedure to output as duggins's do*/
proc report data = hw6.HW6LouIpums2005;
  column City Metro MortStat HHI HomeVal;
  where State eq "North Carolina" and HHI gt 500000;
/*  define HomeVal /display;*/  /*if we want to make special missing values appear,
                                  we can run this line of code*/
run;

/*select some specified tables by absolute to output*/
ods select  Univariate.CityPop.BasicMeasures
            Univariate.CityPop.Quantiles
            Univariate.CityPop.Histogram.Histogram
            Univariate.MortPay.Quantiles
            Univariate.HHI.BasicMeasures
            Univariate.HHI.ExtremeObs
            Univariate.HomeVal.BasicMeasures
            Univariate.HomeVal.ExtremeObs
            Univariate.HomeVal.MissingValues
;
ods proctitle;
title;

/*using univariate procedure to output as duggins's does*/
proc UNIVARIATE data = hw6.HW6LouIpums2005;
  var CityPop MortPay HHI HomeVal;
  histogram CityPop / kernel (c = 0.79);
run;

/*insert a page break here and set up graph dpi, width, title and footnote*/
ods pdf startpage = NOW;
title1 "Distribution of City Population";
title2 "(For Households in a Recognized City)";
footnote justify = left "Recognized cities have a non-zero value for City Population.";
ods graphics on / reset width=5.5in;

/*using sgplot procedure to output as duggins's does, including a histogram graph*/
proc sgplot data = hw6.Hw6louipums2005;
  histogram CityPop / scale = proportion;
  density CityPop / type = kernel lineattrs = (color = red thickness = 3);
  where Citypop ne 0;
  keylegend / location = inside;
  yaxis valuesformat = percent.
        display = (nolabel);
run;

title "Distribution of Household Income Stratified by Mortgage Status";
footnote "Kernel estimate parameters were determined automatically.";

/*using sgplot procedure to output as duggins's does, including a series of 
histogram graph by Mortstat variables*/
proc sgpanel data = hw6.Hw6louipums2005 NOAUTOLEGEND;
  panelby Mortstat / NOVARNAME;
  histogram HHI / scale = proportion;
  density HHI / type = kernel lineattrs = (color = red);
  rowaxis display = (nolabel) 
          valuesformat = percent.;
run;

title;
footnote;
ods pdf close;
options date;
ods listing;
quit;
