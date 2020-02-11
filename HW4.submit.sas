/*
Name: Jungwon Woo
Assignment: HW4
*/

* Part I *;

	*The dataset for the final project that I found is IMDB movie dataset on Kaggle website
	 (https://www.kaggle.com/nielspace/imdb-data). The dataset consists
	 of 12 variables and 1,000 observations. There are rank (observation number column), movie title, genre, 
	 Description (plot), Director, Actors (three main actors), Year Released, Runtime, Rating, Votes (rating votes), 
	 Revenue (in Millions), Metascore (Metacritic Movie rating). 1,000 observations were drawn from the movies 
	 released between 2006 to 2016 (the data is not uniformly distributed by year. Majority of them are from 2016).
	 There are some null numeric values (revenue, rating, Metascore) due to the absence of the data. They will be
	 either excluded or replaced in a proper way. ; 

*Part II*;

	*The main goal here is to figure out what factors affects the most on the movie revenue. To see that clearly,
	 first question would be whether audience's rating leads to an increased amount of the revenue or not.
	 The second question is whether or not the certain genres generate more revenue.
	 Another possible question could be movie's success depends on the appearances of certain movie stars.; 
	 
	*For the first question, I am thinking about checking the correlation between the audience rating and
	 the revenue, since both values are continuous variables. For the second question ANOVA might be appropriate
	 to analyze (Genre = Categorical variable, Revenue = Continuous variable.) Lastly, the movie stars' impact
	 can be checked by separating them into two groups(TOP 20 vs. The Rest) and conducting Two Sample T test.;
	
*Part III*;

FILENAME movie url "https://raw.githubusercontent.com/woo2201/moviedat/master/IMDB-Movie-Data.csv";
* original data = https://www.kaggle.com/nielspace/imdb-data;

PROC IMPORT 
  datafile = movie 		/* movie file is uploaded from the url above */
  dbms= csv 
  out= movie 			/* name it as movie */
  replace ; 			/* replace the data everytime the program runs */
  GETNAMES= YES ;		/* first row is variable names; So yes. */
  GUESSINGROWS= 10000 ;
  DATAROW = 2 ; 		/* so star it from the 2nd row*/
RUN;

										** basic data prep **;
DATA moviedata;
  SET   work.movie;
  WHERE votes >= 2000;					 /* for a valid result, use the data that has enough votes*/
 
  IF rating = . then rating = metascore/10; 				/* if rating is empty, substitute with metascore */
		else if metascore =. then metascore = rating*10; 	/* and vice versa. */
		else if rating AND metascore = . then delete; 	 	/* if both values are missing, delete the observation */	
	
  IF revenue = . then delete; 							/* delete the row with no revenue value */ 
     	
  Score = ((rating*10)+metascore)/2; 	 /* take average of the ratings and metascore to see */
  Genre1 = scan(Genre,1); 				 /* Main genre of the movie : Well, three genres are hard to analyze */
  Main_actor1 = scan(actors,1,',');		 /* We will see there's any difference that actors make on the revenue */
  Main_actor2 = scan(actors,2,',');
  	  
  FORMAT revenue DOLLAR12.2	 		 	 /* dollar sign for revenue */
  		 votes COMMA10.0;				 /* for the visibility of the vote # */	  
  DROP   rank description; 				 /* KEEP statement is not necessary since DROP statement is used */	
  LABEL  revenue = "Revenue (Millions)"
  		 score = "Audience Rating"
  		 main_actor1 = "Actor / Actress 1"
  		 main_actor2 = "Actor / Actress 2"
  		 genre1 = "Main Genre"
  		 runtime = "Runtime (Minutes)"
  		 Year = "Year Released";
RUN;

PROC PRINT data = moviedata;
RUN;