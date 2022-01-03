/** Reference: https://www.mssqltips.com/sqlservertip/1239/how-to-get-index-usage-information-in-sql-server/ */
USE DBINVOICY_SAAS
GO

SELECT   OBJECT_NAME(S.[OBJECT_ID]) AS [OBJECT NAME], 
         I.[NAME] AS [INDEX NAME], 
         USER_SEEKS, 
         USER_SCANS, 
         USER_LOOKUPS, 
         USER_UPDATES 
FROM     SYS.DM_DB_INDEX_USAGE_STATS AS S 
         INNER JOIN SYS.INDEXES AS I 
           ON I.[OBJECT_ID] = S.[OBJECT_ID] 
              AND I.INDEX_ID = S.INDEX_ID 
WHERE   
	OBJECTPROPERTY(S.[OBJECT_ID],'IsUserTable') = 1 AND
	I.[NAME] IN ('PK__NUC033', 'UNUC0331') -- Filtrar pelo nome dos índices
GO