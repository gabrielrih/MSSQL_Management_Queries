/* Exibe índices sugeridos pelo SQL Server */
USE TesteIndexes
GO

SELECT 
dm_mid.database_id AS DatabaseID,
dm_migs.avg_user_impact*(dm_migs.user_seeks+dm_migs.user_scans) Avg_Estimated_Impact,
dm_migs.last_user_seek AS Last_User_Seek,
OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) AS [TableName],
'CREATE NONCLUSTERED INDEX [SK01_'
 + OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) +']'+ 

' ON ' + dm_mid.statement+ ' (' + ISNULL (dm_mid.equality_columns,'')
+ CASE WHEN dm_mid.equality_columns IS NOT NULL AND dm_mid.inequality_columns IS NOT NULL THEN ',' ELSE
'' END+ ISNULL (dm_mid.inequality_columns, '')
+ ')'+ ISNULL (' INCLUDE (' + dm_mid.included_columns + ')', '') AS Create_Statement,dm_migs.user_seeks,dm_migs.user_scans
FROM sys.dm_db_missing_index_groups dm_mig
INNER JOIN sys.dm_db_missing_index_group_stats dm_migs
ON dm_migs.group_handle = dm_mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details dm_mid
ON dm_mig.index_handle = dm_mid.index_handle
WHERE dm_mid.database_ID = DB_ID()
and dm_migs.last_user_seek >= getdate()-1
--and OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) = 'TableName'
ORDER BY Avg_Estimated_Impact DESC
GO