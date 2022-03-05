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

SELECT *
FROM salaries;

SELECT p.playerid, p.nameFIRST, p.nameLAST, s.sum()
--player id, player first name, player last name, total salary
FROM people AS p
LEFT JOIN collegeplaying AS c
ON p.playerid = c.playerid
LEFT JOIN salaries AS s
ON p.playerid = s.playerid
WHERE schoolid = 'vandy'

