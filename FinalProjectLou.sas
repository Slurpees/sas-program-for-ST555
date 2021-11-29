/******** Readme*********

Programmed by: Kaida Lou
Programmed on: 2021-11-28
Programmed to: Create a solution to ST555-Final Project A

Modified by: N/A
Modified on: N/A
Modified to: N/A

*/

/* using reative path to refer the dataset file and create the rawdata filepath*/
x "cd L:\st555\Data\BookData\BeverageCompanyCaseStudy";
libname InputDS ".";
filename RawData ".";
/*create the Inputfmt where some formats are saved in*/
x "cd L:\st555\Data";
libname InputFmt ".";
option fmtsearch=(inputfmt Final); 
/*create the Final Library to save all my results*/
x "cd S:\SAS\FinalA";
libname Final ".";

/* set up some global statements(no other destination 
no proc title, no system date)*/ 
ods _all_ close;
ods noproctitle;
options nodate;

/* create several user-defined formats for produce the productnames and save them in to the Final library*/
proc format library = Final; 
  value $PronameEnergy(fuzz = 0)
    "1" = "Zip-Orange"
    "2" = "Zip-Berry"	
    "3" = "Zip-Grape"	
    "4" = "Diet Zip-Orange"	
    "5" = "Diet Zip-Berry"	
    "6" = "Diet Zip-Grape"	
    "7" = "Big Zip-Berry"	
    "8" = "Big Zip-Grape"	
    "9" = "Diet Big Zip-Berry"	
    "10" = "Diet Big Zip-Grape"	
    "11" = "Mega Zip-Orange"	
    "12" = "Mega Zip-Berry"	
    "13" = "Diet Mega Zip-Orange"	
    "14" = "Diet Mega Zip-Berry"	
  ;
  value $PronameOther(fuzz = 0)
    "1" = "Non-Soda Ades-Lemonade"
    "2" = "Non-Soda Ades-Diet Lemonade"	
    "3" = "Non-Soda Ades-Orangeade"	
    "4" = "Non-Soda Ades-Diet Orangeade"	
    "5" = "Nutritional Water-Orange"	
    "6" = "Nutritional Water-Grape"	
    "7" = "Diet Nutritional Water-Orange"	
    "8" = "Diet Nutritional Water-Grape"
  ;
  value South(fuzz = 0)
    13 = "Georgia"
    37 = "North Carolina"
    45 = "South Carolina"
  ;
  value $Noncolasoda(fuzz = 0)
    "Citrus Splash" = "Citrus" 
    "Grape Fizzy" = "Grape"
    "Lemon-Lime" = "Lemon-Lime"
    "Orange Fizzy" = "Orange"
    "Professor Zesty" = "Zesty"
  ;
run;

/* connecting to the 2016data Microsoft Access database*/
libname data2016 access 'L:\st555\Data\BookData\BeverageCompanyCaseStudy\2016Data.accdb';
/*store the county table into my dataset library*/
data Final.counties(drop = state county);
  length stateFIPS 8. 
         countyFIPS 8.;
  set data2016.counties;
  stateFIPS = state;
  countyFIPS = county;
run;
/*disconnect to the data2016*/
libname data2016 clear;

/* read in the non-cola-nascga dataset and use one formatted input to read the Data variable*/
data Final.NonColaSouth;
  infile rawdata("Non-Cola--NC,SC,GA.dat") firstobs = 7;
  input StateFIPS 1-2 CountyFIPS 3-5 ProductName$ 6-25 Size$ 26-35
        UnitSize 36-38 Date mmddyy10. Unitssold 49-55;
run;

/*read in Energy--NC,SC,GA file using list-based input*/
data Final.EnergySouth;
  infile rawdata("Energy--NC,SC,GA.txt") dlm = "09"x firstobs = 2;
  input StateFIPS CountyFIPS ProductName : $25. Size$
        UnitSize Date date9. Unitssold;
run;

/*read in Other?NC,SC,GA.csv file using list-based input styles.*/
data Final.OtherSouth;
  infile rawdata("Other--NC,SC,GA.csv") dlm = "2C"x firstobs = 2;
  input StateFIPS CountyFIPS ProductName: $50. Size$
        UnitSize Date date7. Unitssold;
