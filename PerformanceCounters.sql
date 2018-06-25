--SELECT
--user_object_perc = CONVERT(DECIMAL(6,3), u*100.0/(u+i+v+f)),
--internal_object_perc = CONVERT(DECIMAL(6,3), i*100.0/(u+i+v+f)),
--version_store_perc = CONVERT(DECIMAL(6,3), v*100.0/(u+i+v+f)),
--free_space_perc = CONVERT(DECIMAL(6,3), f*100.0/(u+i+v+f)),
--[total] = (u+i+v+f)
--FROM (
--SELECT
--u = SUM(user_object_reserved_page_count)*8,
--i = SUM(internal_object_reserved_page_count)*8,
--v = SUM(version_store_reserved_page_count)*8,
--f = SUM(unallocated_extent_page_count)*8
--FROM
--sys.dm_db_file_space_usage
--) x;

--SELECT                
--	DB_NAME(database_id) AS 'Database_Name'
--    ,CASE WHEN file_id = 2 THEN 'Log' ELSE 'Data' END AS 'File_Type'
--    ,((size_on_disk_bytes/1024)/1024.0)                                        AS 'Size_On_Disk_in_MB'
--    ,io_stall_read_ms / num_of_reads                                                AS 'Avg_Read_Transfer_in_Ms'
--    ,CASE WHEN file_id = 2 THEN CASE WHEN io_stall_read_ms / num_of_reads < 5 THEN 'Good'
--									 WHEN io_stall_read_ms / num_of_reads < 15 THEN  'Acceptable'
--									 ELSE  'Unacceptable' END
--	ELSE
--		CASE WHEN io_stall_read_ms / num_of_reads < 10 THEN 'Good'
--			 WHEN io_stall_read_ms / num_of_reads < 20 THEN  'Acceptable'
--             ELSE  'Unacceptable' END                                                                                        
--	END AS 'Average_Read_Performance'
--    ,io_stall_write_ms / num_of_writes AS 'Avg_Write_Transfer_in_Ms'
--    ,CASE WHEN file_id = 2 THEN CASE WHEN io_stall_write_ms / num_of_writes < 5 THEN 'Good'
--									  WHEN io_stall_write_ms / num_of_writes < 15 THEN  'Acceptable'
--                                      ELSE  'Unacceptable' END
--	ELSE
--		CASE WHEN io_stall_write_ms / num_of_writes < 10 THEN 'Good'
--			 WHEN io_stall_write_ms / num_of_writes < 20 THEN 'Acceptable'
--			 ELSE  'Unacceptable' END                                                                                        
--	END AS 'Average_Write_Performance'
--	FROM                sys.dm_io_virtual_file_stats(null,null) 
--	WHERE                num_of_reads > 0 AND num_of_writes > 0


--One way that we can see if tempdb is suffering, is by checking the wait stats of the server and looking for high levels of PAGELATCH. A latch is a short-term synchronisation lock that is used by SQL Server to maintain the integrity of the physical pages of data structures in memory. Unlike locks, you are not able to influence the behaviour of latches as SQL Server manages this for us.
--I have taken his wait stat query and modified it slightly so that the column names and general formatting are more readable.
--WITH Waits AS
--        (
--                SELECT        wait_type                                                AS 'Wait_type'
--                ,        wait_time_ms / 1000.0                                        AS 'Wait_time_seconds'
--                ,        100.0 * wait_time_ms / SUM(wait_time_ms) OVER()                AS 'Percent_of_results'
--                ,        ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC)                AS 'Row_number'
--                FROM        sys.dm_os_wait_stats WITH (NOLOCK)
--                WHERE        wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK','SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR', 'LOGMGR_QUEUE','CHECKPOINT_QUEUE','REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP','CLR_MANUAL_EVENT','CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT','XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP','ONDEMAND_TASK_QUEUE', 'BROKER_EVENTHANDLER', 'SLEEP_BPOOL_FLUSH')
--        )
--        SELECT                W1.wait_type                                                AS 'Wait_Type'
--        ,                CAST(W1.Wait_time_seconds AS DECIMAL(12, 2))                AS 'Wait_time_seconds'
--        ,                CAST(W1.Percent_of_results AS DECIMAL(12, 2))                AS 'Percent_of_results'
--        ,                CAST(SUM(W2.Percent_of_results) AS DECIMAL(12, 2))        AS 'Running_percentage'
--        FROM                Waits AS W1
--        INNER JOIN        Waits AS W2 ON W2.[Row_number] <= W1.[Row_number]
--        GROUP BY        W1.[Row_number], W1.wait_type, W1.wait_time_seconds, W1.Percent_of_results
--        HAVING                SUM(W2.percent_of_results) - W1.Percent_of_results < 99 
--        OPTION (RECOMPILE);


