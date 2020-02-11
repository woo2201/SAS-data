/*
Name: JUNGWON WOO
Assignment: HW5
*/

proc datasets library=work kill noprint;run;quit;
libname hwdata "/courses/df6689e5ba27fe300/IntroSAS/MISC/HW5/";

*Part I;
data shell_mod; 
	set hwdata.shell;
current = input(scan(amount,1,"/"), 2.);
capacity = input(scan(amount,2,"/"), 3.);
	drop amount;
run;

*Part II;
data stacked;
	length  location $ 21 timegrp $ 7;
	set hwdata.nat(rename= (count = current)) shell_mod hwdata.ogg;
	prop = current/capacity;
	time = timepart(pulled);
	format time timeampm.;


   	 if time >='00:00't and time <= '10:00't then timegrp = "Dawn";
else if time > '10:00't and time <= '15:00't then timegrp = "Midday";
else if time > '15:00't and time <= '24:00't then timegrp = "Evening";

	keep location time timegrp prop;
run;

*Part III;
proc means data = stacked noprint nway mean stddev n ;
 var prop;
 class location timegrp;
 output out = mymeans (rename=(_freq_ = n) drop=_type_)
 		mean = average stddev = stdev;
run;

*Part IV;
Proc sort data = stacked; by location timegrp; run;
Proc sort data = mymeans; by location timegrp; run;
data merged;
	merge stacked mymeans;
	by location timegrp; 
run;

*----- Do not Modify code in this section --------;
%include "/courses/df6689e5ba27fe300/IntroSAS/MISC/HW5/HW5Check.sas";
*--------------------------------------------------;


