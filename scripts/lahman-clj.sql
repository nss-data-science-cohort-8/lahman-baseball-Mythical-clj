/* 1. Find all players in the database who played at Vanderbilt University. 
Create a list showing each player's first and last names as well as the
total salary they earned in the major leagues. 
Sort this list in descending order by the total salary earned. 
Which Vanderbilt player earned the most money in the majors? */


-- CAVIN'S (WRONG, Need to distinct playerid)
SELECT
	namefirst ||' '||
	namelast AS name,
	CAST(SUM(salary) AS NUMERIC)::MONEY AS total_earned,
	schoolname
FROM people
INNER JOIN salaries
	USING(playerid)
INNER JOIN collegeplaying
	USING(playerid)
INNER JOIN schools
	USING(schoolid)
WHERE schoolid = 'vandy'
GROUP BY namefirst, namelast, schoolname
ORDER BY total_earned DESC
LIMIT 5; -- David Price made $81,851,296.00


-- MICHAEL'S
WITH vandy_players AS (
    SELECT DISTINCT playerid
    FROM collegeplaying
    WHERE schoolid = 'vandy'
)
SELECT 
    namefirst || ' ' || namelast AS fullname, 
    SUM(salary)::int::MONEY AS total_salary
FROM salaries
INNER JOIN vandy_players
USING(playerid)
INNER JOIN people
USING(playerid)
GROUP BY fullname
ORDER BY total_salary DESC
LIMIT 5;

/* 2. Using the fielding table, group players into three groups based on 
their position: label players with position OF as "Outfield", 
those with position "SS", "1B", "2B", and "3B" as "Infield", 
and those with position "P" or "C" as "Battery". 
Determine the number of putouts made by each of these three groups in 
2016. */


SELECT 
	SUM(po) AS putouts,
	CASE
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
		WHEN pos IN('P', 'C') THEN 'Battery' 
		ELSE 'NULL' END AS position
FROM fielding
WHERE yearid = '2016'
	GROUP BY position;


/* 3. Find the average number of strikeouts per game by decade 
since 1920. Round the numbers you report to 2 decimal places. 
Do the same for home runs per game. Do you see any trends? 
(Hint: For this question, you might find it helpful to look at 
the **generate_series** function 
(https://www.postgresql.org/docs/9.1/functions-srf.html). 
If you want to see an example of this in action, 
check out this DataCamp video: 
https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6) */


-- CAVIN'S
WITH decade AS
	SELECT GENERATE_SERIES(MIN(yearid), MAX(yearid), 10) AS decade
SELECT
	g AS games,
	so AS strikeouts,
	hr AS homeruns,
	ROUND(((AVG(hr)) / g) , 2) AS average_homeruns_per_game,
	ROUND(((AVG(so)) / g), 2) AS average_strikeouts_per_game,
    generate_series(1920, 2025, 10) AS lower,
	generate_series(1930, 2025, 10) AS upper)
	FROM
	pitching
GROUP BY 
	games,
	strikeouts,
	homeruns
ORDER BY decade;


-- BILLY'S
WITH bins AS (
	SELECT generate_series(1920, 2025, 10) AS lower,
		   generate_series(1930, 2025, 10) AS upper),
-- subsetting data to tag of interest
	strikeouts AS (
	SELECT yearid, g, so
	FROM battingpost
	)
SELECT lower, upper, CAST(SUM(so) AS FLOAT) / CAST(SUM(g) AS FLOAT) AS avg_strikeout_per_game
	FROM bins
		LEFT JOIN strikeouts
			ON yearid >= lower
			AND yearid < upper
GROUP BY lower, upper
ORDER BY lower;


--BRANNON'S
WITH decade_int AS(
     SELECT generate_series(1920,2010,10) AS lower,
	        generate_series(1930,2020,10) AS upper)
SELECT 
	lower, 
	upper, 
	ROUND((CAST(SUM(so) AS NUMERIC))/(CAST(SUM(g) AS NUMERIC)/2), 2) AS avg_so, 
	ROUND((CAST(SUM(hr) AS NUMERIC))/(CAST(SUM(g) AS NUMERIC)/2), 2) AS avg_hr
 FROM decade_int
 LEFT JOIN teams
 ON yearid >= lower AND yearid <= upper
 GROUP BY lower, upper
 ORDER BY lower, upper;


-- ALEXA'S
WITH decades AS (
	SELECT generate_series(1920, MAX(yearid), 10) AS decade_start,
	generate_series(1929, (MAX(yearid) + 10), 10) AS decade_end
	FROM batting
)
SELECT 
	decade_start, 
	decade_end, 
	ROUND(SUM(so)::numeric/SUM(g)::numeric, 2) as total_so, 
	ROUND(SUM(hr)::numeric/SUM(g)::numeric, 2) as total_hr
	/***
	depends on how you count the games, if orioles vs braves, orioles gets counted once and 
	braves get counted once, so you can divide by two OR leave as is depending on your understanding
	***/
	-- , ROUND(SUM(hr) * 1.0 / (SUM(g) / 2.0), 2) AS hr_per_game
	-- , ROUND(SUM(so) * 1.0 / (SUM(g) / 2.0), 2) AS so_per_game 
