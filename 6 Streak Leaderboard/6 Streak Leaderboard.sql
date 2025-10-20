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
	-- Getting data that I need through the process
		Select 
			Distinct
				UserID,
				UserName,
				[Date]
		From 
			LessonStreaks
	),

	B As(
	-- Calculating the difference between the last active day and the current day for each row
		Select 
			*,
			DATEDIFF(DAY,Date,LAG([Date]) Over(Partition By UserID Order By [Date], UserID)) * -1  As Diff
		From 
			A
	),
	C As(
	-- Detecting if streak is consecutive or not
		Select
			*,
			Case
				When Diff Is Null Or Diff <> 1 Then 0
				Else 1 
			End As IsConsecutive
		From 
			B
	),
	D As(
	-- Assign streak ID for each streak per each user
		Select 
			*,
			Sum(
				Case
					When IsConsecutive Is Null Or IsConsecutive <> 1 Then 1 
					Else 0
				End) Over(Partition By UserID Order By UserID , [Date]) As StreakID
		From 
			C
	),
	E As (
	-- Finally calculating streak length
		Select
			UserID,
			UserName,
			StreakID,
			Count(*) As StreakLength,
			Max(D.[Date]) As EndDate
		From 
			D
		Group By 
			UserID,
			UserName,
			StreakID
	)
	Select
		UserID,
		UserName,
		EndDate,
		StreakLength
	From
		E
	
-- Results =======================================================================

Select 
	Top(10) *
From
	Streaks
Where
	EndDate = '2025/09/28'
Order By
	StreakLength DESC;