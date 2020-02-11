******************** HW4 07/16/2019 Jungwon Woo **********************;

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
	
*Part III*;

FILENAME movie url "https://raw.githubusercontent.com/woo2201/moviedat/master/IMDB-Movie-Data.csv";
* original data = https://www.kaggle.com/nielspace/imdb-data;

PROC IMPORT 
  datafile = movie 		/* movie file is uploaded from the url above */
  dbms= csv 
  out= moviedata 		/* name it as movie data */
  replace ; 			/* replace the data everytime the program runs */
  GETNAMES= YES ;		/* first row is variable names; So yes. */
  GUESSINGROWS= 10000 ;
  DATAROW = 2 ; 		/* so star it from the 2nd row*/
RUN;

										** basic data prep **;
DATA moviedata;
  SET work.moviedata;
  WHERE votes >= 2000;					     /* for a valid result, use the data that has enough votes*/
  FORMAT revenue DOLLAR12.2	 		 	 /* dollar sign for revenue */
  		 votes COMMA10.0;				 /* Add more formats? */
 
	if rating = . then rating = metascore/10; 			/* if rating is empty, substitute with metascore */
		else if metascore =. then metascore = rating*10; 	/* and vice versa*/
		else if rating AND metascore = . then delete; 	 	/* if both values are missing, delete the observation */	
	if revenue = . then delete; 						/* delete the row with no revenue value */ 
  
  Score = ((rating*10)+metascore)/2; 	 /* average the ratings and metascore. Reasoning attached below */
  Genre1 = scan(Genre,1); 				 /* Main genre of the movie : Well, three genres are hard to analyze */
  Main_actor1 = scan(actors,1,',');		 /* We will see there's any difference that actors make on the revenue */
  Main_actor2 = scan(actors,2,',');
  
  if score >= 75 then face = "GREEN";		/* metacritic divides the score into three sections; GREEN, YELLOW, RED */
	else if score >= 49 then face = "YELLOW"; /* depends on the rating. The dividing points are 75 and 49. */
	else face = "RED";   					/* I decided to use the same classification here */
  
  DROP rank description; 						 				/* rank is useless here */
  KEEP title genre actors Director
  	   Year Runtime revenue metascore
  	   votes score genre1 rating
  	   Main_actor1 Main_actor2 face;
  
  label revenue = "Revenue in Millions"
  		score = "Audience Rating"
  		main_actor1 = "Actor / Actress 1"
  		main_actor2 = "Actor / Actress 2"
  		face = "Review Color"
  		genre1 = "Main Genre";
RUN;