FROM decades a 
LEFT JOIN teams b 
ON b.yearid >= a.decade_start
AND b.yearid <= a.decade_end
WHERE b.yearid >= 1920
GROUP BY 1,2
ORDER BY 1,2;


/* 4. Find the player who had the most success stealing bases in 2016,
where __success__ is measured as the percentage of stolen base attempts 
which are successful. 
(A stolen base attempt results either in a stolen base or being 
caught stealing.) 
Consider only players who attempted _at least_ 20 stolen bases. 
Report the players' names, number of stolen bases, number of attempts,
and stolen base percentage. */


SELECT
	namefirst ||' '||
	namelast AS name, 
	cs AS caught,
	sb AS stolen,
	(sb + cs) AS attempts,
	CONCAT(sb * 100 /(sb + cs), '%') AS stolen_percent 
FROM 
	(SELECT
		cs,
		sb,
		playerid,
		yearid
	FROM batting
	WHERE (cs + sb) >= 20
		AND yearid = 2016)
INNER JOIN people
	USING(playerid)
ORDER BY stolen_percent DESC;


-- ALEXA'S
WITH full_batting AS (
    SELECT
        playerid,
        SUM(sb) AS sb,
        SUM(cs) AS cs
    FROM batting
    WHERE yearid = 2016
    GROUP BY playerid
)
SELECT
    namefirst || ' ' || namelast AS full_name,
    sb, 
    sb + cs AS attempts,
    ROUND(sb * 100.0 / (sb + cs), 1) AS sb_pct
FROM full_batting
INNER JOIN people
USING(playerid)
WHERE sb + cs >= 20
ORDER BY sb_pct DESC
LIMIT 5;



/* 5. From 1970 to 2016, what is the largest number of wins for a team
that did not win the world series? 
What is the smallest number of wins for a team that did win the 
world series? Doing this will probably result in an unusually small 
number of wins for a world series champion; 
determine why this is the case. Then redo your query, 
excluding the problem year. How often from 1970 to 2016 was it the 
case that a team with the most wins also won the world series? 
What percentage of the time? */



SELECT yearid, name, w, l, wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
    AND wswin = 'N'
ORDER BY w DESC;


SELECT yearid, name, w, l, wswin
FROM teams
WHERE yearid BETWEEN 1970 AND 2016
    AND wswin = 'Y'
ORDER BY w;



--BRANNON'S
WITH CTE_1 AS (
SELECT yearid, MAX(W) AS most_wins_per_year
FROM teams
WHERE yearid >= 1970
AND yearid <= 2016
AND yearid != 1981
GROUP BY yearid
ORDER BY yearid),
ws_max_table AS (
SELECT
     yearid,
     CASE WHEN wswin = 'Y' AND most_wins_per_year = W THEN 1
	      WHEN wswin = 'N' AND most_wins_per_year = W THEN 0 END AS ws_win_max
FROM teams
INNER JOIN CTE_1
USING(yearid)
GROUP BY yearid, wswin, most_wins_per_year, W
ORDER BY yearid)
SELECT ROUND(100 * (CAST(SUM(ws_win_max) AS NUMERIC)/CAST(COUNT(DISTINCT yearid) AS NUMERIC)), 2) AS ws_win_max_percentage
FROM ws_max_table;


-- MICHAEL'S
WITH most_wins AS (
    SELECT
        yearid,
        MAX(w) AS w
    FROM teams
    WHERE yearid >= 1970
    GROUP BY yearid
    ORDER BY yearid
    ),
ws_winners_with_most_wins AS (
    SELECT 
        yearid,
        teamid,
        w
    FROM teams
    INNER JOIN most_wins
    USING(yearid, w)
    WHERE wswin = 'Y'
),
ws_years AS (
    SELECT COUNT(DISTINCT yearid)
    FROM teams
    WHERE wswin = 'Y' AND yearid >= 1970
)
SELECT 
    (SELECT COUNT(*) FROM ws_winners_with_most_wins) AS num_most_win_ws_winners,
    (SELECT * FROM ws_years) as years_with_ws,
    ROUND((SELECT COUNT(*)
     FROM ws_winners_with_most_wins
    ) * 100.0 /
    (SELECT *
     FROM ws_years
    ), 2) AS most_wins_ws_pct
    ;


-- ALEXA'S
with filtered_table AS (
SELECT 
    yearid
    , teamid
    , WSWin
    , w
    , RANK() OVER (PARTITION BY yearid ORDER BY w DESC) AS rank
FROM teams
WHERE yearid >= 1970
AND yearid <= 2016
AND yearid <> 1981 --the problem year
)
SELECT 
    ROUND(SUM(CASE WHEN wswin = 'Y' THEN 1 END ) / SUM(rank) * 100 ,2) 
    /***
    this is 12/52 TEAMS whereas 12/46 YEARS this happens. Rank doesn't account for ties
    ***/
FROM filtered_table 
WHERE rank=1;



