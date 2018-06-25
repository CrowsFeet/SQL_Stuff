select hostname,elapsed_time_seconds,session_id, is_snapshot, blocked, lastwaittype, cpu, physical_io,  open_tran, cmd 
from sys.dm_tran_active_snapshot_database_transactions a
join master..sysprocesses b
on a.session_id=b.spid 
order by a.elapsed_time_seconds desc

SELECT SUM(version_store_reserved_page_count) AS [version store pages used], (SUM(version_store_reserved_page_count)*1.0/128) AS [version store space in MB] 
FROM sys.dm_db_file_space_usage; 


SELECT GETDATE() AS runtime,
    SUM(user_object_reserved_page_count) * 8 AS usr_obj_kb,
    SUM(internal_object_reserved_page_count) * 8 AS internal_obj_kb,
    SUM(version_store_reserved_page_count) * 8 AS version_store_kb,
    SUM(unallocated_extent_page_count) * 8 AS freespace_kb,
    SUM(mixed_extent_page_count) * 8 AS mixedextent_kb
FROM sys.dm_db_file_space_usage;

-- Active sessions
select r.session_id,
       r.cpu_time,
       p.physical_io,
       t.text,
       substring(t.text, r.statement_start_offset/2 + 1, case when r.statement_end_offset = -1 then len(t.text) else (r.statement_end_offset - r.statement_start_offset)/2 end) as text_running,
       p.blocked,
       db_name(p.dbid) as dbname,
       r.status,
       r.command,
       r.start_time,
       r.wait_type,
       p.waitresource,
       p.status,
       p.open_tran,
       p.loginame,         
       p.hostname,
       p.program_name,
       r.percent_complete,
       r.wait_type,
       r.last_wait_type,
       p.waittime
from sys.dm_exec_requests r
       cross apply sys.dm_exec_sql_text(r.sql_handle) t
       inner join sys.sysprocesses p on p.spid = r.session_id
