/*------------------------------------------------------------------------------------------------------*/
/*--------------------------------------MACRO  VARIABLES------------------------------------------------*/
/*------------------------------------------------------------------------------------------------------*/

%LET movstars "Christian Bale","Brad Pitt","Leonardo DiCaprio","Robert Downey Jr.";
%LET titleops h=14pt f = 'Times New Roman';
%LET meanrev = 84.3;
%LET datlab_att datalabelattrs=(size = 11pt family = arial style = italic);
%LET seglab_att seglabelattrs=(size = 11pt family = arial style = italic);	  /*ordinary font size*/
%LET small_datatt datalabelattrs=(size = 10pt family = arial style = italic); /*for small sized font*/
%LET label_12pt  labelattrs=(size = 12pt);
%LET ftnoteatt j=right italic h=11pt;
/*------------------------------------------------------------------------------------------------------*/
/*--------------------------------------DATA IMPORT STEP------------------------------------------------*/
/*------------------------------------------------------------------------------------------------------*/

FILENAME movie url "https://raw.githubusercontent.com/woo2201/moviedat/master/IMDB-Movie-Data.csv";
* original data = https://www.kaggle.com/nielspace/imdb-data;


PROC IMPORT 
  DATAFILE = movie 		/* movie file is uploaded from the url above */
  DBMS = csv 
  OUT  = movie 			/* name it as movie */
  REPLACE ; 			/* replace the data everytime the program runs */
  GETNAMES= YES ;		/* first row is variable names; So yes. */
  GUESSINGROWS= 1000 ;
  DATAROW = 2 ; 		/* so star it from the 2nd row*/
RUN;


DATA moviedata;
  SET   work.movie; 					 
  WHERE votes >= 2000;					 /* for a valid result, use the data that has enough votes*/
 
  IF rating = . then rating = metascore/10; 				/* if rating is empty, substitute with metascore */
		else if metascore =. then metascore = rating*10; 	/* and vice versa. */
		else if rating AND metascore = . then delete; 	 	/* if both values are missing, delete the observation */	
  IF revenue = . then delete; 								/* delete the row with no revenue value */
     	
  Score = ((rating*10)+metascore)/2; 	 /* take average of the ratings and metascore to see */
										 /* Metacritic's score is also presented in IMDb webpage, mostly rated by experts */
  Genre1 = scan(Genre,1); 				 /* Main genre of the movie : Well, three genres are hard to analyze */
  Main_actor1 = scan(actors,1,',');		 /* We will see there's any difference that main actors make on the revenue */
  	  
  FORMAT revenue DOLLAR12.2	 		 	 /* Dollar Sign for revenue value */
  		 votes COMMA10.0				 /* for the visibility of the vote # */
  		 rating COMMA3.2;  
  		 
  DROP   rank description director; 	 /* KEEP statement is not necessary since DROP statement is used */	
  LABEL  revenue = "Revenue (in Millions)"  /* Gross Revenue in US Box Office only */
  		 score = "Audience Rating"
  		 main_actor1 = "Actor / Actress"
  		 genre1 = "Main Genre"
  		 runtime = "Runtime (in Minutes)";
run;

/*------------------------------------------------------------------------------------------------------*/
proc corr data= moviedata pearson nosimple plots=none;
	var Metascore;
	with Rating;
run; 										/* Reason behind the score merging */
/*------------------------------------------------------------------------------------------------------*/
PROC SORT DATA = work.moviedata;
	 BY descending revenue;      /* Since the revenue amount is our main interest, we sort it by revenue*/
RUN;
/*------------------------------------------------------------------------------------------------------*/

	title1 " IMDb Movie dataset " ;
	footnote1 " Votes # less than 2,000 or null revenue excluded";
	footnote2 "** Audience Rating is the average of metacritic score and IMDB rating ***" ;
	footnote3 "*** (Audience Rating = ((IMDB rating*10)+(Metacritic score))/2 ***";

PROC PRINT DATA = work.moviedata (obs = 40) label; 	/* DATA OVERVIEW, only first 40 observation will be shown*/
   VAR revenue rating metascore
   	   votes score genre1 Year
   	   Runtime Main_actor1;
   ID title;								/* title as an ID variable for visibility*/			
RUN;	

	title;
	footnote;

/*------------------------------------------------------------------------------------------------------*/
/*---------------------------------dataset prep : hypothesis 1 : high-rated movie makes money?----------*/
/*---------------------------------dataset prep : hypothesis 2 : certain movie stars matter?------------*/
/*---------------------------------dataset prep : hypothesis 3 : certain genre makes difference?--------*/
/*------------------------------------------------------------------------------------------------------*/
										
				/* HYPOTHESIS 1 */
				/* First, we want to see the audience rating is correlated with the revenue*/
				/* Intuitively, we think the good movies usually make more money */

title1 &titleops "Score, Votes, Runtime Vs. Revenue";
proc corr DATA = moviedata pearson nosimple plots=matrix;
	var score votes Runtime;
	with Revenue;
run;
title;			/* Instead, Votes (the number of people who rated the movie) has a higher correlation value */
				/* than the audience score of the movie. Running time of the movie seems not to have a big  */
				/* impact on the movie revenue as well. */

