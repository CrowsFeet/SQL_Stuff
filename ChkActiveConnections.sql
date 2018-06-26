-- Script to get a list of active connections on a SQL Server
USE master
go
SELECT db_name(dbid) as DatabaseName, count(dbid) as NoOfConnections,
loginame as LoginName
FROM sys.sysprocesses
WHERE dbid > 0
GROUP BY dbid, loginame
ORDER BY DatabaseName


-- sp_who2

/*
select net_address from sysprocesses where spid IN (
54,
59,
93,
125,
133,
149,
215
)

select * from sys.dm_exec_connections
ORDER by session_id
*/
