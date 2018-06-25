
-- missing indexes by DB
SELECT DatabaseName = DB_NAME(database_id) ,
  [Number Indexes Missing] = count(*) 
FROM sys.dm_db_missing_index_details 
GROUP BY DB_NAME(database_id) 
ORDER BY 2 DESC;

-- costly missing indexes
SELECT --TOP 50 
[Total Cost] = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) ,
   avg_user_impact , TableName = statement , [EqualityUsage] = equality_columns , 
  [InequalityUsage] = inequality_columns , [Include Cloumns] = included_columns 
FROM sys.dm_db_missing_index_groups g 
INNER JOIN sys.dm_db_missing_index_group_stats s ON s.group_handle = g.index_group_handle 
INNER JOIN sys.dm_db_missing_index_details d ON d.index_handle = g.index_handle 
ORDER BY [Total Cost] DESC;

-- costly queries by i/o
--REPLACE(REPLACE(REPLACE(text ,CHAR(9),''),CHAR(10),''),CHAR(13),'') as [QueryText], 

SELECT TOP 500
  @@SERVERNAME as ServerName,
  (total_logical_reads + total_logical_writes) / qs.execution_count AS [Average IO],
  (total_logical_reads + total_logical_writes) AS [Total IO],
  qs.execution_count AS [Execution count],
  REPLACE(REPLACE(REPLACE(SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
    WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
    ELSE qs.statement_end_offset
  END - qs.statement_start_offset) / 2),CHAR(9),''),CHAR(10),''),CHAR(13),'') AS [Individual Query],
  REPLACE(REPLACE(REPLACE(qt.text,CHAR(9),''),CHAR(10),''),CHAR(13),'') AS [Parent Query],
--  DB_NAME(qt.dbid) AS DatabaseName
  DB_NAME(convert(int,att.value)) AS DatabaseName
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) att
WHERE att.attribute='dbid'
AND DB_NAME(convert(int,att.value)) NOT IN ('master','HZN_SMART')
AND CHARINDEX('ALTER INDEX',qt.text,1) =0
ORDER BY [Average IO] DESC;


--FROM sys.dm_exec_query_stats qs
--CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
--WHERE CHARINDEX('ALTER INDEX',qt.text,1) =0
--ORDER BY [Average IO] DESC



-- costly quieries by cpu
SELECT TOP 500
  @@SERVERNAME as ServerName,
  total_worker_time / qs.execution_count AS [Average CPU used],
  total_worker_time AS [Total CPU used],
  qs.execution_count AS [Execution count],
  REPLACE(REPLACE(REPLACE(SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
    WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
    ELSE qs.statement_end_offset
  END - qs.statement_start_offset) / 2),CHAR(9),''),CHAR(10),''),CHAR(13),'') AS [Individual Query],
  REPLACE(REPLACE(REPLACE(qt.text,CHAR(9),''),CHAR(10),''),CHAR(13),'') AS [Parent Query],
--  DB_NAME(qt.dbid) as DatabaseName 
  DB_NAME(convert(int,att.value)) AS DatabaseName
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
CROSS APPLY sys.dm_exec_plan_attributes(qs.plan_handle) att
WHERE att.attribute='dbid'
AND DB_NAME(convert(int,att.value)) NOT IN ('master','HZN_SMART')
AND CHARINDEX('ALTER INDEX',qt.text,1) =0
ORDER BY [Average CPU used] DESC;

--FROM sys.dm_exec_query_stats qs
--CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
--WHERE CHARINDEX('ALTER INDEX',qt.text,1) =0
--ORDER BY [Average CPU used] DESC;


-- costly clr queries
SELECT TOP 10
  [Average CLR Time] = total_clr_time / execution_count,
  [Total CLR Time] = total_clr_time,
  [Execution count] = qs.execution_count,
  [Individual Query] = SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
    WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
    ELSE qs.statement_end_offset
  END - qs.statement_start_offset) / 2),
  [Parent Query] = qt.text,
  DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE total_clr_time <> 0
ORDER BY [Average CLR Time] DESC;

-- most executed queries
SELECT TOP 100
	DB_NAME(qt.dbid) as DatabaseName,
	execution_count AS [Execution count],
	REPLACE(REPLACE(REPLACE(SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
    WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
    ELSE qs.statement_end_offset
	END - qs.statement_start_offset) / 2),CHAR(9),''),CHAR(10),''),CHAR(13),'') AS [Individual Query],
  REPLACE(REPLACE(REPLACE(SUBSTRING(qt.text,1,255),CHAR(9),''),CHAR(10),''),CHAR(13),'') AS [Parent Query]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE DB_NAME(qt.dbid) = 'HZN_QUALITY'
ORDER BY [Execution count] DESC;
--   REPLACE(REPLACE(REPLACE(qt.text,CHAR(9),''),CHAR(10),''),CHAR(13),'') AS [Parent Query],


-- queries suffering from blocking
SELECT TOP 10
  [Average Time Blocked] = (total_elapsed_time - total_worker_time) / qs.execution_count,
  [Total Time Blocked] = total_elapsed_time - total_worker_time,
  [Execution count] = qs.execution_count,
  [Individual Query] = SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
    WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
    ELSE qs.statement_end_offset
  END - qs.statement_start_offset) / 2),
  [Parent Query] = qt.text,
  DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY [Average Time Blocked] DESC;


