-- not a good one.
DECLARE @Handle varbinary(50), @Spid int = <your spid value/>
SELECT @Handle = sql_handle from master.dbo.sysprocesses where spid = @spid
DBCC INPUTBUFFER (@spid)
SELECT * FROM master.sys.fn_get_sql(@Handle)