select
reserved_MB= convert(numeric(10,2),round((unallocated_extent_page_count+version_store_reserved_page_count+user_object_reserved_page_count+internal_object_reserved_page_count+mixed_extent_page_count)*8/1024.,2)) ,
unallocated_extent_MB =convert(numeric(10,2),round(unallocated_extent_page_count*8/1024.,2)),
user_object_reserved_page_count,
user_object_reserved_MB =convert(numeric(10,2),round(user_object_reserved_page_count*8/1024.,2))
from sys.dm_db_file_space_usage


--select convert(numeric(10,2),round(sum(data_pages)*8/1024.,2)) as user_object_reserved_MB
--from tempdb.sys.allocation_units a
--inner join tempdb.sys.partitions b on a.container_id = b.partition_id
--inner join tempdb.sys.objects c on b.object_id = c.object_id

--SELECT TOP 10
--        ddtsu.session_id,(ddtsu.user_objects_alloc_page_count + ddtsu.internal_objects_alloc_page_count) objs_alloc_page,
--        TEXT,
--        query_plan
--FROM    sys.dm_db_task_space_usage ddtsu ,sys.dm_exec_requests der 
--CROSS APPLY sys.dm_exec_sql_text(sql_handle)
--        CROSS APPLY sys.dm_exec_query_plan(plan_handle) 
--WHERE   ddtsu.session_id = der.session_id
--AND ddtsu.session_id > 50
--ORDER BY objs_alloc_page DESC ;


--SELECT * FROM sys.dm_tran_active_transactions
--  WHERE name = N'worktable';

--SELECT
--st.dbid AS QueryExecutionContextDBID,
--DB_NAME(st.dbid) AS QueryExecContextDBNAME,
--st.objectid AS ModuleObjectId,
--SUBSTRING(st.TEXT,
--dmv_er.statement_start_offset/2 + 1,
--(CASE WHEN dmv_er.statement_end_offset = -1
--THEN LEN(CONVERT(NVARCHAR(MAX),st.TEXT)) * 2
--ELSE dmv_er.statement_end_offset
--END - dmv_er.statement_start_offset)/2) AS Query_Text,
--dmv_tsu.session_id ,
--dmv_tsu.request_id,
--dmv_tsu.exec_context_id,
--(dmv_tsu.user_objects_alloc_page_count - dmv_tsu.user_objects_dealloc_page_count) AS OutStanding_user_objects_page_counts,
--(dmv_tsu.internal_objects_alloc_page_count - dmv_tsu.internal_objects_dealloc_page_count) AS OutStanding_internal_objects_page_counts,
--dmv_er.start_time,
--dmv_er.command,
--dmv_er.open_transaction_count,
--dmv_er.percent_complete,
--dmv_er.estimated_completion_time,
--dmv_er.cpu_time,
--dmv_er.total_elapsed_time,
--dmv_er.reads,dmv_er.writes,
--dmv_er.logical_reads,
--dmv_er.granted_query_memory,
--dmv_es.HOST_NAME,
--dmv_es.login_name,
--dmv_es.program_name
--FROM sys.dm_db_task_space_usage dmv_tsu
--INNER JOIN sys.dm_exec_requests dmv_er
--ON (dmv_tsu.session_id = dmv_er.session_id AND dmv_tsu.request_id = dmv_er.request_id)
--INNER JOIN sys.dm_exec_sessions dmv_es
--ON (dmv_tsu.session_id = dmv_es.session_id)
--CROSS APPLY sys.dm_exec_sql_text(dmv_er.sql_handle) st
--WHERE (dmv_tsu.internal_objects_alloc_page_count + dmv_tsu.user_objects_alloc_page_count) > 0
--ORDER BY (dmv_tsu.user_objects_alloc_page_count - dmv_tsu.user_objects_dealloc_page_count) + (dmv_tsu.internal_objects_alloc_page_count - dmv_tsu.internal_objects_dealloc_page_count) DESC


 --could be helpful