title1 &titleops "Example : Revenue Vs. Score";
proc sgplot data=WORK.MOVIEDATA (where=(title contains "Transformer" or score > 88));
	bubble x = Title y = Score size = Revenue /
	datalabel=revenue datalabelpos= top &datlab_att
	fillattrs=(color = skyblue) 
	bradiusmin=8 bradiusmax=30;
	xaxis valueattrs=(size = 11pt) label = " " grid;
	yaxis grid;
run;
title;
/*------------------------------------------------------------------------------------------------------*/

				/* HYPOTHESIS 2 */
				/* Certain movie actors bring more revenue? */
				/* People love certain movie stars for sure, but does that mean their movies guarantee a success? */

PROC FREQ DATA = moviedata; 				 /* ACTOR/ACTRESS who made frequent appearances */
    table main_actor1 / noprint
    out = actor1; 							 /* already sorted by Main_actor1*/
RUN;
PROC SORT DATA = moviedata
	out = work.sorted_mv;   				 /* Average revenue of the most frequently appeared actors vs that of others! */
	by main_actor1;
RUN;

DATA actordat;
	MERGE actor1 sorted_mv;
	BY Main_actor1;
	IF COUNT >= 7 then aprnc = "TOP 14";	 /* consider 7 or more appearance as top 14 */
	ELSE aprnc = "Others";
	keep Main_actor1 COUNT Revenue aprnc year genre1;
run;	
	
	title1 &titleops "Average Revenue Comparison";
	footnote1 &ftnoteatt "TOP 14 actors are those who starred in any movies in this dataset at least 7 times" ;
proc sgplot data= actordat;
  vbar aprnc / stat = mean response = revenue
    fillattrs=(color = grey)
    barwidth= 0.5
    limits = both limitstat = clm alpha = 0.05 
    seglabel seglabelattrs=(size = 15 color = white) dataskin =matte;
    xaxis &label_12pt label= "Actor Group";
    yaxis &label_12pt;
run;						/* Movie stars with more appearances have a higher mean */
	title; 					/* revenue. Now, */
	footnote;


	title1 &titleops "Top 14 Movie Star's Average Revenue";
proc sgplot data = actordat;
	where aprnc = "TOP 14";
	hbar main_actor1 / stat = mean response= revenue
	fillattrs=(color = grey)
    barwidth= 0.7 categoryorder=respdesc 
    datalabel &datlab_att
    dataskin = matte;
    refline &meanrev / axis= x label = "Average Revenue : &meanrev"
    labelloc= inside lineattrs= (pattern = dash thickness = 1.5 color = blue);
    xaxis &label_12pt;
    yaxis &label_12pt valueattrs=(size = 11.5pt);
run;							/* the revenue plot of the each member in TOP 15 */
	title;						/* Robert Downey Jr. is the first place */


				/* Here, I picked 4 top actors out of top 14 and check whether there is any trend in revenue by year*/
				
	title1 &titleops "Revenue Timeline Trend From 4 Actors";
	footnote1  &ftnoteatt "** black dot-line stands for the dataset's mean revenue of &meanrev **";
proc sgpanel data=actordat noautolegend ;
	where main_actor1 in (&movstars);
	panelby main_actor1 / novarname	headerattrs=(size = 12pt family = "Times New Roman");
	vline Year / response=Revenue group=Main_actor1
	stat= mean markers datalabel &datlab_att;
		styleattrs
	datacontrastcolors=(green blue black red)
	datalinepatterns=(solid shortdash longdash dot);
	refline &meanrev / axis= y
	lineattrs= (pattern = dot color = black);
run;					
	title;
	footnote;
	
	/* There is no distinctive trend in year, except Leonardo DiCaprio, other three actors are not seemingly creating a good revenue recently */
				
/*------------------------------------------------------------------------------------------------------*/
	
												/* HYPOTHESIS 3 */
												/* DOES GENRE MATTERS */
						
title1 &titleops "Genre Frequency";
proc sgplot data = moviedata;
vbar genre1 / 
    stat = freq
    datalabel &datlab_att
    fillattrs=(color = grey) dataskin= matte
    transparency = 0.2;
    xaxis &label_12pt;
	yaxis &label_12pt;
run;
title;
							/*Genre Distribution : Action, Comedy, Drama take up the big three portions*/

title1 &titleops " Average Revenue by Genre";
proc sgplot data = moviedata;
hbar genre1 / 
    stat = mean response = revenue 
    datalabel &datlab_att 
    fillattrs=(color = grey) dataskin = matte
    transparency = 0.2;
run;
title;
						/* Animation, Adventure and Action makes more revenue compared to other genres. */
						/* for future filmmakers, it would be better for them to make those genres if they */
						/* are aiming at a higher revenue, regardless of the ratings. */

footnote;

title1 &titleops " Top Actors' Mean Revenue by Genre";				
footnote1 &ftnoteatt angle=30 "***Revenue is in millions";

proc sgplot data=moviedata;
	where main_actor1 in (&movstars) and genre1 not in ("Mystery"); 			/* Mystery Genre was excluded as it only contains one actor */
	hbar genre1 / response=Revenue group=Main_actor1  groupdisplay=cluster 		/* which means there is no comparison counterpart*/
		datalabel &small_datatt nooutline DATALABELFITPOLICY=NONE
		stat= mean; 
		styleattrs
	datacolors=(grey orange yellow skyblue);
	yaxis grid;
    xaxis ranges=(0 - 400) display=(noline nolabel) grid;
run;

title;
footnote;


