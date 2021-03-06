-- be careful when you use this script. especially on a production server.
USE master
go
--DBCC FREESYSTEMCACHE('SQL Plans')
-- Clearing *JUST* the 'SQL Plans' based on *just* the amount of Adhoc/Prepared single-use plans
DECLARE @MB decimal(19,3)
        , @Count bigint
        , @StrMB nvarchar(20)

SELECT @MB = sum(cast((CASE WHEN usecounts = 1 AND objtype IN ('Adhoc', 'Prepared') THEN size_in_bytes ELSE 0 END) as decimal(12,2)))/1024/1024 
        , @Count = sum(CASE WHEN usecounts = 1 AND objtype IN ('Adhoc', 'Prepared') THEN 1 ELSE 0 END)
        , @StrMB = convert(nvarchar(20), @MB)
FROM sys.dm_exec_cached_plans

IF @MB > 10
        BEGIN
--                DBCC FREESYSTEMCACHE('SQL Plans') 
                RAISERROR ('%s MB was allocated to single-use plan cache. Single-use plans have been cleared.', 10, 1, @StrMB)
        END
ELSE
        BEGIN
                RAISERROR ('Only %s MB is allocated to single-use plan cache – no need to clear cache now.', 10, 1, @StrMB)
                -- Note: this is only a warning message and not an actual error.
        END
GO 

-- Clearing *ALL* of your cache based on the total amount of wasted by single-use plans (2005/2008):
/*
    DECLARE @MB decimal(19,3)
            , @Count bigint
            , @StrMB nvarchar(20)

    SELECT @MB = sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(12,2)))/1024/1024 
            , @Count = sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END)
            , @StrMB = convert(nvarchar(20), @MB)
    FROM sys.dm_exec_cached_plans

    IF @MB > 1000
--            DBCC FREEPROCCACHE
            RAISERROR ('Nada', 10, 1, @StrMB)
    ELSE
            RAISERROR ('Only %s MB is allocated to single-use plan cache – no need to clear cache now.', 10, 1, @StrMB)
    GO
*/    
