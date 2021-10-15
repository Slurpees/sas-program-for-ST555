/******** Readme*********

Programmed by: Kaida Lou
Programmed on: 2021-09-22
Programmed to: Create solution to ST555-Homework03

Modified by: N/A
Modified on: N/A
Modified to: N/A

*/

x "cd L:\st555\Data\BookData\ClinicalTrialCaseStudy";
filename rawdata ".";
x "cd L:\st555\Results";
libname Results ".";
x "cd S:\SAS Working Directory";
libname HW3 ".";
ods _all_ close;
ods noproctitle;
options nodate;
*create macro variables to cut down on repetitions code;
/*store attributes*/ 
%let VarAttrs = 
  Subj label = 'Subject Number'
  sfReas   length = $50 label = 'Screen Failure Reason'
  sfStatus length = $1  label = 'Screen Failure Status (0 = Failed)'
  BioSex   length = $1  label = 'Biological Sex'
  VisitDate length= $10 label = 'Visit Date'
  failDate length = $10  label = 'Failure Notification Date'
  sbp                   label = 'Systolic Blood Pressure'
  dbp                   label = 'Diastolic Blood Pressure'
  bpUnits  length = $5  label = 'Units (BP)'
  pulse                 label = 'Pulse'
  pulseUnits length = $9 label = 'Units (Pulse)'
  position length = $9  label = 'Position'
  temp     format = 5.1 label = 'Temperature'
  tempUnits length = $1 label = 'Units (Temp)'
  weight                label = 'Weight'
  weightUnits length = $2. label = 'Units (Weight)'
  pain                  label = 'Pain Score'
;

  /*store hierarchy and order */
%let Valsort =  DESCENDING sfStatus 
                sfReas 
                DESCENDING VisitDate 
                DESCENDING failDate 
                Subj
;
/*store proc compare settings which are common*/
%let CompOpt = outbase 
               outcompare
               outdiff
               outnoequal
               noprint
               method = ABSOLUTE
               CRITERION = 1E-10
;
/*creating the Visit Macro Variable to insert the correct 
 visit name into headers and footers.*/
%let Visit = 3 Month Visit;

* read in the first file;
data HW3.HW3LouSite1;
  infile rawdata("Site 1, &Visit..txt") dlm = "09"x dsd;
  attrib &VarAttrs;
  input  Subj sfReas$ sfStatus$ BioSex$ VisitDate$ failDate$ sbp dbp bpUnits$ 
         pulse pulseUnits$ position$ temp tempUnits$ weight weightUnits$ pain;
run;

*read in the second file;
data HW3.HW3LouSite2;
  infile rawdata("Site 2, &Visit..csv") dsd; 
  /*According ot the log, I should use sequential periods here. But I do not know why? 
  Maybe it is about the marco varibales laws in the double quotes*/
  attrib &VarAttrs;
  input Subj sfReas$  sfStatus$  BioSex$  VisitDate$ failDate$ sbp dbp bpUnits$ 
         pulse pulseUnits$ position$ temp tempUnits$ weight weightUnits$ pain;
  list; /*write each iteration IB to log*/
run;

*read in the second file;
data HW3.HW3LouSite3;
  infile rawdata("Site 3, &Visit..dat") dlm = "20"x;
  attrib &VarAttrs;
  input Subj 1-7 sfReas$ 8-58 sfStatus$ 59-61 BioSex$ 62 VisitDate$ 63-72 
        failDate$ 73-82 sbp 83-85 dbp 86-88 bpUnits$ 89-94 pulse 95-97
        pulseUnits$ 98-107 position$ 108-120 temp 121-123 tempUnits$ 124 
        weight 125-127 weightUnits$ 128-131 pain 132;
  putlog Pulse=;*Write the values of Pulse from the PDV to the log for every record. ;
run;

/* VALIDATE */
/* SORTING the first data sets by given order */
proc sort data = HW3.HW3LouSite1;
  by &Valsort;
run;

/* SORTING the second data sets by given order */
proc sort data = HW3.HW3LouSite2;
  by &Valsort;
run;

/* SORTING the third data sets by given order */
proc sort data = HW3.HW3LouSite3;
  by &Valsort;
