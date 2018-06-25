use DBA
go
/*
CREATE function fn_hex_to_char (
  @x varbinary(100), -- binary hex value
  @l int -- number of bytes
  ) returns varchar(200)
 as 
-- Written by: Gregory A. Larsen
-- Date: May 25, 2004
-- Description:  This function will take any binary value and return 
--               the hex value as a character representation.
--               In order to use this function you need to pass the 
--               binary hex value and the number of bytes you want to
--               convert.
begin

declare @i varbinary(10)
declare @digits char(16)
set @digits = '0123456789ABCDEF'
declare @s varchar(100)
declare @h varchar(100)
declare @j int
set @j = 0 
set @h = ''
-- process all  bytes
while @j < @l
begin
  set @j= @j + 1
  -- get first character of byte
  set @i = substring(cast(@x as varbinary(100)),@j,1)
  -- get the first character
  set @s = cast(substring(@digits,@i%16+1,1) as char(1))
  -- shift over one character
  set @i = @i/16 
  -- get the second character
  set @s = cast(substring(@digits,@i%16+1,1) as char(1)) + @s
  -- build string of hex characters
  set @h = @h + @s
end
return(@h)
end
*/
--Code for usp_log_running_jobs SP:

CREATE proc usp_long_running_jobs as
-- Written by: Gregory A. Larsen
-- Date: May 25, 2004
-- Description: This stored procedure will detect long running jobs.  
--              A long running job is defined as a job that has 
--              been running over 6 hours.  If it detects any long
--              running job then an email is sent to the DBA's.

------------------
-- Begin Section 1
------------------

set nocount on 

declare @c char(1000)
declare @cnt int

-- Create table to hold job information
create table #enum_job ( 
Job_ID uniqueidentifier,
Last_Run_Date int,
Last_Run_Time int,
Next_Run_Date int,
Next_Run_Time int,
Next_Run_Schedule_ID int,
Requested_To_Run int,
Request_Source int,
Request_Source_ID varchar(100),
Running int,
Current_Step int,
Current_Retry_Attempt int, 
State int
)       

------------------
-- Begin Section 2
------------------

-- create a table to hold job_id and the job_id in hex character format
create table ##jobs (job_id uniqueidentifier , 
                     job_id_char varchar(100))

-- Get a list of jobs 	
insert into #enum_job 
      execute master.dbo.xp_sqlagent_enum_jobs 1,
                'garbage' -- doesn't seem to matter what you put here

------------------
-- Begin Section 3
------------------

-- calculate the #jobs table with job_id's
-- and their hex character representation
insert into ##jobs 
       select job_id, dba.dbo.fn_hex_to_char(job_id,16) from #enum_job

------------------
-- Begin Section 4
------------------

-- get a count or long running jobs
select @cnt = count(*) 
     from master.dbo.sysprocesses a
          join ##jobs b
          on  substring(a.program_name,32,32)= b.job_id_char
          join msdb.dbo.sysjobs c on b.job_id = c.job_id 
     -- check for jobs that have been running longer that 6 hours.
     where login_time < dateadd(hh,-6,getdate())

------------------
-- Begin Section 5
------------------

if @cnt > 0 
  -- Here are the long running jobs  
exec master.dbo.xp_sendmail                   
      @recipients='Greg.Larsen@databasejournal.com',
      @subject='Jobs Running Over 6 hours',
      @query= 'select substring(c.name,1,78) 
              ''These jobs have been running longer than 6 hours'' 
              from master.dbo.sysprocesses a  
              join ##jobs b
              on  substring(a.program_name,32,32)= b.job_id_char
              join msdb.dbo.sysjobs c on b.job_id = c.job_id 
              where login_time < dateadd(hh,-6,getdate())'

drop table #enum_job
drop table ##jobs
GO	
