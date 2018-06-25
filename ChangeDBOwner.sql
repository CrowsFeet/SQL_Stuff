USE <DBName_Here>
GO

EXEC sp_changedbowner 'sa'

-- is there a way to list all db owners from all dbs

select suser_sname(owner_sid) as 'Owner', state_desc, *
from sys.databases
WHERE suser_sname(owner_sid) IS NULL