-- lowest plan reuse
SELECT TOP 10
  [Plan usage] = cp.usecounts,
  [Individual Query] = SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
    WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
    ELSE qs.statement_end_offset
  END - qs.statement_start_offset) / 2),
  [Parent Query] = qt.text,
  DatabaseName = DB_NAME(qt.dbid),
  cp.cacheobjtype
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
INNER JOIN sys.dm_exec_cached_plans AS cp
  ON qs.plan_handle = cp.plan_handle
WHERE cp.plan_handle = qs.plan_handle
AND DB_NAME(qt.dbid) = 'prod_eo_eo0'
ORDER BY [Plan usage] ASC;

-- index usage and missing clustered indexes
SELECT  OBJECT_NAME(a.object_id) AS table_name ,
        COALESCE(name, 'XXXtable with no clustered index') AS index_name ,
        type_desc AS index_type ,
        user_seeks ,
        user_scans ,
        user_lookups ,
        user_updates
FROM    sys.dm_db_index_usage_stats a
        INNER JOIN sys.indexes b ON a.index_id = b.index_id
                                    AND a.object_id = b.object_id
WHERE   database_id = DB_ID('prod_eo_eo0')
        AND a.object_id > 1000
ORDER BY 2

-- get the missing indexes that would be beneficial for speeding up queries
SELECT  D.index_handle, [statement] AS full_object_name, unique_compiles, avg_user_impact, user_scans, user_seeks, column_name, column_usage
FROM    sys.dm_db_missing_index_groups G
        JOIN sys.dm_db_missing_index_group_stats GS ON G.index_group_handle = GS.group_handle
        JOIN sys.dm_db_missing_index_details D ON G.index_handle = D.index_handle
        CROSS APPLY sys.dm_db_missing_index_columns (D.index_handle) DC
ORDER BY D.index_handle, [statement];


---------------------------------------------------------------------------------------------------------------
-- check stats for individual tables...
-- https://www.mssqltips.com/sqlservertip/1642/finding-a-better-candidate-for-your-sql-server-clustered-indexes/
SELECT   OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
         I.[NAME] AS [INDEX NAME], 
         USER_SEEKS, 
         USER_SCANS, 
         USER_LOOKUPS, 
         USER_UPDATES 
FROM     sys.dm_db_index_usage_stats AS S 
         INNER JOIN sys.indexes AS I 
           ON I.[OBJECT_ID] = S.[OBJECT_ID] 
              AND I.INDEX_ID = S.INDEX_ID 
WHERE    OBJECT_NAME(S.[OBJECT_ID]) = 'ite_ItemExtensions'

------------------------------------------------------------------------------------------------
-- find missing indexes
-- https://technet.microsoft.com/en-us/magazine/jj128029.aspx
    -- Missing Indexes in current database by Index Advantage 
    SELECT user_seeks * avg_total_user_cost * ( avg_user_impact * 0.01 ) 
    AS [index_advantage] ,
    migs.last_user_seek , 
    mid.[statement] AS [Database.Schema.Table] ,
    mid.equality_columns , 
    mid.inequality_columns , 
    mid.included_columns , migs.unique_compiles , 
    migs.user_seeks , 
    migs.avg_total_user_cost , 
    migs.avg_user_impact
    FROM sys.dm_db_missing_index_group_stats AS migs WITH ( NOLOCK ) 
    INNER JOIN sys.dm_db_missing_index_groups AS mig WITH ( NOLOCK ) 
    ON migs.group_handle = mig.index_group_handle 
    INNER JOIN sys.dm_db_missing_index_details AS mid WITH ( NOLOCK ) 
    ON mig.index_handle = mid.index_handle
    WHERE mid.database_id = DB_ID()
    ORDER BY index_advantage DESC ;

---------------------------------------------------------------------------------------------------
    --- Index Read/Write stats (all tables in current DB)
    SELECT OBJECT_NAME(s.[object_id]) AS [ObjectName] , 
    i.name AS [IndexName] , i.index_id , 
    user_seeks + user_scans + user_lookups AS [Reads] , 
    user_updates AS [Writes] , 
    i.type_desc AS [IndexType] , 
    i.fill_factor AS [FillFactor]
    FROM sys.dm_db_index_usage_stats AS s 
    INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
    WHERE OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1 
    AND i.index_id = s.index_id 
    AND s.database_id = DB_ID()
    ORDER BY OBJECT_NAME(s.[object_id]) , 
    writes DESC ,
    reads DESC ;
