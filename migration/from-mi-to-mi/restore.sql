-- Criar credencial 
IF NOT EXISTS (
	SELECT *
	   FROM sys.credentials
	   WHERE name = 'https://my.blob.core.windows.net/dump'
)
	CREATE CREDENTIAL [https://my.blob.core.windows.net/dump]
	WITH IDENTITY = 'SHARED ACCESS SIGNATURE', SECRET = 'secret-here'
	GO

-- Check connectivity for Restore
RESTORE FILELISTONLY
FROM  
	URL = 'https://my.blob.core.windows.net/dump/database_1.bak',
	URL = 'https://my.blob.core.windows.net/dump/database_2.bak',
	URL = 'https://my.blob.core.windows.net/dump/database_3.bak',
	URL = 'https://my.blob.core.windows.net/dump/database_4.bak',
	URL = 'https://my.blob.core.windows.net/dump/database_5.bak'
GO

  
-- Restore 
-- References:
--	https://docs.azure.cn/en-us/azure-sql/managed-instance/restore-sample-database-quickstart#use-t-sql-to-restore-from-a-backup-file
--	https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-transact-sql?view=sql-server-ver17
RESTORE DATABASE [database-name]
FROM  
	URL = 'https://my.blob.core.windows.net/dump/database_1.bak',
	URL = 'https://my.blob.core.windows.net/dump/database_2.bak',
	URL = 'https://my.blob.core.windows.net/dump/database_3.bak',
	URL = 'https://my.blob.core.windows.net/dump/database_4.bak',
	URL = 'https://my.blob.core.windows.net/dump/database_5.bak'
GO

-- Progress of backup/restore
SELECT session_id as SPID, command, a.text AS Query, start_time, percent_complete
   , dateadd(second,estimated_completion_time/1000, getdate()) as estimated_completion_time
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) a
WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE')
GO


