SELECT
SUM (user_object_reserved_page_count)*8 as usr_obj_kb,
SUM (internal_object_reserved_page_count)*8 as internal_obj_kb,
SUM (version_store_reserved_page_count)*8  as version_store_kb,
SUM (unallocated_extent_page_count)*8 as freespace_kb,
SUM (mixed_extent_page_count)*8 as mixedextent_kb
FROM sys.dm_db_file_space_usage

-- session file usage
SELECT top 5 * 
FROM sys.dm_db_session_space_usage  
ORDER BY (user_objects_alloc_page_count +
 internal_objects_alloc_page_count) DESC

-- session task space useage
SELECT top 5 * 
FROM sys.dm_db_task_space_usage
ORDER BY (user_objects_alloc_page_count +
 internal_objects_alloc_page_count) DESC

-- monitor space usage
 SELECT t1.session_id, t1.request_id, t1.task_alloc,
  t1.task_dealloc, t2.sql_handle, t2.statement_start_offset, 
  t2.statement_end_offset, t2.plan_handle
FROM (Select session_id, request_id,
    SUM(internal_objects_alloc_page_count) AS task_alloc,
    SUM (internal_objects_dealloc_page_count) AS task_dealloc 
  FROM sys.dm_db_task_space_usage 
  GROUP BY session_id, request_id) AS t1, 
  sys.dm_exec_requests AS t2
WHERE t1.session_id = t2.session_id
  AND (t1.request_id = t2.request_id)
ORDER BY t1.task_alloc DESC

-- longest running transactions
SELECT top 5 transaction_id, transaction_sequence_num, 
elapsed_time_seconds 
FROM sys.dm_tran_active_snapshot_database_transactions
ORDER BY elapsed_time_seconds DESC
