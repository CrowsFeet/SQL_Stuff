-- My version of the index defrag process.
-- this one is a little bit clever as it also stored historical info on the processing.
-- depending on the level of detail, you can see basic info (db defrag start and end) 
-- or detailed info (db start and end and table start and end).
-- there are also sql agent jobs for this.
USE [DBA]
GO

/****** Object:  Table [dbo].[tbl_DefragAudit]    Script Date: 02/05/2018 09:08:25 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tbl_DefragAudit](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[sServerName] [nvarchar](255) NULL,
	[sText] [nvarchar](1000) NULL,
	[dDate] [datetime] NULL,
	[dStartTime] [datetime] NULL,
	[dEndTime] [datetime] NULL
) ON [PRIMARY]

GO



USE [DBA]
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_DefragDBSelectionMain]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_DefragDBSelectionMain]

CREATE PROCEDURE [dbo].[usp_DefragDBSelectionMain]

@RebuildType INT = 0,
@LogAudit INT = 0--,
--@Bypass INT = 0 -- no longer needed as DB is not live

AS

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Description : Main Stored Procedure to identify Datbases to be deragmented
--
-- Author : Andy G
--
-- Created : 10/2/2016
--
-- History : 01/03/2016 Altered SP to handle and additional parameter for REBUILD/REORGANIZE and Also to Bypass specific Db for now.
--			 22/03/2016 Altered SP and removed the db filter. the DB is now stable and live.
--           23/02/2017 Altered SP and added update statistics per db into the process. and bypass specific db
--			 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SET NOCOUNT ON

DECLARE @CMD NVARCHAR(255),
		@DBName  NVARCHAR(255)

DECLARE @Table TABLE
(
	DBName NVARCHAR(255),
	Completed INT
)

INSERT INTO @Table ( DBName,Completed ) 
SELECT name AS DBName,0 AS Completed FROM sys.databases
WHERE name like 'HZN_%'
AND state_desc = 'ONLINE'
AND CHARINDEX('_PLAY',name,1)=0
or name = 'msdb'
ORDER BY 1

--SELECT * FROM @Table

WHILE EXISTS (SELECT TOP 1 DBName FROM @Table WHERE Completed = 0)
BEGIN
	SELECT TOP 1 @DBName = DBName
    FROM @Table
    WHERE Completed = 0
    ORDER BY DBName ASC

	INSERT INTO DBA.dbo.tbl_DefragAudit (sServerName, sText, dDate, dStartTime, dEndTime)
	VALUES(@@SERVERNAME,'Starting Index Defrag on Database ' + QUOTENAME(@DBName),GETDATE(), NULL, NULL)

-- lets defrag some indexes
		--SET @Cmd = 'EXEC DBA.dbo.usp_ReIndexTables ' + QUOTENAME(@DBName)

		IF @RebuildType = 0
			SET @Cmd = 'EXEC DBA.dbo.usp_ReIndexTables ' + QUOTENAME(@DBName) + ', ' + '0'

		IF @LogAudit = 0
			SET @Cmd = @Cmd + ', ' + '0'

		IF @RebuildType = 0 AND @LogAudit = 1
			SET @Cmd = @Cmd + ', ' + '1'

		IF @RebuildType = 1
			SET @Cmd = 'EXEC DBA.dbo.usp_ReIndexTables ' + QUOTENAME(@DBName) + ', ' + '1'

		IF @RebuildType = 1 AND @LogAudit = 0
			SET @Cmd = @Cmd + ', ' + '0'

		IF @RebuildType = 1 AND @LogAudit = 1
			SET @Cmd = @Cmd + ', ' + '1'


--PRINT @Cmd
--PRINT 'GO'
		EXEC (@Cmd)

		SET @Cmd = ''''
-- update statistics time
		IF @DBName <> '<Add_DB_To_Ignore>'
		BEGIN
			SET @Cmd = 'EXEC DBA.dbo.usp_UpdateStats ' + QUOTENAME(@DBName)

			EXEC (@Cmd)
		END

	INSERT INTO DBA.dbo.tbl_DefragAudit (sServerName, sText, dDate, dStartTime, dEndTime)
	VALUES(@@SERVERNAME,'Completed Index Defrag on Database ' + QUOTENAME(@DBName),GETDATE(), NULL, NULL)

	UPDATE @Table SET Completed = 1 WHERE DBName = @DBName
	SET @Cmd = ''''

END



GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_ReIndexTables]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_ReIndexTables]

CREATE PROCEDURE [dbo].[usp_ReIndexTables]

@DBName NVARCHAR(255),
@RebuildType NVARCHAR(1) = '0',
@LogAudit NVARCHAR(1) = '0'

AS
-- THIS IS THE LATEST VERSION - 16/03/2016
-------------------------------------------------------------------------------------------------------------------------------
--
-- Description : This SP will perform the defrag of the DBs. Update Stats is now disabled as REBUILD performs this task
--
-- Created : 10-02-2016
--
-- Author : Andy G
--
-- History : 10/02/2016 Altered sys.dm_db_index_physical_stats to use 'DETAILED' in its index fragmentation check. this takes
--				 	    longer to identify indexes to defragment, but it makes sure, it finds them all as the default for this
--					    option does not scan the tables fully.
--
--			 01/03/2016 Altered SP to handle and additional parameter for REBUILD/REORGANIZE and added Table by Table Audit data
--			 16/03/2016 Altered SP to handle a few combinations mostly around a large db. effectively if its about to do perform
--						an index defrag on the big 4 tables (AUDIT, DETAIL, ENTRY and SUMMARY), then choose REORGANIZE regardless
--						of what parameters have been passed into the SP. after Reorganising the big 4, there is an update statistics
--						set for them.
--			 19/05/2017 Altered for Whittakers. seems to have issues currently, so changed them to REORGANISE
--			 23/05/2017 Removing MAXDOP from REBUILD
--
-------------------------------------------------------------------------------------------------------------------------------

SET NOCOUNT ON

DECLARE @SQL1 NVARCHAR(4000)

SET @SQL1 = ''
-- its close to the 4000 character limit
SET @SQL1 = '
USE ' + @DBName + ' 
SET NOCOUNT ON

DECLARE @StartTime DATETIME,
@EndTime DATETIME,
@BuildStats NVARCHAR(255)

DECLARE @Indexes TABLE
(DBName nvarchar(255),
IndexDeFrag nvarchar(1000))

INSERT INTO @Indexes
SELECT ''' + 
@DBName + ''' as DBName,
CASE 
WHEN (indexstats.avg_fragmentation_in_percent) > 10 AND ''' + @DBName + ''' = ''<DB_To_Ignore>'' THEN ''ALTER INDEX '' + dbindexes.[name] + '' ON '' + dbschemas.[name] + ''.'' + dbtables.[name] + '' REORGANIZE''
WHEN indexstats.avg_fragmentation_in_percent >30 and ''' + @RebuildType + ''' = ''0'' then ''ALTER INDEX '' + dbindexes.[name] + '' ON '' +dbschemas.[name] + ''.'' + dbtables.[name] + '' REBUILD'' 
WHEN indexstats.avg_fragmentation_in_percent >30 and ''' + @RebuildType + ''' = ''1'' then ''ALTER INDEX '' + dbindexes.[name] + '' ON '' +dbschemas.[name] + ''.'' + dbtables.[name] + '' REORGANIZE '' 
WHEN (indexstats.avg_fragmentation_in_percent > 10 and indexstats.avg_fragmentation_in_percent <= 30) and ''' + @RebuildType + ''' = ''0'' then ''ALTER INDEX '' + dbindexes.[name] + '' ON '' + dbschemas.[name] + ''.'' + dbtables.[name] + '' REBUILD''
WHEN (indexstats.avg_fragmentation_in_percent > 10 and indexstats.avg_fragmentation_in_percent <= 30) and ''' + @RebuildType + ''' = ''1'' then ''ALTER INDEX '' + dbindexes.[name] + '' ON '' + dbschemas.[name] + ''.'' + dbtables.[name] + '' REORGANIZE ''
ELSE NULL END AS IndexDeFrag
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, ''DETAILED'') AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id] AND indexstats.index_id = dbindexes.index_id
INNER JOIN sys.partitions p ON dbindexes.object_id = p.OBJECT_ID AND dbindexes.index_id = p.index_id
left outer join sys.sysdatabases sd on sd.dbid = DB_ID()
WHERE indexstats.database_id = DB_ID()
AND indexstats.avg_fragmentation_in_percent > 10
AND dbindexes.[name] is not null
AND dbindexes.[name] not like ''%-%''
ORDER BY indexstats.avg_fragmentation_in_percent desc

DECLARE @DBName1 NVARCHAR(255),
@IndexDeFrag1 NVARCHAR(1000)

DECLARE cloopme CURSOR FOR 
SELECT 	DBName,	IndexDeFrag
FROM @Indexes

OPEN cloopme;
DECLARE @SQL Nvarchar(2000)
		
FETCH NEXT FROM cloopme 
INTO @DBName1, @IndexDeFrag1

SET @SQL = ''''
SET @BuildStats = ''''

WHILE (@@FETCH_STATUS <> -1)
BEGIN
	--SET @SQL = ''USE '' + @DBName1 + '' + char(13) + '' '' + char(13)
	SET @SQL = @IndexDeFrag1--
	SET @StartTime = GETDATE()
	--INSERT INTO DBA.dbo.tbl_DefragAudit (sServerName, sText, dDate, dStartTime, dEndTime)
	--VALUES(@@SERVERNAME,''Starting the following...'' + @IndexDeFrag1,GETDATE())

	--PRINT @SQL
	EXEC (@SQL)
		
	SET @EndTime = GETDATE()

	IF ' + @LogAudit + ' = 1
	INSERT INTO DBA.dbo.tbl_DefragAudit (sServerName, sText, dDate, dStartTime, dEndTime)
	VALUES(@@SERVERNAME,''Completed the following...'' + @IndexDeFrag1,GETDATE(), @StartTime, @EndTime)

	FETCH NEXT FROM cloopme 
	INTO @DBName1, @IndexDeFrag1

	SET @SQL = ''''

END;
CLOSE cloopme;
DEALLOCATE cloopme;

'

--SELECT LEN(@SQL1)
--PRINT @SQL1
EXEC (@SQL1)

--EXEC sp_updatestats
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_UpdateStats]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_UpdateStats]

CREATE PROCEDURE [dbo].[usp_UpdateStats]

--DECLARE
@DBNAME nvarchar(255)

AS

SET NOCOUNT ON	

DECLARE @CMD1 NVARCHAR(4000)

SET @CMD1=''
SET @CMD1 = '
use [' + @DBNAME + ']

SET NOCOUNT ON

DECLARE @Name NVARCHAR(500),
		@Cmd NVARCHAR(4000)

SELECT name AS table_name,
Completed = 0
INTO #tmp_Stats
FROM sys.sysobjects
WHERE xtype = ''U''
AND name IS NOT null

WHILE EXISTS (SELECT * FROM #tmp_Stats WHERE Completed = 0)
BEGIN
	SELECT TOP 1 @Name = table_name
    FROM #tmp_Stats
    WHERE Completed = 0
    ORDER BY table_name ASC

		SET @Cmd = ''UPDATE STATISTICS '' + @Name +'';''
		--+ CHAR(13)+CHAR(10) 
		--+ '' WITH FULLSCAN''
	
PRINT @Cmd
--PRINT ''GO''
		EXEC (@Cmd)

	UPDATE #tmp_Stats SET Completed = 1 WHERE table_name = @Name
	SET @Cmd = ''''

END

DROP TABLE #tmp_Stats
'
--PRINT @CMD1

EXEC sp_executesql @CMD1


GO



USE [msdb]
GO

/****** Object:  Job [DBA - Rebuild Indexes]    Script Date: 02/05/2018 09:12:17 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/05/2018 09:12:17 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Rebuild Indexes', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Step1]    Script Date: 02/05/2018 09:12:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Step1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SELECT 1', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [IndexRebuild]    Script Date: 02/05/2018 09:12:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'IndexRebuild', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE DBA
go

-- 2 Params
-- Param 1 is Rebuild(0)/ReOrganize(1)
-- Param 2 is Log Audit Detailed 1 = yes 0 = No

EXEC [usp_DefragDBSelectionMain] 0,0', 
		@database_name=N'DBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'IndexRebuild', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160205, 
		@active_end_date=99991231, 
		@active_start_time=14500, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

/****** Object:  Job [DBA - Stop Rebuild Indexes Job]    Script Date: 02/05/2018 09:12:18 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 02/05/2018 09:12:18 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA - Stop Rebuild Indexes Job', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This SQL Agent job will start 2.5 hours after the Index Rebuild SQL Agent job has started to make sure that it is not still processing. This makes sure that the job does not conflict with normal daily use.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Step 1]    Script Date: 02/05/2018 09:12:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Step 1', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SELECT 1', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [StopIndexRebuild]    Script Date: 02/05/2018 09:12:18 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'StopIndexRebuild', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @JOB_NAME SYSNAME = N''DBA - Rebuild Indexes''; 
 
IF EXISTS(     
        select 1 
        from msdb.dbo.sysjobs_view job  
        inner join msdb.dbo.sysjobactivity activity on job.job_id = activity.job_id 
        where  
            activity.run_Requested_date is not null  
        and activity.stop_execution_date is null  
        and job.name = @JOB_NAME 
        ) 
BEGIN      
    PRINT ''Stopping job '''''' + @JOB_NAME + ''''''''; 
    EXEC msdb.dbo.sp_stop_job @JOB_NAME; 
END 
ELSE 
BEGIN 
    PRINT ''Job '''''' + @JOB_NAME + '''''' is Not Running ''; 
END', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'StopIndexRebuild', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160226, 
		@active_end_date=99991231, 
		@active_start_time=41600, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