run;

/*read in Non-Cola--DC-MD-VA.dat file using only formatted input*/
data Final.NonColaNorth;
  infile rawdata("Non-Cola--DC-MD-VA.dat") firstobs = 5;
  input StateFIPS 2. CountyFIPS 3. Code & $200. Date : anydtdte20. Unitssold;
run;*The using of informat anydtdte20. is got from https://documentation.sas.com/doc/en/vdmmlcdc/8.1/leforinforref/n04jh1fkv5c8zan14fhqcby7jsu4.htm;

/*read in Energy--DC-MD-VA.txt file using list-based input styles*/
data Final.EnergyNorth;
  infile rawdata('Energy--DC-MD-VA.txt') dlm = "09"x firstobs = 2;
  input StateFIPS CountyFIPS Code : $200. Date : anydtdte20. Unitssold;
run;

/*read in other-dc-md-va.csv using listed-based input style*/
data Final.OtherNorth;
  infile rawdata("Other--DC-MD-VA.csv") dsd firstobs = 2;
  input StateFIPS CountyFIPS Code : $200. Date : anydtdte20. Unitssold;
run;

/*read in Sodas.csv file*/
data Final.Sodas(drop = _Sizes i j);
  infile rawdata("Sodas.csv") firstobs = 6 dsd dlm = "2C"x;
  input Number Flavor : $50. @;
  do i = 1 to 6;
    input _Sizes : $50. @;
  if not missing(_Sizes) then do;
      if not index(_Sizes, "(") then do;
        IndiSize = catx(" ", scan(_Sizes,1," "), scan(_Sizes,2," "));
        ReunitSize = 1;
        code= catx("-", "S", Number, IndiSize, ReunitSize);
        output;
      end;
        else do;
          j = 1;
          do until(missing(scan(scan(_Sizes,2,"("),j,",")));
            IndiSize = catx(" ", scan(_Sizes,1," "), scan(_Sizes,2," "));
            ReunitSize = input(compress(scan(scan(_Sizes,2,"("),j,",)")), 8.);
            code= catx("-", "S", Number, IndiSize, ReunitSize);
            j+1;
            output;
          end;
        end;
    end;
  end;
run;