run;
/*  setting up to print following results to a pdf, powerpoint, rtf file.
Setting headers and footnotes */
ods pdf file = "HW3 Lou 3 Month Clinical Report.pdf" style = PRINTER;
ods powerpoint file = "HW3 Lou 3 Month Clinical Report.pptx" style = POWERPOINTDARK;
ods rtf file = "HW3 Lou 3 Month Clinical Report.rtf" style = SAPPHIRE;
title "Variable-level Attributes and Sort Information: Site 1 at &Visit";
footnote j = l h = 10pt "Prepared by &SysUserID on &SYSDATE";
ods powerpoint exclude all;
/* manually comparing my descriptor portions with Duggins'*/
/*data sets are sorted, so confirm variables names with position
  and sorted order with sortedby*/
ods select position Sortedby;
proc contents data = HW3.HW3LouSite1 varnum;
run;
/*proc contents data = Results.Hw3dugginssite1 varnum;*/
/*run;*/
title "Variable-level Attributes and Sort Information: Site 2 at &Visit";
ods select position Sortedby;
proc contents data = HW3.HW3LouSite2 varnum;
run;
/*proc contents data = Results.Hw3dugginssite2 varnum;*/
/*run;*/
title "Variable-level Attributes and Sort Information: Site 3 at &Visit";
ods select position Sortedby;
proc contents data = HW3.HW3LouSite3 varnum;
run;
/* compare data electronically */
/* compare my site1 data set with duggins' one*/
proc compare base = Results.HW3dugginssite1
             compare = HW3.HW3LouSite1
             out = HW3.diff1
             &CompOpt
;
run;
/* compare my site2 data set with duggins' one*/
proc compare base = Results.HW3dugginssite2
             compare = HW3.HW3LouSite2
             out = HW3.diff2
             &CompOpt
;
run;
/* compare my site3 data set with duggins' one*/
proc compare base = Results.HW3dugginssite3
             compare = HW3.HW3LouSite3
             out = HW3.diff3
             &CompOpt
;
run;
/* set up the page headers and footnotes */
ods powerpoint exclude none;
title "Selected Summary Statistics on Measurements"; 
title2 "for Patients from Site 1 at &Visit";
footnote1 j = l h = 10pt "Statistic and SAS keyword: Sample size (n), Mean (mean), Standard Deviation (stddev), Median (median), IQR (qrange)";
footnote2 j = l h = 10pt "Prepared by &SysUserID on &SYSDATE";
/* print the statistics of the first data set*/
proc means data = HW3.HW3LouSite1 n mean stddev median qrange maxdec = 1 nonobs;
  label;
  class Pain;
  Var weight temp pulse dbp sbp;
run;
/* custom dbo/sbp formats and save it as permanent into HW3 library */
proc format library = HW3;
  value sbpfmt
  low -< 130 = "Acceptable"
  130 - high = "High"
  ;
  value dbpfmt
  low -< 80 = "Acceptable"
  80 - high = "High"
  ;
run;
/* use the permanent format */
option FMTSEARCH=(HW3);
/* set up the page headers and footnotes */
title1 "Frequency Analysis of Positions and Pain Measurements by Blood Pressure Status";
title2 "for Patients from Site 2 at &Visit";
footnote1 j = l h = 10pt "Hypertension (high blood pressure) begins when systolic reaches 130 or diastolic reaches 80";
footnote2 j = l h = 10pt "Prepared by &SysUserID on &SYSDATE";
ods pdf COLUMNS = 2; /*set pdf page columns*/ 
/* print frequency analysis of Positions and Pain Measurements by Blood Pressure Status*/
proc freq data = HW3.Hw3LouSite2;
  table position
        pain * dbp * sbp / nocol norow;
  format sbp sbpfmt. dbp dbpfmt.;
run;
/* set up the page headers and footnotes */
title1 "Selected Listing of Patients with a Screen Failure and Hypertension";
title2 "for patients from Site 3 at &Visit";
footnote1 j = l h = 10pt "Hypertension (high blood pressure) begins when systolic reaches 130 or diastolic reaches 80";
footnote2 j = l h = 10pt "Only patients with a screen failure are included.";
footnote3 j = l h = 10pt "Prepared by &SysUserID on &SYSDATE";
ods pdf COLUMNS = 1;
ods powerpoint exclude all;
/* print third data set Listing of Patients with a Screen Failure and Hypertension*/
proc print data = HW3.HW3LouSite3 label noobs;
  where sfstatus = "0";
  id subj pain;
  var VisitDate sfStatus sfReas failDate BioSex sbp dbp bpUnits weight weightUnits;
run;
/*finish my project*/
title;
footnote;
ods pdf close;
ods powerpoint close;
ods rtf close;
ods listing;
quit;
