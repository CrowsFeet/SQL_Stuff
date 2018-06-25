
;WITH task_space_usage AS (
    -- SUM alloc/delloc pages
    SELECT session_id,
           request_id,
           SUM(internal_objects_alloc_page_count) AS alloc_pages,
           SUM(internal_objects_dealloc_page_count) AS dealloc_pages
    FROM sys.dm_db_task_space_usage WITH (NOLOCK)
    WHERE session_id <> @@SPID
    GROUP BY session_id, request_id
)
SELECT TSU.session_id,
       TSU.alloc_pages * 1.0 / 128 AS [internal object MB space],
       TSU.dealloc_pages * 1.0 / 128 AS [internal object dealloc MB space],
       EST.text,
       -- Extract statement from sql text
       ISNULL(
           NULLIF(
               SUBSTRING(
                 EST.text, 
                 ERQ.statement_start_offset / 2, 
                 CASE WHEN ERQ.statement_end_offset < ERQ.statement_start_offset 
                  THEN 0 
                 ELSE( ERQ.statement_end_offset - ERQ.statement_start_offset ) / 2 END
               ), ''
           ), EST.text
       ) AS [statement text],
       EQP.query_plan
FROM task_space_usage AS TSU
INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK)
    ON  TSU.session_id = ERQ.session_id
    AND TSU.request_id = ERQ.request_id
OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
WHERE EST.text IS NOT NULL OR EQP.query_plan IS NOT NULL
ORDER BY 3 DESC;

----------------------------------------------------------------------------------

SELECT database_transaction_log_bytes_reserved,session_id 
  FROM sys.dm_tran_database_transactions AS tdt 
  INNER JOIN sys.dm_tran_session_transactions AS tst 
  ON tdt.transaction_id = tst.transaction_id 
  WHERE database_id = 2;

----------------------------------------------------------------------------

SELECT tdt.database_transaction_log_bytes_reserved,tst.session_id,
       t.[text], [statement] = COALESCE(NULLIF(
         SUBSTRING(
           t.[text],
           r.statement_start_offset / 2,
           CASE WHEN r.statement_end_offset < r.statement_start_offset
             THEN 0
             ELSE( r.statement_end_offset - r.statement_start_offset ) / 2 END
         ), ''
       ), t.[text])
     FROM sys.dm_tran_database_transactions AS tdt
     INNER JOIN sys.dm_tran_session_transactions AS tst
     ON tdt.transaction_id = tst.transaction_id
         LEFT OUTER JOIN sys.dm_exec_requests AS r
         ON tst.session_id = r.session_id
         OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
     WHERE tdt.database_id = 2;

----------------------------------------------------------------------------


SELECT  tst.[session_id],
        s.[login_name] AS [Login Name],
        DB_NAME (tdt.database_id) AS [Database],
        tdt.[database_transaction_begin_time] AS [Begin Time],
        tdt.[database_transaction_log_record_count] AS [Log Records],
        tdt.[database_transaction_log_bytes_used] AS [Log Bytes Used],
        tdt.[database_transaction_log_bytes_reserved] AS [Log Bytes Rsvd],
        SUBSTRING(st.text, (r.statement_start_offset/2)+1,
        ((CASE r.statement_end_offset
                WHEN -1 THEN DATALENGTH(st.text)
                ELSE r.statement_end_offset
        END - r.statement_start_offset)/2) + 1) AS statement_text,
        st.[text] AS [Last T-SQL Text],
        qp.[query_plan] AS [Last Plan]
FROM    sys.dm_tran_database_transactions tdt
        JOIN sys.dm_tran_session_transactions tst
            ON tst.[transaction_id] = tdt.[transaction_id]
        JOIN sys.[dm_exec_sessions] s
            ON s.[session_id] = tst.[session_id]
        JOIN sys.dm_exec_connections c
            ON c.[session_id] = tst.[session_id]
        LEFT OUTER JOIN sys.dm_exec_requests r
            ON r.[session_id] = tst.[session_id]
        CROSS APPLY sys.dm_exec_sql_text (c.[most_recent_sql_handle]) AS st
        OUTER APPLY sys.dm_exec_query_plan (r.[plan_handle]) AS qp
WHERE   DB_NAME (tdt.database_id) = 'tempdb'
ORDER BY [Log Bytes Used] DESC