/*produce the Alldrinks dataset using concatenation*/
data Final.Alldrinks(drop = code);
  attrib StateFIPS  format = BEST12. informat = BEST32. 
         CountyFIPS format = BEST12. informat = BEST32.  
         Region length = $8. format = $8. informat = $8.  label = "Region"
         productName length = $50. 
         Type length = $8. label = "Beverage Type"
         Flavor length = $30. label = "Beverage Flavor"
         productCategory length = $30. label = "Beverage Category"
         ProductSubCategory length = $30. label = "Beverage Sub-Category"
         size length = $200. label = "Container Size"
         UnitSize format = BEST12.   label = "Containers per Unit"
         Container length = $6. label = "Beverage Container"
         Date format = date9.  
         UnitsSold length = 8.
  ;
  set Final.Energynorth(in = inEN ) Final.Energysouth(in = inES) Final.Noncolanorth(in = inNN)
      Final.Noncolasouth(in = inNS) Final.Othernorth(in = inON) Final.Othersouth(in = inOS)
      InputDS.Coladcmdva(in = inCN) InputDS.Colancscga(in = inCS);
  if inES = 1 OR inNS =1 OR inOS =1 OR inCS = 1 THEN Region = "South";
    else Region = "North";
  if not missing(code) then do;
    if (scan(code,1,"-") = "S") then productname = put(scan(code,2,"-"), PRODNAMES.);
      else if (scan(code,1,"-") = "E") then productname = put(scan(code,2,"-"), PronameEnergy.);
        else if (scan(code,1,"-") = "O") then productname = put(scan(code,2,"-"), PronameOther.);
  end;
  productname = propcase(productname, " -");
  if not missing(code) then size = scan(code,3,"-");
  size = lowcase(size);
  if not missing(code) then UnitSize = input(scan(code,4,"-"), 8.);
  if index(productname,"Diet") then Type = "Diet";
    else Type = "Non-Diet";
  if inES = 1 or inEN = 1 then do;
    ProductCategory = "Energy";
    if index(productname,"Big Zip") then ProductSubCategory = "Big Zip";
      else if index(productname,"Mega Zip") then ProductSubCategory = "Mega Zip";
        else ProductSubCategory = "Zip";
  end;
    else if index(productname, "Non-Soda Ades") then ProductCategory = "Non-Soda Ades";
      else if index(productname, "Nutritional Water") then ProductCategory = "Nutritional Water";
        else if index(productname, "Cola") then ProductCategory = "Soda: Cola";
          else ProductCategory = "Soda: Non-Cola";
  select;
    when(index(productname, "Berry")) Flavor = "Berry";
    when(index(productname, "Grape")) Flavor = "Grape";
    when(index(productname, "Orange")) Flavor = "Orange";
    when(index(productname, "Lemonade")) Flavor = "Lemonade";
    when(index(productname, "Orangeade")) Flavor = "Orangeade";
    when(index(productname, "Cherry Cola")) Flavor = "Cherry Cola";
    when(index(productname, "Vanilla Cola")) Flavor = "Vanilla Cola";
    when(index(productname, "Citrus Splash")) Flavor = "Citrus Splash";
    when(index(productname, "Grape Fizzy")) Flavor = "Grape Fizzy";
    when(index(productname, "Lemon-Lime")) Flavor = "Lemon-Lime";
    when(index(productname, "Orange Fizzy")) Flavor = "Orange Fizzy";
    when(index(productname, "Professor Zesty")) Flavor = "Professor Zesty";
    otherwise Flavor = "Cola";
  end;
  select(scan(size,2," "));
    when("ounce", "ounces") do;
      size = catx(" ", scan(size,1," "), "oz");
      Container = "Can";
    end;
    when("l", "liters") do;
      size = catx(" ", scan(size,1," "), "liter");
      Container = "Bottle";
    end;
    when("oz") Container = "Can";
    when("liter") Container = "Bottle";
    otherwise putlog 'QCNOTE: Unknown value for Size' Size=;
  end;
run;

/*sort alldrinks for merging later*/
proc sort data = final.Alldrinks out = final.sortedAlldrinks;
  by stateFIPS countyFIPS;
run;

/*merge one-to-many*/
data final.Alldata;
  attrib StateName length = $50. format = $50. informat = $50. label = "State Name"
         StateFips  format = BEST12. informat = BEST32. label = "State FIPS"
         countyName length = $50. format = $50. informat = $50. label = "County Name"
         CountyFips format = BEST12. informat = BEST32.  label = "County FIPS"
         Region length = $8. format = $8. informat = $8.  label = "Region"
         popestimate2016 format = comma10. label = "Estimated Population in 2016"
         popestimate2017 format = comma10. label = "Estimated Population in 2017"
         productName length = $50. label = "Beverage Name"
         Type length = $8. label = "Beverage Type"
         Flavor length = $30. label = "Beverage Flavor"
         productCategory length = $30. label = "Beverage Category"
         ProductSubCategory length = $30. label = "Beverage Sub-Category"
         size length = $200. label = "Beverage Volume"
         UnitSize format = BEST12.   label = "Beverage Quantity"
         Container length = $6. label = "Beverage Container"
         Date format = date9. label = "Sale Date"  
         UnitsSold length = 8. format = comma7. label = "Units Sold"
         salesPerThousand format = 7.4 label = "Sales per 1,000"
  ;
  merge final.counties(drop = region) final.sortedAlldrinks;
  by stateFIPS countyFIPS;
  if index(CountyName, "County") then do;
    Countyname = substr(CountyName,1,index(CountyName, "County")-2);
  end;
  if not missing(date) then do;
    SalesPerThousand = round(1000 * UnitsSold / ((popestimate2016 + popestimate2017)/2) ,.0001);
    output;
  end;
run;

