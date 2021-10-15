/******** Readme*********

Programmed by: Kaida Lou
Programmed on: 2021-09-10
Programmed to: Create solution to ST555-Homework02

Modified by: N/A
Modified on: N/A
Modified to: N/A

*/
x "cd L:\st555\Data";
libname InputDS "."; /* use relatives paths to associate InputDS
                        with the data folder on the shared drive*/
x "cd S:\";
libname HW2 "."; /* use relative path associate HW2 with 
                       the folder where I want to save my results*/
filename rawdata "L:\st555\Data";
options nodate;
ods noproctitle; 
title "Variable-Level Metadata (Descriptor) Information"; 
data work.Baseball;
  infile rawdata("Baseball.dat") dlm = "092C"x firstobs = 14;/*delimiters are tab and comma
  and read data using fixed and list input*/
/*  length Division$ 4 Position$ 2;*/
  length FName$ 9 LName$ 11 City$ 13;
  input  LName$ FName$ City$ nAtBat 51-54 nHits 55-58 nHome 59-62 nRuns 
         63-66 nRBI 67-70 nBB 71-74 YrMajor 75-78 CrAtBat 79-83
         CrHits 84-87 CrHome 88-91 CrRuns 92-95 CrRbi 96-99 CrBB 100-102 
         League$ Division$ 112-115 Position$117-118 nOuts 133-136 nAssts 137-140 nError 
         141-144 Salary 145-152;
/*  list;  */ 
  format Salary dollar10.3;
  label 
        LName    = 'Last Name'
		FName    = 'First Name'
        City     = 'City at the end of 1986'
        nAtBat    = '# of At Bats in 1986'
        nHits     = '# of Hits in 1986'
        nHome     = '# of Home Runs in 1986'
        nRuns     = '# of Runs in 1986'
        nRBI      = '# of RBIs in 1986'
        nBB       = '# of Walks in 1986'
        YrMajor   = '# of Years in the Major Leagues'
        CrAtBat   = '# of At Bats in Career'
        CrHits    = '# of Hits in Career'
        CrHome    = '# of Home Runs in Career'
        CrRuns    = '# of Runs in Career'
        CrRbi     = '# of RBIs in Career'
        CrBB      = '# of Walks in Career'
        League    = 'League at the end of 1986'
        Division  = 'Division at the end of 1986'
        Position  = 'Position(s) Played'
        nOuts     = '# of Put Outs in 1986' 
        nAssts    = '# of Assists in 1986'
        nError    = '# of Errors in 1986'
        Salary    = 'Salary (Thousands of Dollars)'
  ; 
run;

ods rtf file = "HW2 Lou Baseball Reprot.rtf" style = Sapphire;
ods pdf file = "HW2 Lou Baseball Reprot.pdf" style = Journal;
/*ods trace on;*/
ods pdf exclude all;
ods select Position; *only the table called Position will print;
proc contents data = work.Baseball varnum ;
run;
/*ods trace off;*/
options FMTSEARCH = (InputDS);*This gives me access to all formats in this library;
proc format fmtlib library = InputDS;
  select Salary;/* print Salary which is suitable*/
run;
ods pdf exclude none;

/*proc format;*/
/*  value SalaryF*/
/*    .           = "Missing"*/
/*    low -  190  = "First Quartile"*/
/*	190 <- 425  = "Second Quartile"*/
/*    425 <- 750  = "Third Quartile"*/
/*	750 <- high = "Fourth Quartile"*/
/*  ; */
/*run;*/


title "Five Number Summaries of Selected Batting Statistics";
title2 h=10pt "Grouped by League (1986), Division (1986), and Salary Category (1987)"; 
options label;

proc means data = work.Baseball min p25 p50 p75 max missing nolabels maxdec = 2;
  class League Division Salary;
  var nHits nHome nRuns nRBI nBB ;
  format Salary Salary.; /* in the fmtlib, the format Salary is the same as what I have created*/
run;
title;

title "Breakdown of Players by Position and Position by Salary";
proc freq data = work.baseball;
  table position;/* one-way table*/
  table position * salary / missing;* two-way table;
  format salary salary.;/* use the format salary in fmtlib*/
run;
title;

proc sort data =  work.baseball out = work.sortedbaseball ;*sort data for print later;
  by league division City decending Salary;
  label;
run;
title "Listing of Selected 1986 Players";
footnote j = l height = 8pt "Included: Players with Salaries of at least $1,000,000 or who played for the Chicago Cubs";
options label;
proc print data = work.sortedbaseball noobs label;
  id Lname Fname Position ;
  var league division City Salary nHits nHome nRuns nRBI nBB;
  where (salary >= 1000 or (city in ("Chicago") and league notin ("Amercia") and Division notin ("West")));
  sum Salary nHits nHome nRuns nRBI nBB;
  format Salary dollar11.3 nHits nHome nRuns nRBI nBB comma8.;
run;
title;
footnote;
ods pdf close; 
ods rtf close;
ods proctitle;
quit;