select
	    t1.session_id
	    , t1.request_id
	    , task_alloc_GB = cast((t1.task_alloc_pages * 8./1024./1024.) as numeric(10,1))
	    , task_dealloc_GB = cast((t1.task_dealloc_pages * 8./1024./1024.) as numeric(10,1))
	    , host= case when t1.session_id >=50 then 'SYS' else s1.host_name end
	    , s1.login_name
	    , s1.status
	    , s1.last_request_start_time
	    , s1.last_request_end_time
	    , s1.row_count
	    , s1.transaction_isolation_level
	    , query_text=
	        coalesce((SELECT SUBSTRING(text, t2.statement_start_offset/2 + 1,
	          (CASE WHEN statement_end_offset = -1
	              THEN LEN(CONVERT(nvarchar(max),text)) * 2
	                   ELSE statement_end_offset
	              END - t2.statement_start_offset)/2)
	        FROM sys.dm_exec_sql_text(t2.sql_handle)) , 'Not currently executing')
	    , query_plan=(SELECT query_plan from sys.dm_exec_query_plan(t2.plan_handle))
	from
	    (Select session_id, request_id
	    , task_alloc_pages=sum(internal_objects_alloc_page_count +   user_objects_alloc_page_count)
	    , task_dealloc_pages = sum (internal_objects_dealloc_page_count + user_objects_dealloc_page_count)
	    from sys.dm_db_task_space_usage
	    group by session_id, request_id) as t1
	left join sys.dm_exec_requests as t2 on t1.session_id = t2.session_id and t1.request_id = t2.request_id
	left join sys.dm_exec_sessions as s1 on t1.session_id=s1.session_id
	where
	    t1.session_id > 50 -- ignore system unless you suspect there's a problem there
	    and t1.session_id > @@SPID -- ignore this request itself
	order by t1.task_alloc_pages DESC

-- colud be helpful
--SELECT
--	session_id,
--	(SUM(user_objects_alloc_page_count)*1.0/128) AS [user object space in MB],
--	(SUM(internal_objects_alloc_page_count)*1.0/128) AS [internal object space in MB]
--FROM sys.dm_db_session_space_usage
--GROUP BY session_id
--ORDER BY session_id;
--v2
SELECT
dme.original_login_name as Login_ID,
	ssu.session_id,
	(SUM(ssu.user_objects_alloc_page_count)*1.0/128) AS [user object space in MB],
	(SUM(ssu.internal_objects_alloc_page_count)*1.0/128) AS [internal object space in MB]
FROM sys.dm_db_session_space_usage ssu
left outer join sys.dm_exec_sessions dme ON dme.session_id = ssu.session_id
GROUP BY ssu.session_id, dme.original_login_name
ORDER BY ssu.session_id



--SELECT SU.session_id, 
--sum (SU.internal_objects_alloc_page_count) as session_internal_alloc,
--sum (SU.internal_objects_dealloc_page_count) as sesion_internal_dealloc, 
--sum (SU.user_objects_alloc_page_count) as session_user_alloc,
--sum (SU.user_objects_dealloc_page_count) as sesion_user_dealloc, 
--sum (TS.internal_objects_alloc_page_count) as task_internal_alloc ,
--sum (TS.internal_objects_dealloc_page_count) as task_internal_dealloc,
--sum (TS.user_objects_alloc_page_count) as task_user_alloc ,
--sum (TS.user_objects_dealloc_page_count) as task_user_dealloc
--FROM sys.dm_db_session_space_usage SU
--inner join sys.dm_db_task_space_usage TS
--on SU.session_id = TS.session_id
--where SU.session_id > 50    
--GROUP BY SU.session_id;