/*set up pdf parameters for outputting activityies*/
ods pdf dpi = 300 file = "LouFinalReport.pdf";
ods graphics on / width = 6in; 

/*sort the alldata and output the sortdata1 for being used in the proc means procedure later*/
proc sort data = Final.Alldrinks out = Final.sortdata1;
  by statefips productname size UnitSize;
run;

/*using the proc means to output the activity 2.1*/
ods proctitle;
title1 "Activity 2.1";
title2 "Summary of Units Sold";
title3 "Single Unit Packages";
footnote justify = center "Minimum and maximum Sales are within any county for any week";
proc means data = Final.sortdata1 nonobs sum min max;
  where statefips in (13,37,45) and index(productname, "Cola") and UnitSize = 1;
  class statefips productname size UnitSize;
  var unitssold;
run;
footnote;

/*sort the alldata and output the sortdata1 for being used in the proc freq procedures*/
proc sort data = Final.Alldrinks out = Final.sortdata2;
  by productname statefips size;
run;

/*using the proc means to output the activity 2.3*/
ods pdf select Freq.Table1of1.CrossTabFreqs
           Freq.Table2of1.CrossTabFreqs;
title1 "Activity 2.3";
title2 "Cross Tabulation of Single Unit Product Sales in Various States";
proc freq data = Final.sortdata2;
  table productname*statefips*size / format = comma12.;
  where statefips in (13,37,45) and index(productname, "Cola")and UnitSize = 1;
  weight unitssold;
run;
ods noproctitle;

/*output activity 3.1.*/
title1 "Activiy 3.1";
title2 "Single-Unit 12 oz Sales";
title3 "Regular, Non-Cola Sodas";
proc sgplot data = Final.alldrinks(where= (size in ("12 oz") and UnitSize = 1 and StateFIPS in (13, 37, 45)
        and productname in ("Citrus Splash", "Grape Fizzy", "Lemon-Lime", "Orange Fizzy", "Professor Zesty")));
  hbar StateFIPS / response=Unitssold stat = sum 
                   group = ProductName groupdisplay=cluster;
  keylegend / location = inside position = bottomright down = 3;
  format StateFIPS South. Productname $Noncolasoda.;
  yaxis display = (nolabel);
  xaxis label = "Total Sold" valuesformat = comma10.;
run;

/*output activity 3.3.*/
title1 "Activiy 3.3";
title2 "Average Weekly Sales, Non-Diet Energy Drinks";
title3 "For 8 oz Cans in Georgia";
proc sgplot data = Final.alldrinks(where= (size in ("8 oz") and StateFIPS in (13)
        and productname in ("Big Zip-Berry", "Big Zip-Grape", "Zip-Berry", "Zip-Grape", "Zip-Orange")));
  vbar productname / response=Unitssold stat = mean 
                   group = UnitSize groupdisplay=cluster dataskin = sheen;
  keylegend / position = bottom title = "UnitSize";
  xaxis display = (nolabel);
  yaxis label = "Weekly Average Sales";
run;

/*output activity 3.6*/
title1 "Activiy 3.6";
title2 "Average Weekly Sales, Nutritional Water";
title3 "Single-Unit Package";
proc sgplot data = final.alldrinks(where= (UnitSize = 1 
        and productname in ("Diet Nutritional Water-Grape", "Diet Nutritional Water-Orange", "Nutritional Water-Grape", "Nutritional Water-Orange")));
  hbar productname / response=Unitssold stat = mean barwidth = .6 legendlabel='Mean';
  hbar productname / response=Unitssold stat = median fillattrs = (transparency = .4) legendlabel='Median';
  keylegend / noborder location = inside position = topright title = "Week Sales" across = 1 ;
  xaxis label = "Georiga, North Carolina, and South Carolina";
  yaxis display = (nolabel);
run;

/*produce activity 4.1*/
ods proctitle;
title1 "Activiy 4.1";
title2 "Weekly Sales Summaries";
title3 "Cola Products, 20 oz Bottles, Individual Units";
footnote justify = center "All States";
options nolabel;
proc means data = Final.alldrinks mean median q1 q3 maxdec = 0 nonobs ;
  where Flavor in ("Cherry Cola", "Vanilla Cola", "Cola") and size in ("20 oz") and unitsize = 1;
  class Region Type Flavor;
  var UnitsSold;
