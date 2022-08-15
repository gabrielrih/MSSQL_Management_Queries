/**
	Check percentage of index creation.
	When using RESUMABLE=ON
*/
SELECT 
   name, 
   percent_complete,
   state_desc,
   last_pause_time,
   page_count
FROM sys.index_resumable_operations
GO