----------------------------------------------------------------------------
-- Good one this one.
;WITH s AS
(
    SELECT 
        s.session_id,
        [pages] = SUM(s.user_objects_alloc_page_count 
          + s.internal_objects_alloc_page_count) 
    FROM sys.dm_db_session_space_usage AS s
    GROUP BY s.session_id
    HAVING SUM(s.user_objects_alloc_page_count 
      + s.internal_objects_alloc_page_count) > 0
)
SELECT s.session_id, s.[pages], t.[text], 
  [statement] = COALESCE(NULLIF(
    SUBSTRING(
        t.[text], 
        r.statement_start_offset / 2, 
        CASE WHEN r.statement_end_offset < r.statement_start_offset 
        THEN 0 
        ELSE( r.statement_end_offset - r.statement_start_offset ) / 2 END
      ), ''
    ), t.[text])
FROM s
LEFT OUTER JOIN 
sys.dm_exec_requests AS r
ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
ORDER BY s.[pages] DESC;

---------------------------------------------------------------------------------------------

DECLARE @minutes_apart INT; SET @minutes_apart = 3
DECLARE @how_many_times INT; SET @how_many_times = 40
--DROP TABLE tempdb..TempDBUsage
--SELECT * FROM tempdb..TempDBUsage
--SELECT session_id, STDEV(pages) stdev_pages FROM tempdb..TempDBUsage GROUP BY session_id HAVING STDEV(pages) > 0 ORDER BY stdev_pages DESC

DECLARE @delay_string NVARCHAR(8); SET @delay_string = '00:' + RIGHT('0'+ISNULL(CAST(@minutes_apart AS NVARCHAR(2)), ''),2) + ':00'
DECLARE @counter INT; SET @counter = 1

SET NOCOUNT ON
if object_id('tempdb..TempDBUsage') is null
    begin
    CREATE TABLE tempdb..TempDBUsage (
        session_id INT, pages INT, num_reads INT, num_writes INT, login_time DATETIME, last_batch DATETIME,
        cpu INT, physical_io INT, hostname NVARCHAR(64), program_name NVARCHAR(128), text NVARCHAR (MAX)
    )
    end
else
    begin
        PRINT 'To view the results run this:'
        PRINT 'SELECT * FROM tempdb..TempDBUsage'
        PRINT 'OR'
        PRINT 'SELECT session_id, STDEV(pages) stdev_pages FROM tempdb..TempDBUsage GROUP BY session_id HAVING STDEV(pages) > 0 ORDER BY stdev_pages DESC'
        PRINT ''
        PRINT ''
        PRINT 'Otherwise manually drop the table by running the following, then re-run the script:'
        PRINT 'DROP TABLE tempdb..TempDBUsage'
        RETURN
    end
--GO
TRUNCATE TABLE tempdb..TempDBUsage
PRINT 'To view the results run this:'; PRINT 'SELECT * FROM tempdb..TempDBUsage'
PRINT 'OR'; PRINT 'SELECT session_id, STDEV(pages) stdev_pages FROM tempdb..TempDBUsage GROUP BY session_id HAVING STDEV(pages) > 0 ORDER BY stdev_pages DESC'
PRINT ''; PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



--SELECT SUM(version_store_reserved_page_count) AS [version store pages used], 
--(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB] 
--FROM sys.dm_db_file_space_usage; 

-- open trans
--SELECT transaction_id FROM sys.dm_tran_active_snapshot_database_transactions ORDER BY elapsed_time_seconds DESC;

-- this is good
SELECT  ssu.session_id AS [SESSION ID]
      , DB_NAME(ssu.database_id) AS [DATABASE Name]
      , host_name AS [System Name]
      , program_name AS [Program Name]
      , login_name AS [USER Name]
      , status
      , cpu_time AS [CPU TIME (in milisec)]
      , total_scheduled_time AS [Total Scheduled TIME (in milisec)]
      , total_elapsed_time AS [Elapsed TIME (in milisec)]
      , ( memory_usage * 8 ) AS [Memory USAGE (in KB)]
      , ( user_objects_alloc_page_count * 8 ) AS [SPACE Allocated FOR USER Objects (in KB)]
      , ( user_objects_dealloc_page_count * 8 ) AS [SPACE Deallocated FOR USER Objects (in KB)]
      , ( internal_objects_alloc_page_count * 8 ) AS [SPACE Allocated FOR Internal Objects (in KB)]
      , ( internal_objects_dealloc_page_count * 8 ) AS [SPACE Deallocated FOR Internal Objects (in KB)]
      , CASE is_user_process
          WHEN 1 THEN 'user SESSION'
          WHEN 0 THEN 'system session'
        END AS [SESSION Type]
      , row_count AS [ROW COUNT]