run;
footnote;
options label;
ods noproctitle;

/*produce activity 4.2*/;
title1 "Activiy 4.2";
title2 "Weekly Sales Distributions";
title3 "Cola Products, 12 Packs of 20 oz Bottles";
footnote justify = center "All States";
proc sgpanel data= Final.alldrinks;
  panelby region type / novarname;
  histogram UnitsSold / scale=proportion binstart=125 binwidth=250;
  colaxis label='Unit Sold';
  rowaxis display=(nolabel) valuesformat=percent7.;
  where ProductCategory in ("Soda: Cola")  and unitsize = 12 and size in ("20 oz");
run;

/*produce a dataset called Quantiles42 which is used for outputing the activity 4.4*/
ods pdf exclude summary;
ods output summary= final.Quantiles44;
proc means data = Final.alldrinks mean median q1 q3 maxdec = 0 nonobs;
  where Flavor in ("Cola") and size in ("20 oz") and unitsize = 1;
  class Region Type date;
  var UnitsSold;
run;

/*produce activity 4.4 which is a high-low plot*/
title1 "Activiy 4.4";
title2 "Sales Inter-Quartile Ranges";
title3 "Cola: 20 oz Bottles, Individual Units";
footnote justify = center "All States";
proc sgpanel data= final.Quantiles44;
  panelby region type / novarname;
  highlow x = date low = UnitsSold_Q1 high = UnitsSold_Q3;
  colaxis label = "Date"  interval = month;
  rowaxis label = "Q1-Q3" ;
  format date MONYY7.;
run;
footnote;

/*according to the instruction, sort the alldrinks data set for producing the activity #28*/
proc sort data = final.alldrinks
          out = final.sortdrinks28 nodupkey;
  by productCategory productSubcategory productName Type Container Flavor Size;
run;

/*producing the activity #28*/
title1 "Optional Activity";
title2 "Product Information and Categorization";
options nolabel;
proc report data = final.sortdrinks28 nowd;
  column productname type productCategory productsubcategory flavor size container;
  define productname /display;
  define productcategory / display;
  define type / display;
  define productsubcategory /display; 
  define flavor / display;
  define size / display;
  define container / display;
run;
options label;

/*produce the data55N dateset for outputing the activity 5.5 later*/
ods pdf exclude report;
proc report data = final.alldata out = final.data555;
  where Flavor in ("Cola") and unitsize = 1 and size in ("12 oz") 
        and StateName in ("North Carolina", "South Carolina") and date GE "01AUG2016"d and date LE "31AUG2016"d;
  column type StateName date UnitsSold=soldsum col1 col2;
  define type / group;
  define StateName / group;
  define date / group;
  define soldsum / analysis sum;
  define col1 / computed;
  define col2 / computed;
  compute col2;
    if StateName in ("South Carolina") then c = 1;
      else if StateName in ("North Carolina") then c = 2;
    if c = 1 then col1 = soldsum;
       else if c = 2 then col2 = soldsum;
  endcomp;
run;

/*produce activity 5.5*/
title1 "Activiy 5.5";
title2 "North and South Carolina Sales in August";
title3 "12 oz, Single-Unit, Cola Flavor";
proc sgpanel data = final.data555;
  panelby type / columns=1 novarname;
  hbar date / response = col2 barwidth = .6 legendlabel="South Carolina";
  hbar date / response = col1 barwidth = .85 transparency=0.5 legendlabel="North Carolina";
  colaxis label = "Sales"  TYPE = LINEAR valuesformat = comma8.;
  rowaxis display = (nolabel);  
  keylegend / title = "";
  format date mmddyy8.;
run;

