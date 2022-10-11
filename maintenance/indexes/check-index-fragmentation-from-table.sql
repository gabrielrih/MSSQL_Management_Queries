-- Reference: https://learn.microsoft.com/pt-br/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-ver16
DECLARE @DBId INT = DB_ID(N'HBGDT')
DECLARE @TableId INT = OBJECT_ID(N'doc_cte')

SELECT index_Type_desc,avg_page_space_used_in_percent
	,avg_fragmentation_in_percent	
	,index_level /* Árvore (0. Nível folha - leaf; 1-X. Nível intermediário; Y. Nível root (é o último nível)) */
	,record_count
	,page_count
	,fragment_count
	,avg_record_size_in_bytes
FROM sys.dm_db_index_physical_stats(@DBId, @TableId, NULL, NULL, 'LIMITED') -- DETAILED
GO
