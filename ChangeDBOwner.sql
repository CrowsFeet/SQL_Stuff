-- Oldy but a goody.
-- I am still encountering databases that have lost their owner, which stops you from viewing the database
-- Properties.
-- this will sort it.
USE <DBName_Here>
GO

EXEC sp_changedbowner 'sa'

-- is there a way to list all db owners from all dbs

select suser_sname(owner_sid) as 'Owner', state_desc, *
from sys.databases
WHERE suser_sname(owner_sid) IS NULL
