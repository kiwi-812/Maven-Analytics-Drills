USE master;
GO
-- Creating Database =======================================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'MavenAnalytics' )
	BEGIN
		CREATE DATABASE MavenAnalytics
			ON (
				NAME = 'MavenAnalyticsData',
				FILENAME = 'F:\Kareem\MavenAnalytics\6 Streak Leaderboard\DB/MavenAnalyticsData.MDF',
				SIZE = 100MB,
				FILEGROWTH = 10MB,
				MAXSIZE = UNlIMITED
			)
			LOG ON (
				NAME = 'MavenAnalyticsLog',
				FILENAME = 'F:\Kareem\MavenAnalytics\6 Streak Leaderboard\DB/MavenAnalyticsLog.LDF',
				SIZE = 100MB,
				FILEGROWTH = 10MB,
				MAXSIZE = UNlIMITED		
			)
	END;
GO

-- Creating Table =======================================================================

Use MavenAnalytics;
Go

IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'LessonStreaks')
	BEGIN
		CREATE TABLE LessonStreaks (
		  ID nvarchar(50) PRIMARY KEY,
		  LessonID nvarchar(50),
		  [Date] date,
		  UserID nvarchar(50),
		  UserName nvarchar(100)
		)
	END;
GO

-- Loading Data =======================================================================

BULK INSERT LessonStreaks 
FROM 'F:\Kareem\MavenAnalytics\6 Streak Leaderboard\RawData/LessonStreaks.csv' 
WITH (
		FIRSTROW=2,
		FIELDTERMINATOR=',',
		ROWTERMINATOR='\n',
		TABLOCK);
Go

-- Preperations =======================================================================

Use MavenAnalytics;
Go

Create View Streaks As
-- I created this view to make it easier to load the data into Power BI or Excel later

	With A As(
	--Here I'm trying to get the user's last active day before the current day for each row
		Select 
			*,
			LAG([Date]) Over(Partition By UserID Order By [Date], UserID) As LastDay
		From 
			LessonStreaks
	),

	B As(
	-- Here I'm calculating the difference between the last active day and the current day for each row
		Select 
			Distinct *,
			DATEDIFF(DAY,Date,LastDay) * -1  As Diff
		From 
			A
		Where
			Date <> LastDay
	)
	-- Here I'm detecting if streak is consecutive or not
		Select
			*,
			Case
				When Diff <> 1 Then 0
				Else 1 
			End As IsConsecutive
		From 
			B
;

-- Results =======================================================================

Select 
	Distinct * 
From
	Streaks
Order By
	UserID, [Date];
