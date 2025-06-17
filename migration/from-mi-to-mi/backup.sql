-- Criar credencial 
IF NOT EXISTS (
	SELECT *
	   FROM sys.credentials
	   WHERE name = 'https://my.blob.core.windows.net/dump'
)
	CREATE CREDENTIAL [https://my.blob.core.windows.net/dump]
	WITH IDENTITY = 'SHARED ACCESS SIGNATURE', SECRET = 'secret-here'
	GO

-- Backup para Storage Account
-- References:
--	https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/sql-server-backup-to-url?view=sql-server-ver17#limitations-of-backuprestore-to-azure-blob-storage
--	https://learn.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql?view=sql-server-ver17
-- Recomendo rodar via job para evitar de cair a sessão do usuário
BACKUP DATABASE [database-name]
TO
URL = 'https://my.blob.core.windows.net/dump/hbnfe_prod_1.bak',
URL = 'https://my.blob.core.windows.net/dump/hbnfe_prod_2.bak',
URL = 'https://my.blob.core.windows.net/dump/hbnfe_prod_3.bak',
URL = 'https://my.blob.core.windows.net/dump/hbnfe_prod_4.bak',
URL = 'https://my.blob.core.windows.net/dump/hbnfe_prod_5.bak'
WITH COPY_ONLY, INIT, MAXTRANSFERSIZE = 4194304, BLOCKSIZE = 65536, COMPRESSION, STATS = 5
GO
