-- QUESTION 1: What range of years for baseball games played does the provided database cover?
SELECT yearID
FROM batting
GROUP BY yearID
ORDER BY yearID ASC;

SELECT MAX(yearID), MIN(yearID), (MAX(yearID) - MIN(yearID)) AS range
FROM batting;
--ANSWER: 145 years: 1871 - 2016





-- QUESTION 2: Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?
-- I need to look at the g_all column to understand something:
SELECT *
FROM appearances

--can I find the team name in the teams table?
SELECT *
FROM teams;

-- What about players who played for multiple teams?...
SELECT playerid, count(teamid)
FROM appearances
GROUP BY playerid;

--loesbi01 played for 12 teams, let's look at that
SELECT *
FROM appearances
WHERE playerid = 'loesbi01';

--JUST KIDDING I DIDN'T ACCOUNT FOR DUPLICATES take 2
SELECT playerid, COUNT(DISTINCT teamid)
FROM appearances
GROUP BY playerid;

--aardsda01 played for 8 teams, let's look at that
SELECT *
FROM appearances
WHERE playerid = 'aardsda01';

--so g_all is total games played in a given year. mmmmmkay. let's try this.
SELECT p.playerID, p.nameFIRST, p.nameLAST, p.nameGIVEN, p.height, sum(a.g_all) AS total_appearances, a.teamid, count(a.teamid) AS team_count
FROM people AS p
JOIN appearances AS a
ON p.playerID = a.playerID
GROUP BY p.playerID, p.height, a.teamID
ORDER BY p.height ASC;

--lol I forgot team name take 2
SELECT p.playerID, p.nameFIRST, p.nameLAST, p.nameGIVEN, p.height, sum(a.g_all) AS total_appearances, a.teamid, t.name, count(a.teamid) AS team_count
FROM people AS p
JOIN appearances AS a
ON p.playerID = a.playerID
JOIN teams AS t
ON a.teamid = t.teamid
GROUP BY p.playerID, p.nameFIRST, p.nameLAST, p.nameGIVEN, p.height, a.teamID, t.name
ORDER BY p.height ASC;

--wait... let me double-check the total appearances for this guy, because it said 1 in the query without the team name and 52 in the query with...
SELECT *
FROM appearances
WHERE playerid = 'gaedeed01';

--that's whack. maybe the join type is the issue? Or I can try adding a where subquery to only pull the shortest guy?
SELECT p.playerID, p.nameFIRST, p.nameLAST, p.nameGIVEN, p.height, sum(a.g_all) AS total_appearances, a.teamid, t.name, count(a.teamid) AS team_count
FROM people AS p
LEFT JOIN appearances AS a
ON p.playerID = a.playerID
LEFT JOIN teams AS t
ON a.teamid = t.teamid
WHERE p.height = (SELECT min(height)
				 FROM people)
GROUP BY p.playerID, p.nameFIRST, p.nameLAST, p.nameGIVEN, p.height, a.teamID, t.name
ORDER BY p.height ASC;

--this won't solve my problem, but... let's see how many appearances the team has in total
SELECT teamID, sum(g_all)
FROM appearances
WHERE teamID = 'SLA'
GROUP BY teamID;

--ANSWER: Eddie Gaedel (Edward Carl Gaedel) was the shortest player in the database at 43 inches tall. He played in one total game, for the St. Louis Browns. I can't get my query to work, but I'm gonna put a pin in it and come back.





--QUESTION 3: Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
--what's the difference between the schools table and the college table?
SELECT *
FROM schools;

SELECT *
FROM collegeplaying;

--note to self: schools is just data about each school, collegeplaying is where each player played in college, as well as when they played.

--what is vanderbilt's schoolid?
SELECT *
FROM schools
WHERE schoolname LIKE 'Vanderbilt%';
--Vanderbilt's schoolid is 'vandy'

--understanding the salaries table
SELECT *
FROM salaries;

--trying a full query with a CTE
WITH total_salaries AS (
SELECT playerID, sum(salary) AS total_salary
FROM salaries
GROUP BY playerID)

SELECT DISTINCT p.playerid, p.nameFIRST, p.nameLAST, ts.total_salary
FROM people AS p
LEFT JOIN collegeplaying AS c
ON p.playerid = c.playerid
LEFT JOIN total_salaries AS ts
ON p.playerid = ts.playerid
WHERE schoolid = 'vandy' AND total_salary IS NOT null
ORDER BY total_salary DESC;

--ANSWER: David Price (playerID priceda01) earned the most money in tha majors of all the Vanderbilt players, earning a total of $81,851,296.00





--QUESTION 4: Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.
SELECT * 
FROM fielding;

--ok, let's take a stab at it... current plan is to select
--player id, position, position group CASE statement, # putouts each, # putouts by category window
--I think I'll try using a CTE for the case statement so it doesn't get too muddy to read
WITH position_cat AS (
SELECT playerid,
	(CASE WHEN pos = 'OF' THEN 'Outfield'
	 WHEN pos = '1B' OR pos = '2B' OR pos = '3B' OR pos = 'SS' THEN 'Infield'
	 WHEN pos IN ('P', 'C') THEN 'Battery'
	 ELSE null END) AS category
FROM fielding)
SELECT
	f.playerid,
	f.pos,
	position_cat.category,
	f.PO AS putout_count,
	SUM(f.PO) OVER(PARTITION BY position_cat.category) AS cat_putouts
FROM fielding AS f
LEFT JOIN position_cat
ON f.playerid = position_cat.playerid
WHERE yearid = 2016
GROUP BY f.playerid, f.pos, position_cat.category, f.po;

--the categories are all coming out as Battery............................... but when I run the CTE as its own query, it doesn't................... what the HECK.

--try it without a CTE, and without the window statement
SELECT f.playerid, f.pos, 
	(CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos = '1B' OR pos = '2B' OR pos = '3B' OR pos = 'SS' THEN 'Infield'
	WHEN pos = 'P' OR pos = 'C' THEN 'Battery' ELSE null END) AS category,
	f.PO as putout_count,
	SUM(f.PO) OVER (PARTITION BY category ORDER BY playerid)
FROM fielding AS f
WHERE yearid = 2016;
--this query doesn't work because the case statement is creating a column that I want to partition by, but I can't because of order of operations... hmm ok. back to the drawing board

--let's try something simpler. case statement in a CTE, but no playerid or pos rows?...

WITH c AS (
SELECT playerid,
	CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos = '1B' OR pos = '2B' OR pos = '3B' OR pos = 'SS' THEN 'Infield'
	WHEN pos = 'P' OR pos = 'C' THEN 'Battery' ELSE null END AS category
FROM fielding)
SELECT
	c.category
	SUM(PO) OVER (PARTITION BY category)
FROM fielding
LEFT JOIN c
ON fielding.playerid = c.playerid
--this has an error that I don't understand but I think I just realized I'm being dumb and there's a much simpler way

SELECT sum(po),
	CASE WHEN pos = 'OF' THEN 'Outfield'
	WHEN pos = '1B' OR pos = '2B' OR pos = '3B' OR pos = 'SS' THEN 'Infield'
	WHEN pos = 'P' OR pos = 'C' THEN 'Battery' ELSE null END AS category
FROM fielding
WHERE yearid = 2016
GROUP BY category
ORDER BY category DESC;

--yeah ok, that's better. dang, Abi. 
--ANSWER: Outfield 29,560  |  Infield 58,934  |  Battery 41,424





--QUESTION 5: Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?






