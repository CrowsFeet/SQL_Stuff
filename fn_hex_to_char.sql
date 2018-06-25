USE HostedMaintenance
GO

CREATE FUNCTION fn_hex_to_char 
(  
  @x VARBINARY(100), -- binary hex value  
  @l INT -- number of bytes  
) 
RETURNS VARCHAR(200)  

AS 

-----------------------------------------------------------------------------------------------------------------------------
--
-- Description:		This function will take any binary value and return the hex value as a character representation.  
--					In order to use this function you need to pass the binary hex value and the number of bytes you want to  
--					convert.  
--
-- Author :			Andy G
--
-- Created :		12/03/2018
--
-- History :
--
-----------------------------------------------------------------------------------------------------------------------------

BEGIN  
  
DECLARE @i VARBINARY(10),
		@digits CHAR(16), 
		@s VARCHAR(100),
		@h VARCHAR(100),
		@j INT  

SET @digits = '0123456789ABCDEF'  

SET @j = 0   
SET @h = ''  

-- process all  bytes  
WHILE @j < @l  
BEGIN  
  SET @j= @j + 1  
  -- get first character of byte  
  SET @i = SUBSTRING(CAST(@x AS VARBINARY(100)),@j,1)  
  -- get the first character  
  SET @s = CAST(SUBSTRING(@digits,@i%16+1,1) AS CHAR(1))  
  -- shift over one character  
  SET @i = @i/16   
  -- get the second character  
  SET @s = CAST(SUBSTRING(@digits,@i%16+1,1) AS CHAR(1)) + @s  
  -- build string of hex characters  
  SET @h = @h + @s  
END  
RETURN(@h)
END  