FROM    sys.dm_db_session_space_usage ssu
        INNER JOIN sys.dm_exec_sessions es ON ssu.session_id = es.session_id;

------------------------------------------------------------------------------------------------------------

SELECT
                    transaction_id AS [Transacton ID],
                    [name]      AS [TRANSACTION Name],
                    transaction_begin_time AS [TRANSACTION BEGIN TIME],
                    DATEDIFF(mi, transaction_begin_time, GETDATE()) AS [Elapsed TIME (in MIN)],
                    CASE transaction_type
                                         WHEN 1 THEN 'Read/write'
                    WHEN 2 THEN 'Read-only'
                    WHEN 3 THEN 'System'
                    WHEN 4 THEN 'Distributed'
                    END AS [TRANSACTION Type],
                    CASE transaction_state
                                         WHEN 0 THEN 'The transaction has not been completely initialized yet.'
                                         WHEN 1 THEN 'The transaction has been initialized but has not started.'
                                         WHEN 2 THEN 'The transaction is active.'
                                         WHEN 3 THEN 'The transaction has ended. This is used for read-only transactions.'
                                         WHEN 4 THEN 'The commit process has been initiated on the distributed transaction. This is for distributed transactions only. The distributed transaction is still active but further processing cannot take place.'
                                         WHEN 5 THEN 'The transaction is in a prepared state and waiting resolution.'
                                         WHEN 6 THEN 'The transaction has been committed.'
                                         WHEN 7 THEN 'The transaction is being rolled back.'
                                         WHEN 8 THEN 'The transaction has been rolled back.'
                    END AS [TRANSACTION Description]
FROM sys.dm_tran_active_transactions

---------------------------------------------------------------------------------------------------

SELECT  host_name AS [System Name]
      , program_name AS [Application Name]
      , DB_NAME(es.database_id) AS [DATABASE Name]
      , USER_NAME(user_id) AS [USER Name]
      , connection_id AS [CONNECTION ID]
      , er.session_id AS [CURRENT SESSION ID]
      , blocking_session_id AS [Blocking SESSION ID]
      , start_time AS [Request START TIME]
      , er.status AS [Status]
      , command AS [Command Type]
      , ( SELECT    text
          FROM      sys.dm_exec_sql_text(sql_handle)
        ) AS [Query TEXT]
      , wait_type AS [Waiting Type]
      , wait_time AS [Waiting Duration]
      , wait_resource AS [Waiting FOR Resource]
      , er.transaction_id AS [TRANSACTION ID]
      , percent_complete AS [PERCENT Completed]
      , estimated_completion_time AS [Estimated COMPLETION TIME (in mili sec)]
      , er.cpu_time AS [CPU TIME used (in mili sec)]
      , ( memory_usage * 8 ) AS [Memory USAGE (in KB)]
      , er.total_elapsed_time AS [Elapsed TIME (in mili sec)]
FROM    sys.dm_exec_requests er
        INNER JOIN sys.dm_exec_sessions es ON er.session_id = es.session_id
WHERE   DB_NAME(es.database_id) = 'tempdb';

----------------------------------------------------------------------------------------------

SELECT SUM(unallocated_extent_page_count) AS [free pages], 
(SUM(unallocated_extent_page_count)*1.0/128) AS [free space in MB]
FROM sys.dm_db_file_space_usage;

SELECT SUM(version_store_reserved_page_count) AS [version store pages used],
(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB]
FROM sys.dm_db_file_space_usage;

SELECT transaction_id
FROM sys.dm_tran_active_snapshot_database_transactions 
ORDER BY elapsed_time_seconds DESC;


SELECT transaction_id
FROM sys.dm_tran_active_snapshot_database_transactions 
ORDER BY elapsed_time_seconds DESC;

----------------------------------------------------------------------------------------------------------------



--SELECT SUM(version_store_reserved_page_count) AS [version store pages used], 
--(SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB] 
--FROM sys.dm_db_file_space_usage; 

-- open trans
--SELECT transaction_id FROM sys.dm_tran_active_snapshot_database_transactions ORDER BY elapsed_time_seconds DESC;

