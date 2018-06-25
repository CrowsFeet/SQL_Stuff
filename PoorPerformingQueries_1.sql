USE master
go
 SET NOCOUNT ON

DROP TABLE #temp_requests

-- Checked for currenlty running queries by putting data in temp table
DECLARE @Date datetime

SET @Date = getdate()

--insert into #temp_requests
SELECT 
	 @Date as ReportTime
	,s.session_id
    ,r.STATUS
    ,r.blocking_session_id
    ,r.wait_type
    ,wait_resource
    ,r.wait_time / (1000.0) 'WaitSec'
    ,r.cpu_time
    ,r.logical_reads
    ,r.reads
    ,r.writes
    ,r.total_elapsed_time / (1000.0) 'ElapsSec'
    ,Substring(st.TEXT, (r.statement_start_offset / 2) + 1, (
            (
                CASE r.statement_end_offset
                    WHEN - 1
                        THEN Datalength(st.TEXT)
                    ELSE r.statement_end_offset
                    END - r.statement_start_offset
                ) / 2
            ) + 1) AS statement_text
    ,Coalesce(Quotename(Db_name(st.dbid)) + N'.' + Quotename(Object_schema_name(st.objectid, st.dbid)) + N'.' + Quotename(Object_name(st.objectid, st.dbid)), '') AS command_text
    ,r.command
    ,s.login_name
    ,s.host_name
    ,s.program_name
    ,s.host_process_id
    ,s.last_request_end_time
    ,s.login_time
    ,r.open_transaction_count
INTO #temp_requests
FROM sys.dm_exec_sessions AS s
INNER JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
WHERE r.session_id != @@SPID
and [program_name] <> 'Quest Diagnostic Server (Deadlock Trace)'
ORDER BY r.cpu_time DESC
    ,r.STATUS
    ,r.blocking_session_id
    ,s.session_id


select * from #temp_requests
where ReportTime = @Date 
