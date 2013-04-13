
#filename
input=$1
grader=$2

while read line ; do
  
  cadename=$(echo "${line}" |  cut -d "," -f 1) 
  last=$(echo "${line}" | cut -d"," -f 2)
  first=$(echo "${line}" |  cut -d "," -f 3) 
  p_last=$(echo "${line}" | cut -d"," -f 4)
  p_first=$(echo "${line}" |  cut -d "," -f 5) 
  p_ship=$(echo "${line}" |  cut -d "," -f 6)
  db_table=$(echo "${line}" |  cut -d "," -f 7)
  db_queries=$(echo "${line}" |  cut -d "," -f 8)
  p=$(echo "${line}" |  cut -d "," -f 9)
  details=$(echo "${line}" |  cut -d "," -f 10)
  g=$(echo "${line}" |  cut -d "," -f 11)
  err=$(echo "${line}" |  cut -d "," -f 12)
  subtotal=$(echo "${line}" |  cut -d "," -f 13)
  eff=$(echo "${line}" |  cut -d "," -f 14)
  total=$(echo "${line}" |  cut -d "," -f  15)
  comments=$(echo "${line}" |  cut -d "," -f 16)
  
  echo  "CS 3500, PS 10 Grade, Fall 2012

Student: ${last}, ${first} & ${p_last}, ${p_first}

Graded by: ${grader}

Score: ${total}/100

Note to graders.  Check partnership.pdf before grading. Grade only the submitting partner's solution and record it for both partners.  If parternship.txt reports a partnership problem, let me know about it.

1) ${p_ship}/10

Each member of the partnership submitted his or her own partnership.pdf, which contains a reasonable description of the experience of doing pair programming.  If the student worked alone, no credit for this part.

2) ${db_table}/20

The parternship created and described (in database.pdf) a properly-organized database that avoids duplication and nulls by using multiple tables.

3) ${db_queries}/20

The partnership described (in database.pdf) a representative selection of queries for accessing and modifying its database.

4) ${subtotal}/35

Test the GET requests by hand, following the rubric below.  The responses should be properly-formatted HTML responses.  Play a game or two first to make sure that the DB can be updated as well a queried.

[${p}/10] GET /players HTTP/1.1

The server should send back (see below) an HTML page containing a table of information.  There should be one row for each player in the database and four columns.  Each row should consist of the player's name, the number of games won by the player, the number of games lost by the player, and the number of games tied by the player.

[${details}/10] GET /players/games?player=Joe HTTP/1.1

The server should send back (see below) an HTML page containing a table of information.  There should be one row for each game played by the player named in the line of text (e.g., 'Joe' in the example above) and five or six columns.  Each row should consist of a number that uniquely  identifies the game (see the next paragraph for how that number will be used), the date and time when the game was played, the name of the opponent, the score for the named player, and the score for the opponent.

[${g}/10] GET /game?id=35 HTTP/1.1

The server should send back (see below) an HTML page containing information about the specified game (e.g., 35 in the example above).  The page should contain the names and scores of the two players involved, the date and time when the game was played, a 4x4 table containing the Boggle board that was used, the time limit that was used for the game, and the five-part word summary. If there the specified game does not exist, treat this as an 'anything else' case as discussed below.

[${err}/5] Anything else

If the first line of text is anything else, the server should send back an HTML page containing an error message.


5) ${eff}/15

It is evident from the code that the partnership made a good-faith effort to solve the problem, even if it doesn't work.


6) Give any additional helpful comments here:


${comments}" >"scores/${last}_${first}___${p_last}_${p_first}.txt"
  
done < $input