-- this is good
SELECT  ssu.session_id AS [SESSION ID]
      , DB_NAME(ssu.database_id) AS [DATABASE Name]
      , host_name AS [System Name]
      , program_name AS [Program Name]
      , login_name AS [USER Name]
      , status
      , cpu_time AS [CPU TIME (in milisec)]
      , total_scheduled_time AS [Total Scheduled TIME (in milisec)]
      , total_elapsed_time AS [Elapsed TIME (in milisec)]
      , ( memory_usage * 8 ) AS [Memory USAGE (in KB)]
      , ( user_objects_alloc_page_count * 8 ) AS [SPACE Allocated FOR USER Objects (in KB)]
      , ( user_objects_dealloc_page_count * 8 ) AS [SPACE Deallocated FOR USER Objects (in KB)]
      , ( internal_objects_alloc_page_count * 8 ) AS [SPACE Allocated FOR Internal Objects (in KB)]
      , ( internal_objects_dealloc_page_count * 8 ) AS [SPACE Deallocated FOR Internal Objects (in KB)]
      , CASE is_user_process
          WHEN 1 THEN 'user SESSION'
          WHEN 0 THEN 'system session'
        END AS [SESSION Type]
      , row_count AS [ROW COUNT]
FROM    sys.dm_db_session_space_usage ssu
        INNER JOIN sys.dm_exec_sessions es ON ssu.session_id = es.session_id;

------------------------------------------------------------------------------------------------------------

SELECT
                    transaction_id AS [Transacton ID],
                    [name]      AS [TRANSACTION Name],
                    transaction_begin_time AS [TRANSACTION BEGIN TIME],
                    DATEDIFF(mi, transaction_begin_time, GETDATE()) AS [Elapsed TIME (in MIN)],
                    CASE transaction_type
                                         WHEN 1 THEN 'Read/write'
                    WHEN 2 THEN 'Read-only'
                    WHEN 3 THEN 'System'
                    WHEN 4 THEN 'Distributed'
                    END AS [TRANSACTION Type],
                    CASE transaction_state
                                         WHEN 0 THEN 'The transaction has not been completely initialized yet.'
                                         WHEN 1 THEN 'The transaction has been initialized but has not started.'
                                         WHEN 2 THEN 'The transaction is active.'
                                         WHEN 3 THEN 'The transaction has ended. This is used for read-only transactions.'
                                         WHEN 4 THEN 'The commit process has been initiated on the distributed transaction. This is for distributed transactions only. The distributed transaction is still active but further processing cannot take place.'
                                         WHEN 5 THEN 'The transaction is in a prepared state and waiting resolution.'
                                         WHEN 6 THEN 'The transaction has been committed.'
                                         WHEN 7 THEN 'The transaction is being rolled back.'
                                         WHEN 8 THEN 'The transaction has been rolled back.'
                    END AS [TRANSACTION Description]
FROM sys.dm_tran_active_transactions


-------------------------------------------------------------------------------------------------------------------------------------------------

--CREATE VIEW all_task_usage
--AS 
--    SELECT session_id, 
--      SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
--      SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count 
--    FROM sys.dm_db_task_space_usage 
--    GROUP BY session_id;
--GO

--CREATE VIEW all_session_usage 
--AS
--    SELECT R1.session_id,
--        R1.internal_objects_alloc_page_count 
--        + R2.task_internal_objects_alloc_page_count AS session_internal_objects_alloc_page_count,
--        R1.internal_objects_dealloc_page_count 
--        + R2.task_internal_objects_dealloc_page_count AS session_internal_objects_dealloc_page_count
--    FROM sys.dm_db_session_space_usage AS R1 
--    INNER JOIN all_task_usage AS R2 ON R1.session_id = R2.session_id;
--GO


--DECLARE @max int;
--DECLARE @i int;
--SELECT @max = max (session_id)
--FROM sys.dm_exec_sessions
--SET @i = 51
--  WHILE @i <= @max BEGIN
--         IF EXISTS (SELECT session_id FROM sys.dm_exec_sessions
--                    WHERE session_id=@i)
--         DBCC INPUTBUFFER (@i)
--         SET @i=@i+1
--         END;

