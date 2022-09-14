/*
	Esta query mostra a utilizacao dos indices de uma determinada tabela desde que o SQL Server foi reinicializado.
	- user_Updates (Insert, update, delete)

	Muito user_Updates e user_lookups é ruim. 
*/
USE TesteIndexes
GO

DECLARE @TableName VARCHAR(100) = 'TestFragmentation'

SELECT getdate(), o.Name,i.name, s.user_seeks,s.user_scans,s.user_lookups, s.user_Updates, 
	isnull(s.last_user_seek,isnull(s.last_user_scan,s.last_User_Lookup)) Ultimo_acesso,fill_factor
FROM sys.dm_db_index_usage_stats s
	 join sys.indexes i on i.object_id = s.object_id and i.index_id = s.index_id
	 join sys.sysobjects o on i.object_id = o.id
WHERE s.database_id = db_id() and o.name in (@TableName) --and i.name = 'SK02_Telefone_Cliente'
ORDER BY s.user_seeks + s.user_scans + s.user_lookups DESC

GO