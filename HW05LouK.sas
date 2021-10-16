/******** Readme*********

Programmed by: Kaida Lou
Programmed on: 2021-10-16
Programmed to: Create solution to ST555-Homework05

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
x "cd S:\SAS Working Directory";
libname HW5 ".";
filename HW5 ".";
/* set up some global statements(no other destination except listig and pdf,
no proc title, no system date)*/ 
ods _all_ close;
ods noproctitle;
options nodate nobyline;

/*this macro variable is used to set options for proc compare*/
%let CompOpts = outbase 
                outcompare
                outdiff
                outnoequal
                noprint
                method = absolute
                criterion = 1E-9;

/*read in O3project dataset*/
data HW5.louO3;
  infile RawData("O3Projects.txt") dsd firstobs = 2 truncover;
  input _StName$ _JobID$  _DateRegion : $30. _PolCodePolType$ _Equipment$ _Personnel$;
run;

/*read in COproject dataset*/
data HW5.louCO;
  infile RawData("COProjects.txt") dsd firstobs = 2 truncover;
  input _StName$ _JobID$  _DateRegion : $30.  _Equipment$ _Personnel$;
run;

/*read in SO2project dataset*/
data HW5.louSO2;
  infile RawData("SO2Projects.txt") dsd firstobs = 2 truncover;
  input _StName$ _JobID$  _DateRegion : $30. _Equipment$ _Personnel$;
run;

/*read in TSPproject dataset*/
data HW5.louTSP;
  infile RawData("TSPProjects.txt") dsd firstobs = 2 truncover;
  input _StName$ _JobID$  _DateRegion : $30. _Equipment$ _Personnel$;
run;

/* clean and combine 5 datasets in to one dateset called HW5louprojects*/ 
data HW5.Hw5louprojects(label = "Cleaned and Combined EPA Projects Data" drop = _:);
  set hw5.loulead(in = inlead)
      hw5.louso2(in = inso2)
      hw5.loutsp(in = intsp)
      hw5.louco(in = inco)
      hw5.louo3(in = ino3)
  ;
  if intsp eq 1 then do;
  PolCode = "1";
  PolType = "TSP";
  end;
  if inso2 eq 1 then do;
  PolCode = "4";
  PolType = "SO2";
  end;
  if inco eq 1 then do;
  PolCode = "3";
  PolType = "CO";
  end;
  if ino3 eq 1 then do;
  PolType = compress(_PolCodePolType,"5");
  PolCode = compress(_PolCodePolType,"O3");
  end;
  if inlead ne 1 then do;
  StName = upcase(_Stname);
  JobID  = input((TRANWRD(TRANWRD(_JobID,'l','1'), 'O', '0')), 8.);
  Date   = input(scan(_DateRegion,1,,'a'),8.);
  Region = propcase(scan(_DateRegion,1,,'d'));
  Equipment = input(_Equipment, dollar11.);
  Personnel = input(_Personnel, dollar11.);
  JobTotal = Equipment + Personnel;
  end;
run;

/*sort my dateset as the same as the Duggins' one does*/;
proc sort data = HW5.Hw5Louprojects;
 by PolCode Region DESCENDING JobTotal DESCENDING Date JobID;
run;

/* output variebles attributes of my data set*/
ods output position = HW5.Hw5louprojectsdesc(drop = member);
proc contents data = Hw5.Hw5louprojects varnum; 
run;

/*compare my dataset variables attributes with Duggin's one*/
proc compare base = results.Hw5dugginsprojectsdesc 
             compare = HW5.Hw5louprojectsdesc
             out = HW5.diffd
             &CompOpts
;
run;

/*compare my dataset with Duggin's one*/
proc compare base = results.Hw5dugginsprojects 
             compare = HW5.Hw5Louprojects
             out = HW5.diffe
             &CompOpts
;
run;

/* use the permanent format in HW5 AND inPUTDS*/
option FMTSEARCH=(HW5, InputDS);

/* output the dataset which is used to plot, using the Polmap format 
is to map polcode to pollutant type*/
ods output summary = HW5.loumeans (drop = PolType rename = (polcode = poltype));
proc means data = HW5.Hw5louprojects p25 p75;
  class PolType region date;
  by polcode;
  var JobTotal;
  format date calendaryear. Polcode $polmap.;
  label polcode = "Pollutant Name";
  where not missing(region) and not missing(PolCode); 
run;

/* set up the pdf file output and attributes of graphs*/
ods pdf file = "HW5 Lou Projects Graphs.pdf";
ods pdf startpage = NEVER;
ods listing image_dpi=300;
/*save all graphs in my hw5 directory*/
ods graphics on / reset width=6in imagename = "HW5LouPctPlot";
title1 "25th and 75th Percentiles of Total Job Cost";
title2 "By Region and Controlling for Pollutant = #byval1";
title3 height = 8pt "Excluding Records where Region or Pollutant Code were Unknown (Missing)";
footnote justify = left "Bars are labeled with the number of jobs contributing to each bar";

/*plot graphs*/
proc sgplot data = HW5.loumeans;
  by poltype;
  styleattrs datacolors = (red blue green orange);
  vbar region / group = date 
                groupdisplay=cluster 
                response = JobTotal_P75
                name = "TheFirstPlot"
                OUTLINEATTRS = (color=black)	
                DATALABEL = NObs
                DATALABELATTRS = (Size = 7pt)
                GROUPORDER = ASCENDING
  ;
  vbar region / group = date 
                groupdisplay = cluster 
                response = JobTotal_P25
                fillattrs = (color = gray)
                OUTLINEATTRS = (color=black)
                name = "TheSecondPlot"
  ;
  
  yaxis grid 
        gridattrs=(color=gray thickness = 2 ) 
        valuesformat = dollar11.
        display=(nolabel)
       ;
  xaxis display=(nolabel)
  ;
  keylegend "TheFirstPlot" / position = top;
run;

ods pdf close;
ods proctitle;
options date;
ods listing;
quit;