--CREATE VIEW all_request_usage
--AS 
--  SELECT session_id, request_id, 
--      SUM(internal_objects_alloc_page_count) AS request_internal_objects_alloc_page_count,
--      SUM(internal_objects_dealloc_page_count)AS request_internal_objects_dealloc_page_count 
--  FROM sys.dm_db_task_space_usage 
--  GROUP BY session_id, request_id;
--GO
--CREATE VIEW all_query_usage
--AS
--  SELECT R1.session_id, R1.request_id, 
--      R1.request_internal_objects_alloc_page_count, R1.request_internal_objects_dealloc_page_count,
--      R2.sql_handle, R2.statement_start_offset, R2.statement_end_offset, R2.plan_handle
--  FROM all_request_usage R1
--  INNER JOIN sys.dm_exec_requests R2 ON R1.session_id = R2.session_id and R1.request_id = R2.request_id;
--GO


--SELECT R1.sql_handle, R2.text 
--FROM all_query_usage AS R1
--OUTER APPLY sys.dm_exec_sql_text(R1.sql_handle) AS R2;


--SELECT R1.plan_handle, R2.query_plan 
--FROM all_query_usage AS R1
--OUTER APPLY sys.dm_exec_query_plan(R1.plan_handle) AS R2;

--DBCC opentran

-- these 2 are the same
select getdate() AS runtime, SUM (user_object_reserved_page_count)*8 as usr_obj_kb,
SUM (internal_object_reserved_page_count)*8 as internal_obj_kb,
SUM (version_store_reserved_page_count)*8  as version_store_kb,
SUM (unallocated_extent_page_count)*8 as freespace_kb,
SUM (mixed_extent_page_count)*8 as mixedextent_kb
FROM sys.dm_db_file_space_usage

SELECT
SUM (user_object_reserved_page_count)*8 as user_obj_kb,
SUM (internal_object_reserved_page_count)*8 as internal_obj_kb,
SUM (version_store_reserved_page_count)*8  as version_store_kb,
SUM (unallocated_extent_page_count)*8 as freespace_kb,
SUM (mixed_extent_page_count)*8 as mixedextent_kb
FROM sys.dm_db_file_space_usage

--If user_obj_kb is the highest consumer, then you that objects are being created by user queries like local or global temp tables or table variables. Also don’t forget to check if there are any permanent 
--tables created in TempDB. Very rare, but I’ve seen this happening.

--If version_store_kb is the highest consumer, then it means that the version store is growing faster than the clean up. Most likely there are long running transactions or open transaction (Sleeping state), 
--which are preventing the cleanup and hence not release tempdb space back.


SELECT es.host_name , es.login_name , es.program_name,
st.dbid as QueryExecContextDBID, DB_NAME(st.dbid) as QueryExecContextDBNAME, st.objectid as ModuleObjectId,
SUBSTRING(st.text, er.statement_start_offset/2 + 1,(CASE WHEN er.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(max),st.text)) * 2 ELSE er.statement_end_offset 
END - er.statement_start_offset)/2) as Query_Text,
tsu.session_id ,tsu.request_id, tsu.exec_context_id, 
(tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count) as OutStanding_user_objects_page_counts,
(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) as OutStanding_internal_objects_page_counts,
er.start_time, er.command, er.open_transaction_count, er.percent_complete, er.estimated_completion_time, er.cpu_time, er.total_elapsed_time, er.reads,er.writes, 
er.logical_reads, er.granted_query_memory
FROM sys.dm_db_task_space_usage tsu inner join sys.dm_exec_requests er 
 ON ( tsu.session_id = er.session_id and tsu.request_id = er.request_id) 
inner join sys.dm_exec_sessions es ON ( tsu.session_id = es.session_id ) 
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) st
WHERE (tsu.internal_objects_alloc_page_count+tsu.user_objects_alloc_page_count) > 0
ORDER BY (tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count)+(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count) 
DESC


-- You can use the following query to find the oldest transactions that are active and using row versioning.
SELECT top 20 a.session_id, a.transaction_id, a.transaction_sequence_num, a.elapsed_time_seconds,
b.program_name, b.open_tran, b.status
FROM sys.dm_tran_active_snapshot_database_transactions a
join sys.sysprocesses b
on a.session_id = b.spid
ORDER BY elapsed_time_seconds DESC

---------------------------------------------------------------------------------------------------------------------------------------


select * from tempdb.sys.all_objects
where is_ms_shipped = 0;

SELECT * FROM sys.databases

