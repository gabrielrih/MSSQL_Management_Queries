DECLARE @MinimumOfModificationCounter AS INT = 1000
DECLARE @LastUpdatedDateMoreThan AS INT = 12

SELECT
	SCHEMA_NAME(tab.schema_id) as schema_name,
    OBJECT_NAME(stat.object_id) as 'table_name',
    stat.name as 'statistic_name',     
    last_updated as 'last_updated', 
    rows as 'total_rows',
    modification_counter as 'modification_counter'
FROM sys.stats AS stat
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp
INNER JOIN sys.tables AS tab ON stat.object_id = tab.object_id
WHERE
	modification_counter >= @MinimumOfModificationCounter AND
	last_updated <= DATEADD(HOUR, -@LastUpdatedDateMoreThan, GETDATE()) AND
	tab.is_external = 0 -- all user tables
