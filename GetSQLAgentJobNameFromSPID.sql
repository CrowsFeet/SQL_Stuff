SET NOCOUNT ON 

DECLARE @c CHAR(1000),
		@cnt INT

--if object_id('tempdb..@Table1') is not null drop table @Table1
--if object_id('tempdb..##jobs') is not null drop table ##jobs
--drop table @Table1
--drop table ##jobs



-- Create table to hold job information
DECLARE @Table1 TABLE 
( 
	Job_ID UNIQUEIDENTIFIER,
	Last_Run_Date INT,
	Last_Run_Time INT,
	Next_Run_Date INT,
	Next_Run_Time INT,
	Next_Run_Schedule_ID INT,
	Requested_To_Run INT,
	Request_Source INT,
	Request_Source_ID VARCHAR(100),
	Running INT,
	Current_Step INT,
	Current_Retry_Attempt INT, 
	[State] INT
)       

------------------
-- Begin Section 2
------------------

-- create a table to hold job_id and the job_id in hex character format
DECLARE @Table2 TABLE
(
	job_id UNIQUEIDENTIFIER, 
    job_id_char VARCHAR(100)
)

-- Get a list of jobs 	
INSERT INTO @Table1 
      EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, 'garbage' -- doesn't seem to matter what you put here

--SELECT * FROM @Table1
------------------
-- Begin Section 3
------------------

-- calculate the #jobs table with job_id's
-- and their hex character representation
INSERT INTO @Table2
	SELECT job_id, HostedMaintenance.dbo.fn_hex_to_char(job_id,16) FROM @Table1


--SELECT * FROM @Table2

------------------
-- Begin Section 4
------------------

-- get a count or long running jobs
/*
select @cnt = count(*) 
     from master.dbo.sysprocesses a
          join @Table2 b
          on  substring(a.program_name,32,32)= b.job_id_char
          join msdb.dbo.sysjobs c on b.job_id = c.job_id 
     -- check for jobs that have been running longer that 6 hours.
--     where login_time < dateadd(hh,-6,getdate())
     where login_time < dateadd(mi,-2,getdate())
*/

------------------
-- Begin Section 5
------------------
/*
if @cnt > 0 
  -- Here are the long running jobs  
exec msdb.dbo.sp_send_dbmail
	@profile_name = 'ISS',
    @recipients='agazdowicz@expedia.com',
    @subject='Jobs Running Over 6 hours on DUBSQLAF01',
    @query= 'select 
				a.spid as SPID,
				b.job_id,
				substring(c.name,1,78) as Job_Name,
				login_time as Start_Time,
				Dateadd(mi,-2,getdate()) as CurrentTime,
				Datediff(ss, login_time,getdate()) CurrentRunTime_Secs
--	            ''These jobs have been running longer than 6 hours'' 
            from master.dbo.sysprocesses a  
            join @Table2b on  substring(a.program_name,32,32)= b.job_id_char
            join msdb.dbo.sysjobs c on b.job_id = c.job_id 
            where login_time < dateadd(mi,-2,getdate())',
	@attach_query_result_as_file = 1 
*/

SELECT 
	a.spid AS SPID,
	b.job_id,
	substring(c.name,1,78) AS Job_Name,
	login_time AS Start_Time,
	Dateadd(mi,-2,getdate()) AS CurrentTime,
	Datediff(ss, login_time,getdate()) AS CurrentRunTime_Secs
--	            ''These jobs have been running longer than 6 hours'' 
FROM master.dbo.sysprocesses a  
JOIN @Table2 b ON  SUBSTRING(a.program_name,32,32) = b.job_id_char
JOIN msdb.dbo.sysjobs c ON b.job_id = c.job_id 
--where login_time < dateadd(mi,-2,getdate())


