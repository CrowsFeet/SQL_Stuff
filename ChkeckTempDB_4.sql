-- tempdb file space used
select
reserved_MB=(unallocated_extent_page_count+version_store_reserved_page_count+user_object_reserved_page_count+internal_object_reserved_page_count+mixed_extent_page_count)*8/1024. ,
unallocated_extent_MB =unallocated_extent_page_count*8/1024., 
internal_object_reserved_page_count,
internal_object_reserved_MB =internal_object_reserved_page_count*8/1024.
from sys.dm_db_file_space_usage

-- tempdb version store
select 
reserved_MB=(unallocated_extent_page_count+version_store_reserved_page_count+user_object_reserved_page_count+internal_object_reserved_page_count+mixed_extent_page_count)*8/1024. ,
unallocated_extent_MB =unallocated_extent_page_count*8/1024., 
version_store_reserved_page_count,
version_store_reserved_MB =version_store_reserved_page_count*8/1024.
from sys.dm_db_file_space_usage


SELECT count(*) as amountofrec,d.name DBName 
from sys.dm_tran_version_store tvs
inner join sys.databases d on tvs.database_id = d.database_id
group by d.name



-- open transactions
SELECT 
er.session_id
,er.open_transaction_count
FROM sys.dm_exec_requests er


--Check Size of tempDB consumed by Version Store
SELECT SUM(VERSION_STORE_RESERVED_PAGE_COUNT) AS [VERSION STORE PAGES USED],
(SUM(VERSION_STORE_RESERVED_PAGE_COUNT)*1.0/128) AS [VERSION STORE SPACE IN MB],
SUM(INTERNAL_OBJECT_RESERVED_PAGE_COUNT) AS [INTERNAL OBJECT PAGES USED],
(SUM(INTERNAL_OBJECT_RESERVED_PAGE_COUNT)*1.0/128) AS [INTERNAL OBJECT SPACE IN MB],
SUM(USER_OBJECT_RESERVED_PAGE_COUNT) AS [USER OBJECT PAGES USED],
(SUM(USER_OBJECT_RESERVED_PAGE_COUNT)*1.0/128) AS [USER OBJECT SPACE IN MB],
SUM(UNALLOCATED_EXTENT_PAGE_COUNT) AS [FREE PAGES],
(SUM(UNALLOCATED_EXTENT_PAGE_COUNT)*1.0/128) AS [FREE SPACE IN MB]
FROM SYS.DM_DB_FILE_SPACE_USAGE;

-- Find session using version store
SELECT A.*,B.KPID,B.BLOCKED,B.LASTWAITTYPE,B.WAITRESOURCE,B.DBID,B.CPU,B.PHYSICAL_IO,B.MEMUSAGE,B.LOGIN_TIME,B.LAST_BATCH,
B.OPEN_TRAN,B.STATUS,B.HOSTNAME,B.PROGRAM_NAME,B.CMD,B.LOGINAME,REQUEST_ID
FROM SYS.DM_TRAN_ACTIVE_SNAPSHOT_DATABASE_TRANSACTIONS A
INNER JOIN SYS.SYSPROCESSES B
ON A.SESSION_ID = B.SPID
