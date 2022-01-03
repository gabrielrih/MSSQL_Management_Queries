SELECT i.[name] AS IndexName
    ,SUM(s.[used_page_count]) * 8 AS IndexSizeKB
FROM sys.dm_db_partition_stats AS s
INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id]
    AND s.[index_id] = i.[index_id]
	join sysobjects o ON i.[object_id] = o .id
where o.name = 'Table_Name'
GROUP BY i.[name]
ORDER BY 2 desc