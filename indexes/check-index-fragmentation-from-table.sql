USE TesteIndexes
GO

DECLARE @DBName VARCHAR(100) = 'TesteIndexes'
DECLARE @TableName VARCHAR(100) = 'TestFragmentation'

SELECT index_Type_desc,avg_page_space_used_in_percent
	,avg_fragmentation_in_percent	
	,index_level /* Árvore (0. Nível folha - leaf; 1-X. Nível intermediário; Y. Nível root (é o último nível)) */
	,record_count
	,page_count
	,fragment_count
	,avg_record_size_in_bytes
FROM sys.dm_db_index_physical_stats(DB_ID(@DBName), OBJECT_ID(@TableName), NULL, NULL, 'DETAILED')
GO