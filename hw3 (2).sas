*Template;
/*
Name:
Assignment: HW3
*/
*----- Do not Modify code in this section --------;
proc datasets library=work kill noprint;run;quit;
libname course "/courses/df6689e5ba27fe300/IntroSAS/Essentials/Data";
libname mylib "~/trash";
proc datasets library=mylib kill noprint;run;quit;
*--------------------------------------------------;
data mylib.rec label;  				  /* name the data rec and store in mylib */
 format date DATE9.					  /* permanent format */
 		time TIMEAMPM.;
 set course.rec;  		  			 /* the original data came from course.rec */
 PC = (current/capacity)*100; 
 Date = datepart(updated);
 Time = timepart(updated);
 where location contains "SHELL"; 	 /* Subset the observations as they are being read */
 keep location current PC date time; /* the dataset keeps these variables*/
 label current = "Count"
	  PC = "Percent of Capacity"
	  date = "Date"
	  location = "Facility"
	  time = "Time"; 				 /*Label them as indicated*/

run;

proc sort data = mylib.rec;
by descending PC;
run;

title1 "Observations with 100% or greater Percent of Capacity";
title2 "All Shell Locations";

proc print data = mylib.rec (obs = 5) noobs label;
format PC 8.2; /* Temporary format */
var current PC date time;
ID location;
run; 

title;

*----- Do not Modify code in this section --------;
proc contents data = mylib._ALL_;
ods select Directory Members Variables Sortedby;
run;
*--------------------------------------------------;