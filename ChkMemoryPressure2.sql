-- may be useless as it reported itself
 select
                db_name(sp.dbid),sp.spid,er.wait_type,er.wait_time,er.wait_resource,er.total_elapsed_time,st.text,qp.query_plan
                ,ec.net_packet_size,ec.client_net_address,es.host_name,es.program_name,es.client_interface_name
                ,es.status,es.cpu_time,qmg.granted_memory_kb,es.total_scheduled_time,es.total_elapsed_time
                ,es.reads,es.writes,es.logical_reads

    from
                    sys.dm_exec_requests er
    inner join      master.dbo.sysprocesses sp
    on              er.session_id=sp.spid
    inner join      sys.dm_exec_connections ec
    on              er.session_id=ec.session_id
    inner join      sys.dm_exec_sessions es
    on              ec.session_id=es.session_id
    inner join      sys.dm_exec_query_memory_grants qmg
    on er.session_id=qmg.session_id
    cross apply     (select text from sys.dm_exec_sql_text(er.sql_handle)) st
    cross apply     (select * from sys.dm_exec_query_plan(er.plan_handle)) qp