/*produce activity 6.2*/
title1 "Activity 6.2";
title2 "Quarterly Sales Summaries for 12oz Single-Unit Products";
title3 "Maryland Only";
proc report data = final.alldrinks;
  where StateFIPS = 24 and Unitsize = 1 and size in ("12 oz");
  column type productname date UnitsSold,(median sum min max);
  define type / group "Product Type" order = internal;
  define productname / group "Name" order = internal;
  define date / group format = QTRR. "Quarter" order = internal;
  define UnitsSold / "";
  define median / "Median Weekly Sales";
  define sum / "Total Sales" format = comma8.;
  define min / "Lowest Weekly Sales";
  define max / "Highest Weekly Sales" format = comma8.;
  break after productname/ summarize suppress;
run;

/*output activity 7.1*/
title1 "Product Code Mapping for Sodas";
title2 "Created in Activity 7.1";
proc print data = final.sodas noobs;
run;

/*output activity 7.4*/
title1 "Activity 7.4";
title2 "Quarterly Sales Summaries for 12oz Single-Unit Products";
title3 "Maryland Only";
proc report data = final.alldrinks
            style(header)=[backgroundcolor=cx8B838C
                           color=blue];
  where StateFIPS = 24 and Unitsize = 1 and size in ("12 oz");
  column type productname date UnitsSold,(median sum min max);
  define type / group "Product Type" order = internal;
  define productname / group "Name" order = internal;
  define date / group format = QTRR. "Quarter" order = internal;
  define UnitsSold / "";
  define median / "Median Weekly Sales";
  define sum / "Total Sales";
  define min / "Lowest Weekly Sales";
  define max / "Highest Weekly Sales" format = comma8.;
  break after productname/ summarize suppress style=[backgroundcolor=black color=white];
  compute date;
    if lowcase(_break_) eq 'productname' then c = 0;
      else if _break_ eq '' then do;
        c+1;
        if mod(c,4) eq 0 then call define(_row_, 'style', 'style=[backgroundcolor=grayD7]'); 
          else if mod(c,4) eq 1 then call define(_row_, 'style', 'style=[backgroundcolor=white]');
            else if mod(c,4) eq 2 then call define(_row_, 'style', 'style=[backgroundcolor=grayF7]');
              else call define(_row_, 'style', 'style=[backgroundcolor=grayD7]');
      end;
  endcomp;
run;

/*output activity 7.5*/
title1 "Activity 7.5";
title2 "Quarterly Per-Capita Sales Summaries";
title3 "12oz Single-Unit Lemonade";
title4 "Maryland Only";
footnote justify = center "Flagged Rows: Sales Less Than 7.5 per 1000 for Diet; Less Than 30 per 1000 for Non-Diet";
proc report data = final.alldata
            style(header)=[backgroundcolor=gray88
                           color=#5A58A6];
  where StateFIPS = 24 and Unitsize = 1 and size in ("12 oz") and Flavor in ("Lemonade");
  column countyName popestimate2016 type date UnitsSold = summ salessum;
  define countyName / group "county" order = internal;
  define type / group "Product Type" order = internal;
  define date / group format = QTRR. "Quarter" order = internal;
  define summ / sum "Total Sales";
  define salessum / computed format = 7.1 "Sales per 1000";
  define popestimate2016 / group noprint;
  break after countyName/ summarize suppress style=[backgroundcolor=gray33 color=white];
  compute salessum;
    if not missing(popestimate2016) then pop = popestimate2016;
    salessum = round(1000 * summ / pop  ,.0001);
    if Type in ("Diet")then c = 0;
        else if Type in ("Non-Diet") then c = 1;
          else if lowcase(_break_) eq 'countyname' then c = 2;
    if salessum lt 7.5 and c =0 then do;
      call define(_row_, 'style', 'style=[backgroundcolor=gray99]');
      call define('_c6_', 'style', 'style=[color=red]');
    end;
    if salessum lt 30.0 and c =1 then do;
      call define(_row_, 'style', 'style=[backgroundcolor=gray99]');
      call define('_c6_', 'style', 'style=[color=red]');
    end;
  endcomp;
  compute after countyName/ style=[color=white backgroundcolor=black just=right];
    line '2016 Population:   ' pop comma.;
  endcomp;
run;

title;
footnote;
ods graphics off; 
ods pdf close;
options date;
ods listing;
quit;