--;WITH s AS
--(
--    SELECT 
--        s.session_id,
--        [pages] = SUM(s.user_objects_alloc_page_count 
--          + s.internal_objects_alloc_page_count) 
--    FROM sys.dm_db_session_space_usage AS s
--    GROUP BY s.session_id
--    HAVING SUM(s.user_objects_alloc_page_count 
--      + s.internal_objects_alloc_page_count) > 0
--)
--SELECT s.session_id, s.[pages], t.[text], 
--  [statement] = COALESCE(NULLIF(
--    SUBSTRING(
--        t.[text], 
--        r.statement_start_offset / 2, 
--        CASE WHEN r.statement_end_offset < r.statement_start_offset 
--        THEN 0 
--        ELSE( r.statement_end_offset - r.statement_start_offset ) / 2 END
--      ), ''
--    ), t.[text])
--FROM s
--LEFT OUTER JOIN 
--sys.dm_exec_requests AS r
--ON s.session_id = r.session_id
--OUTER APPLY sys.dm_exec_sql_text(r.plan_handle) AS t
--ORDER BY s.[pages] DESC;

--;WITH task_space_usage AS (
--    -- SUM alloc/delloc pages
--    SELECT session_id,
--           request_id,
--           SUM(internal_objects_alloc_page_count) AS alloc_pages,
--           SUM(internal_objects_dealloc_page_count) AS dealloc_pages
--    FROM sys.dm_db_task_space_usage WITH (NOLOCK)
--    WHERE session_id <> @@SPID
--    GROUP BY session_id, request_id
--)
--SELECT TSU.session_id,
--       TSU.alloc_pages * 1.0 / 128 AS [internal object MB space],
--       TSU.dealloc_pages * 1.0 / 128 AS [internal object dealloc MB space],
--       EST.text,
--       -- Extract statement from sql text
--       ISNULL(
--           NULLIF(
--               SUBSTRING(
--                 EST.text, 
--                 ERQ.statement_start_offset / 2, 
--                 CASE WHEN ERQ.statement_end_offset < ERQ.statement_start_offset 
--                  THEN 0 
--                 ELSE( ERQ.statement_end_offset - ERQ.statement_start_offset ) / 2 END
--               ), ''
--           ), EST.text
--       ) AS [statement text],
--       EQP.query_plan
--FROM task_space_usage AS TSU
--INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK)
--    ON  TSU.session_id = ERQ.session_id
--    AND TSU.request_id = ERQ.request_id
--OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
--OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
--WHERE EST.text IS NOT NULL OR EQP.query_plan IS NOT NULL
--ORDER BY 3 DESC;


--SELECT session_id, 
--      SUM(internal_objects_alloc_page_count) AS task_internal_objects_alloc_page_count,
--      SUM(internal_objects_dealloc_page_count) AS task_internal_objects_dealloc_page_count 
--    FROM sys.dm_db_task_space_usage 
--    GROUP BY session_id;


--SELECT 
--  COALESCE(sess.nt_user_name,sess.login_name) AS LoginName,
--  sess.host_name,
--  sess.program_name,
--  sess.client_interface_name,
--  conns.client_net_address,
--  memUsed.KBytesUsed
--FROM sys.dm_exec_sessions sess
--LEFT OUTER JOIN sys.dm_exec_connections conns
--ON sess.session_id = conns.session_id
--LEFT OUTER JOIN 
--(SELECT 
--  session_id,
--  SUM(user_objects_alloc_page_count
--      + user_objects_dealloc_page_count
--      + internal_objects_alloc_page_count
--      + internal_objects_dealloc_page_count) * 8 AS KBytesUsed
--FROM sys.dm_db_task_space_usage
--WHERE database_id = 2
--GROUP BY session_id
--)memUsed
--ON memUsed.session_id = sess.session_id
----WHERE memUsed.KBytesUsed > 0
--WHERE sess.session_id = @@SPID



SELECT database_transaction_log_bytes_reserved,session_id 
  FROM sys.dm_tran_database_transactions AS tdt 
  INNER JOIN sys.dm_tran_session_transactions AS tst 
  ON tdt.transaction_id = tst.transaction_id 
  WHERE database_id = 2;

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



SELECT tst.[session_id],
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
FROM sys.dm_tran_database_transactions tdt
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
where DB_NAME (tdt.database_id) = 'tempdb'ORDER BY [Log Bytes Used] DESC


--dbcc opentran

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

SELECT session_id, STDEV(pages) stdev_pages FROM tempdb..TempDBUsage GROUP BY session_id HAVING STDEV(pages) > 0 ORDER BY stdev_pages DESC