/* 6. Which managers have won the TSN Manager of the Year award in 
both the National League (NL) and the American League (AL)? 
Give their full name and the teams that they were managing when 
they won the award. */

SELECT
    namefirst || ' ' || namelast AS name,
    a.yearid,
    awardid,
    a.lgid,
    name AS team
FROM awardsmanagers AS a
    LEFT JOIN people AS b USING (playerid)
    LEFT JOIN managers AS c USING (playerid, yearid)
    LEFT JOIN teams AS d USING (teamid, yearid)
WHERE
    a.lgid IN ('AL', 'NL')
    AND awardid = 'TSN Manager of the Year'
    AND playerid IN (
        SELECT playerid
        FROM awardsmanagers AS e
        WHERE awardid = 'TSN Manager of the Year'
            AND lgid IN ('AL', 'NL')
        GROUP BY playerid
        HAVING COUNT(DISTINCT lgid) = 2);


/* 7. Which pitcher was the least efficient in 2016 in terms of salary
/ strikeouts? Only consider pitchers who started at least 10 games 
(across all teams). Note that pitchers often play for more than one 
team in a season, so be sure that you are counting all stats for each
player. */

SELECT
    namefirst || ' ' || namelast AS name,
    SUM(salary) AS salary,
    SUM(so) AS strikeouts,
    SUM(gs) AS games_started,
    ROUND((SUM(so::numeric) / SUM(salary::numeric)), 10) AS so_per_dollar
FROM salaries AS s
INNER JOIN pitching AS pt USING (playerid)
INNER JOIN people AS p USING (playerid)
WHERE
    s.yearid = 2016
    AND gs >= 10
GROUP BY name
ORDER BY so_per_dollar;



/* 8. Find all players who have had at least 3000 career hits. 
Report those players' names, total number of hits, and the year 
they were inducted into the hall of fame (If they were not inducted 
into the hall of fame, put a null in that column.) 
Note that a player being inducted into the hall of fame is indicated 
by a 'Y' in the **inducted** column of the halloffame table. */

WITH winners AS
	(SELECT DISTINCT playerid, yearid
	FROM halloffame
	WHERE inducted = 'Y'),

career_hits AS
	(SELECT playerid, SUM(h) AS total_hits
	FROM batting
	GROUP BY playerid
	HAVING SUM(h) >= 3000)

SELECT
  a.namefirst || ' ' || a.namelast AS name,
  MAX(c.yearid) AS induction_year,
  total_hits
FROM people AS a
INNER JOIN batting AS b USING(playerid)
LEFT JOIN winners AS c USING(playerid)
INNER JOIN career_hits AS d USING(playerid)
GROUP BY
	name, total_hits
ORDER BY total_hits DESC;



/* 9. Find all players who had at least 1,000 hits for two different 
teams. Report those players' full names. */


-- ANDREW'S
WITH hitters AS 
	(SELECT
	    playerid,
	    teamid,
	    hits
	FROM (SELECT
	        playerid,
	        teamid,
	        SUM(h) AS hits
	    FROM batting
	    GROUP BY playerid, teamid
	    HAVING SUM(h) >= 1000
	) AS player_team_hits
	WHERE playerid IN (
	        SELECT 
				playerid
	        FROM (
	            SELECT 
					playerid, 
					teamid, 
					SUM(h) AS hits
	            FROM batting
	            GROUP BY 
					playerid, 
					teamid
	            HAVING SUM(h) >= 1000
	        ) AS inner_player_team_hits
	        GROUP BY 
				playerid
	        HAVING COUNT(teamid) >= 2)
	ORDER BY playerid),
teamnames AS (
    SELECT 
		DISTINCT teamid, name
    FROM teams
)
SELECT 
	namefirst||' '||namelast AS playername, 
	h.teamid AS team, 
	h.hits AS hits
FROM people AS p
INNER JOIN hitters AS h
USING(playerid);



/* 10. Find all players who hit their career highest number of home 
runs in 2016. Consider only players who have played in the league 
for at least 10 years, and who hit at least one home run in 2016. 
Report the players' first and last names and the number of home runs 
they hit in 2016. */







/* After finishing the above questions, here are some open-ended 
questions to consider. */

--**Open-ended questions**

/* 11. Is there any correlation between number of wins and team salary?
Use data from 2000 and later to answer this question. As you do this 
analysis, keep in mind that salaries across the whole league tend to 
increase together, so you may want to look on a year-by-year basis. */





/* 12. In this question, you will explore the connection between number
of wins and attendance. */

/*  a. Does there appear to be any correlation between attendance at 
home games and number of wins? */



/* b. Do teams that win the world series see a boost in attendance 
the following year? What about teams that made the playoffs? 
Making the playoffs means either being a division winner or a wild 
card winner. */




/* 13. It is thought that since left-handed pitchers are more rare, 
causing batters to face them less often, that they are more effective.
Investigate this claim and present evidence to either support or 
dispute this claim. First, determine just how rare left-handed pitchers
are compared with right-handed pitchers. Are left-handed pitchers more
likely to win the Cy Young Award? Are they more likely to make it 
into the hall of fame? */



