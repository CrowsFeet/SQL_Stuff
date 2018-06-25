-- quick way to drop users
ALTER DATABASE <Database_Name> SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

RESTORE DATABASE [<Database_Name>]...

-- then put the db back into normal mode
ALTER DATABASE <Database_Name> SET MULTI_USER;
GO


declare @sql as varchar(20), @spid as int
select @spid = min(spid)  from master..sysprocesses  where dbid = db_id('<database_name>') 
and spid != @@spid    

while (@spid is not null)
begin
    print 'Killing process ' + cast(@spid as varchar) + ' ...'
    set @sql = 'kill ' + cast(@spid as varchar)
    exec (@sql)

    select 
        @spid = min(spid)  
    from 
        master..sysprocesses  
    where 
        dbid = db_id('<database_name>') 
        and spid != @@spid
end 

print 'Process completed...'


