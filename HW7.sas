proc datasets library=work kill noprint;run;quit;
options symbolgen mlogic mprint; 
/* Display the resolving macro references result for future debugging.*/
%let path = /home/u39737346/my_courses/mmccants/IntroSAS/MISC/HW7/data;
/* Easier than writing the same physical address multiple times.*/
proc format;
value $platform "Xbox 360","Xbox One" = "Xbox"
			   "PlayStation 3","PlayStation 4" = "PlayStation";
run;

/* new character format. */

*--------------------------------
Part I: Reading in the data sets.
---------------------------------;

%macro readData(fn, output);
FILENAME Bdata "&path./&fn.";	
data &output;
	infile Bdata delimiter = ',' MISSOVER DSD  firstobs=2 ;
	
	%if %scan(&fn.,1,".") = metadata %then %do;
	input id title :$145.;
%end;

/* checking if %scan(&fn.,1,".") = metadata is TRUE,
if it is true, then use ‘id title :$145.’ as an input statement
Otherwise, follow the code below */

%else %do;
	input id type :$14. platform :$13. time :$7.;		 
	hours = input(scan(time,1,"h"),8.);
	if find(time, "m") > 0 then minutes = scan(scan(time,2," "),1,"m");
	else minutes = 0;
	hours = hours + (minutes/60);
	drop minutes time;
	%end;
run;
%mend;

*Run macro you creted above to read in the 4 data sets.;
%readData(fn = metadata.csv, output = meta);
%readData(fn = Bioshock.csv, output = Bio1);
%readData(fn = BioshockII.csv, output = Bio2);
%readData(fn = BioshockIII.csv, output = Bio3);


*-------------------------
Part II: Stack and merge.
--------------------------;

DATA stacked;
	set bio1 bio2 bio3; /* bio: => every dataset that starts with bio will be merged*/
RUN;

	PROC SORT data = stacked; by id; run;
	PROC SORT data = meta; by id; run;  /* SORT before merging*/

DATA merged;
	merge meta(in = M) stacked(in = S);
	by id;
	if S = 1 and M = 1; 				/* Keep only the ids that are in dataset "stacked".*/
RUN;
	
PROC SORT data = merged out = unique nodupkey; by id; RUN;	
PROC FREQ data = stacked noprint; table id; RUN;

PROC MEANS data = merged;
class type platform;
var hours;
run;


*--------------------------
Part III: Create the plots.
--------------------------;

%macro myplot(mytype);

proc sql noprint;
	select mean(hours) format=comma12.1         /*select average hours and format it into comma12.1*/
	into :avgplay trimmed 						/*assign the average hours as avgplay*/
	from merged 								/*from dataset named merged*/
	where type = "&mytype";						/*depends on the type, the macro will run*/

	title h = 13pt "&mytype Gameplay";			/*title seems to have approximately 13pt size*/	
	title2 "Time to completion by platform type";
	footnote f = calibre h = 9pt "** Average gameplay over all platforms was &avgplay hours";

proc sgplot data = merged;
	format platform $platform.;					/*format platform so that we can reduce to 3 types*/
 	where type = "&mytype";
    refline &avgplay / axis = y label = "**"
    				   lineattrs=(thickness = 3 color = purple);
	vbox hours / category = title
	group = platform groupdisplay=cluster spread grouporder = ascending;
	
	yaxis label = "Hours Played" labelattrs=(weight = normal);
	xaxis label = "Game Title" labelattrs=(weight = normal); /*axis labels were not bold. Bring this back to normal*/
	label platform = "Platform";  							 /*Capitalize the first letter p.*/

styleattrs datacolors=(lightblue lightgrey orange) datasymbols= (circle);
/*Otherwise the datasymbols would be different from group to group.*/
run;

	title;
	footnote;
%mend;


*Run macro you creted above to create the 3 plots.;
%myplot(mytype = Main Story);
%myplot(mytype = Main + Extras);
%myplot(mytype = Completionists);
