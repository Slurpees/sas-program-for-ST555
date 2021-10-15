/******** Readme*********

Programmed by: Kaida Lou
Programmed on: 2021-10-05
Programmed to: Create solution to ST555-Homework04

Modified by: N/A
Modified on: N/A
Modified to: N/A

*/

/* using reative path to refer some libraries and filepaths*/
x "cd L:\st555\Data";
libname InputDS ".";
filename rawdata ".";
x "cd L:\st555\Results";
libname Results ".";
x "cd S:\SAS Working Directory";
libname HW4 ".";
filename HW4 ".";
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

/* set the year in which the data was collected. */
%let YEAR = 1998;

/* read in Leadproject.txt file */
data HW4.loulead(drop = _:);
  attrib StName  label  = "State Name" length = $2.
         Region  length = $9. 
         JobID   length = 8.
         Date    format = date9. 
         PolType length = $4. label = "Pollutant Name" 
         PolCode length = $8. label = "Pollutant Code"
         Equipment format = dollar11.
         Personnel  format = dollar11.
         JobTotal format = dollar11.
  ;
  infile rawdata("LeadProjects.txt") firstobs = 2 dsd truncover;
  input _StName$ _JobID$  _DateRegion : $30. _PolCodePolType$ _Equipment$ _Personnel$;
  StName = upcase(_Stname);
  JobID  = input((TRANWRD(TRANWRD(_JobID,'l','1'), 'O', '0')), 8.);
  Date   = input(scan(_DateRegion,1,,'a'),8.);
  PolType = scan(_PolCodePolType,1,,'d');
  PolCode = scan(_PolCodePolType,1,,'a');
  Region = propcase(scan(_DateRegion,1,,'d'));
  Equipment = input(_Equipment, dollar11.);
  Personnel = input(_Personnel, dollar11.);
  JobTotal = Equipment + Personnel;
run;

/* sort the some variables according by Duggins' one*/
proc sort data = hw4.loulead;
  by Region StName DESCENDING JobTotal;
run;

/* output loulead's descriptor portion */
ods output position = HW4.louleaddesc(drop = member);
proc contents data = HW4.loulead varnum;
run;

/*electronically validate the descriptor portion of my data set*/
proc compare base = Results.Hw4dugginsdesc compare = HW4.louleaddesc 
             out = HW4.diffA
             &CompOpts
;
run;

/* electronically validate the content portion of my data set*/
proc compare base = results.Hw4dugginslead compare = HW4.loulead
             out = HW4.diffB
             &CompOpts
;
run;
/* create a format in oder to bin date into 4 quaters, and save it as permanent*/
proc format library = HW4;
  value calendaryear(fuzz = 0)
    "01JAN&YEAR"d - "31Mar&YEAR"d = "Jan/Feb/Mar"
    "01APR&YEAR"d - "30JUN&YEAR"d = "Apr/May/Jun"
    "01Jul&YEAR"d - "30SEP&YEAR"d = "Jul/Aug/Sep"
    "01OCT&YEAR"d - "31DEC&YEAR"d = "Oct/Nov/Dec"
  ;
run;

/* use the permanent format */
option FMTSEARCH=(HW4);
ods pdf file = "HW4 Lou Lead Report.pdf";
/* print the90th percentile plot according by region and date*/
title1 "90th Percentile of Total Job Cost By Region and Quarter";
title2 "Data for 1998";
ods output summary = HW4.louleadp90;
proc means data = HW4.loulead p90;
  class region date;
  var JObTotal;
  format date calendaryear.;
run;

/*plot the bar plot according by region and jobtotal 90th percentile*/
title;
ods listing image_dpi=300;
ods graphics on / reset width=6in;
proc sgplot data = HW4.louleadp90;
  hbar region / response = JobTotal_P90
                group = Date
                groupdisplay = cluster
                DATALABEL= NObs
                DATALABELATTRS=(Size=6pt)
  ;
  keylegend / location = outside 
              position = top
  ;
  xaxis label = "90th Percentile of Total Job Cost"
        values = (0 to 100000 by 20000) 
        valuesformat = dollar8. 
        grid
        offsetmax = .05
  ;
  format date calendaryear.;
run;
ods listing close;

/* outputing the freq table of region by date */
title1 "Frequency of Cleanup by Region and Date";
title2 "Data for 1998";

ods output CrossTabFreqs = HW4.louleadpfreq(keep = region date Frequency rowpercent  where = (rowpercent ne .));
proc freq data = HW4.loulead;
  tables region * date / nocol nopercent;
  format date calendaryear.;
run;

/* plot the bar graph of frequence region by date*/
ods listing image_dpi=300;
ods graphics on / reset width=6in imagename = "HW4LouGraph2";
title;
proc sgplot data = HW4.louleadpfreq;
  styleattrs datacolors = (red blue green orange);
  vbar region / response = RowPercent
                group = Date
                groupdisplay = cluster;
  keylegend / location = inside
              position = topright
              down = 2
              opaque
  ;
  xaxis label = "Region"
        labelattrs = (size = 16pt)
        valueattrs = (size = 14pt)
  ;
  yaxis label = "Region Percentage within 
                 Pollutant"
        values = (0 to 45 by 5) 
        valuesformat = f4.1 
        offsetmax = 0.05
        labelattrs = (size = 16pt)
        valueattrs = (size = 12pt)
        grid
        gridattrs = (color = grayCC thickness = 3)
  ;
  
  format date calendaryear.;	
run;
ods listing close;

/*electronically validate the descriptor portion of my graph2 data set with duggins' */
proc compare base = Results.Hw4dugginsgraph2 compare = HW4.louleadpfreq 
             out = HW4.diffC
             &CompOpts
;
run;
ods pdf close;
ods proctitle;
options date;
ods listing;




