select db_name(io.database_id) as database_name,
	mf.physical_name as file_name,
	io.*
from sys.dm_io_virtual_file_stats(NULL, NULL) io
join sys.master_files mf on mf.database_id = io.database_id
	and mf.file_id = io.file_id
order by (io.num_of_bytes_read + io.num_of_bytes_written) desc;