-- Brilliant script that shows you how many cpu's there are and what is running on each one.
SELECT
  sch.cpu_id
 ,sch.is_idle AS idle
 ,(SELECT TOP 1 SUBSTRING(st.text,r.statement_start_offset / 2,((CASE
      WHEN r.statement_end_offset = -1 THEN (LEN(CONVERT(nvarchar(max),st.text)) * 2)
      ELSE r.statement_end_offset
    END) - r.statement_start_offset) / 2)) AS sql_statement
 ,
   -- s.session_id,
   -- s.login_time,
  s.host_name
 ,s.program_name
 ,ISNULL(s.login_name,'') AS login
 ,
  -- isnull(s.nt_domain, '') +'\'+ isnull(s.nt_user_name, ''),
  -- sch.parent_node_id,
  -- sch.scheduler_id,
  -- sch.status,
  -- sch.is_online,
  -- sch.preemptive_switches_count,
  -- sch.context_switches_count,
  -- sch.idle_switches_count,
  sch.current_tasks_count AS TaskCnt
 ,
  -- sch.runnable_tasks_count,
  sch.current_workers_count AS workers
 ,sch.active_workers_count AS active
 ,
 --sch.work_queue_count,
  sch.pending_disk_io_count AS pendIO
 ,sch.load_factor
 ,
 -- sch.yield_count,
 s.status
 ,s.cpu_time
 ,s.memory_usage
 ,s.total_scheduled_time
 ,s.total_elapsed_time
 ,s.reads
 ,s.writes
 ,s.logical_reads
 ,c.session_id
 ,c.node_affinity
 ,c.num_reads
 ,c.num_writes
 ,c.last_read
 ,c.last_write
 ,r.session_id
 ,r.request_id
 ,r.start_time
 ,DATEDIFF(SECOND,r.start_time,GETDATE()) AS diff_seconds
 ,r.status
 ,r.blocking_session_id
 ,r.wait_type
 ,r.wait_time
 ,r.last_wait_type
 ,r.wait_resource
 ,r.cpu_time
 ,r.total_elapsed_time
 ,r.scheduler_id
 ,r.reads
 ,r.writes
 ,r.logical_reads
 ,t.task_state
 ,t.context_switches_count
 ,t.pending_io_count
 ,t.pending_io_byte_count
 ,t.scheduler_id
 ,t.session_id
 ,t.exec_context_id
 ,t.request_id
 ,w.status
 ,w.is_preemptive
 ,w.context_switch_count
 ,w.pending_io_count
 ,w.pending_io_byte_count
 ,w.wait_started_ms_ticks
 ,w.wait_resumed_ms_ticks
 ,w.task_bound_ms_ticks
 ,w.affinity
 ,w.state
 ,w.start_quantum
 ,w.end_quantum
 ,w.last_wait_type
 ,w.quantum_used
 ,w.max_quantum
 ,w.boost_count
 ,th.os_thread_id
 ,th.status
 ,th.kernel_time
 ,th.usermode_time
 ,th.stack_bytes_committed
 ,th.stack_bytes_used
 ,th.affinity
 ,sch.parent_node_id
 ,sch.scheduler_id
 ,sch.cpu_id
 ,sch.status
 ,sch.is_online
 ,sch.is_idle
 ,sch.preemptive_switches_count
 ,sch.context_switches_count
 ,sch.idle_switches_count
 ,sch.current_tasks_count
 ,sch.runnable_tasks_count
 ,sch.current_workers_count
 ,sch.active_workers_count
 ,sch.work_queue_count
 ,sch.pending_disk_io_count
 ,sch.load_factor
 ,sch.yield_count
FROM sys.dm_os_schedulers sch
LEFT OUTER JOIN sys.dm_os_workers w ON (sch.active_worker_address = w.worker_address)
LEFT OUTER JOIN sys.dm_os_threads th ON (w.thread_address = th.thread_address)
LEFT OUTER JOIN sys.dm_os_tasks t ON (sch.active_worker_address = t.worker_address)
LEFT OUTER JOIN sys.dm_exec_requests r ON (t.session_id = r.session_id AND t.request_id = r.request_id)
LEFT OUTER JOIN sys.dm_exec_connections c ON (r.connection_id = c.connection_id)
LEFT OUTER JOIN sys.dm_exec_sessions s ON (c.session_id = s.session_id)
OUTER APPLY sys.dm_exec_sql_text(sql_handle) st
-- outer apply sys.dm_exec_query_plan(plan_handle) qp
CROSS JOIN sys.dm_os_sys_info si
WHERE sch.scheduler_id < 255
ORDER BY sch.cpu_id