-------------------------------------------------------------------------------------------------
    -- List unused indexes
    SELECT OBJECT_NAME(i.[object_id]) AS [Table Name] ,
    i.name
    FROM sys.indexes AS i 
    INNER JOIN sys.objects AS o ON i.[object_id] = o.[object_id]
    WHERE i.index_id NOT IN ( SELECT s.index_id 
    FROM sys.dm_db_index_usage_stats AS s 
    WHERE s.[object_id] = i.[object_id] 
    AND i.index_id = s.index_id 
    AND database_id = DB_ID() ) 
    AND o.[type] = 'U'
    ORDER BY OBJECT_NAME(i.[object_id]) ASC ;

	-------------------------------------------------------------------------------------------

	    -- Possible Bad NC Indexes (writes > reads)
    SELECT OBJECT_NAME(s.[object_id]) AS [Table Name] , 
    i.name AS [Index Name] , 
    i.index_id , 
    user_updates AS [Total Writes] , 
    user_seeks + user_scans + user_lookups AS [Total Reads] , 
    user_updates - ( user_seeks + user_scans + user_lookups ) 
    AS [Difference]
    FROM sys.dm_db_index_usage_stats AS s WITH ( NOLOCK ) 
    INNER JOIN sys.indexes AS i WITH ( NOLOCK ) 
    ON s.[object_id] = i.[object_id] 
    AND i.index_id = s.index_id
    WHERE OBJECTPROPERTY(s.[object_id], 'IsUserTable') = 1 
    AND s.database_id = DB_ID() 
    AND user_updates > ( user_seeks + user_scans + user_lookups ) 
    AND i.index_id > 1
    ORDER BY [Difference] DESC , 
    [Total Writes] DESC , 
    [Total Reads] ASC ;

---------------------------------------------------------------------------------------------------------
-- http://basitaalishan.com/2012/06/15/find-unused-indexes-using-sys-dm_db_index_usage_stats/

USE prod_eo_eo0
GO
-- Ensure a USE statement has been executed first.
-- unused indexes.
SELECT u.*
FROM [sys].[indexes] i
INNER JOIN [sys].[objects] o ON (i.OBJECT_ID = o.OBJECT_ID)
LEFT JOIN [sys].[dm_db_index_usage_stats] u ON (i.OBJECT_ID = u.OBJECT_ID)
    AND i.[index_id] = u.[index_id]
    AND u.[database_id] = DB_ID() --returning the database ID of the current database
WHERE o.[type] <> 'S' --shouldn't be a system base table
    AND i.[type_desc] <> 'HEAP'
    AND i.[name] NOT LIKE 'PK_%'
    AND u.[user_seeks] + u.[user_scans] + u.[user_lookups] = 0
    AND u.[last_system_scan] IS NOT NULL
ORDER BY 1 ASC

---------------------------------------------------------------------------

--SELECT 
--sqlserver_start_time AS DateLastSQLRestart,
--CONVERT(INT, GETDATE() - sqlserver_start_time) AS DaysSinceLastRestart
--FROM sys.dm_os_sys_info

USE prod_eo_eo0
GO
SELECT  creation_time 
        ,last_execution_time
        ,total_physical_reads
        ,total_logical_reads 
        ,total_logical_writes
        , execution_count
        , total_worker_time
        , total_elapsed_time
        , total_elapsed_time / execution_count avg_elapsed_time
        ,SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
         ((CASE statement_end_offset
          WHEN -1 THEN DATALENGTH(st.text)
          ELSE qs.statement_end_offset END
            - qs.statement_start_offset)/2) + 1) AS statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
ORDER BY execution_count DESC,total_elapsed_time / execution_count DESC;



/*
--SELECT * FROM sys.dm_exec_query_stats qs
-- Top 50 by CPU
SELECT TOP 50
  [Average CPU used] = total_worker_time / qs.execution_count,
  [Total CPU used] = total_worker_time,
--  [Execution count] = qs.execution_count,
--  [Individual Query] = SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
--    WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
--    ELSE qs.statement_end_offset
--  END - qs.statement_start_offset) / 2),
REPLACE(REPLACE(REPLACE(qt.text,CHAR(10),''),CHAR(13),''),CHAR(9),'') AS [Parent Query]--,
--  DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY [Average CPU used] DESC;

-- Top 50 most executed queries
SELECT TOP 50
  [Execution count] = execution_count,
  --[Individual Query] = SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
  --  WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
  --  ELSE qs.statement_end_offset
  --END - qs.statement_start_offset) / 2),
REPLACE(REPLACE(REPLACE(qt.text,CHAR(10),''),CHAR(13),''),CHAR(9),'') AS [Parent Query]--,
--  DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY [Execution count] DESC;


-- list of SELECT * FROM
SELECT DISTINCT --TOP 50
  [Execution count] = execution_count,
  --[Individual Query] = SUBSTRING(qt.text, qs.statement_start_offset / 2, (CASE
  --  WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2
  --  ELSE qs.statement_end_offset
  --END - qs.statement_start_offset) / 2),
REPLACE(REPLACE(REPLACE(qt.text,CHAR(10),''),CHAR(13),''),CHAR(9),'') AS [Parent Query]--,
--  DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qt.text LIKE '%SELECT * FROM%'
ORDER BY [Execution count] DESC;

-- Get process currently running.
SELECT sqltext.TEXT,
req.session_id,
req.status,
req.command,
req.cpu_time,
req.total_elapsed_time
FROM sys.dm_exec_requests req
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext 


*/