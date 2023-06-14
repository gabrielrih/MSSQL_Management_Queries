-- ORIGEM
-- BACKUP FULL (USING SAS TOKEN)
DECLARE @Date AS NVARCHAR(25),
        @TSQL AS NVARCHAR(MAX),
        @ContainerName AS NVARCHAR(MAX),
        @StorageAccountName AS VARCHAR(MAX),
        @URL AS VARCHAR(MAX),
        @SASKey AS VARCHAR(MAX),
        @DatabaseName AS SYSNAME;

-- Change it (Storage Account)
SET @StorageAccountName = 'this-is-my-sa'
SET @ContainerName = 'mycontainer'
SET @SASKey = 'token'

-- Change it (Source database)
SET @DatabaseName = 'database'

-- Do not change it
SET @Date = FORMAT(GETDATE(), 'yyyy_MM_ddTHH_mm')
SET @URL = 'https://' + @StorageAccountName + '.blob.core.windows.net/' + @ContainerName

IF  EXISTS (SELECT * FROM sys.credentials WHERE name = @URL)
BEGIN
    DROP CREDENTIAL [@URL]
END

PRINT 'Creating credential ' + @URL
SELECT @TSQL = 'CREATE CREDENTIAL [https://' + @StorageAccountName + '.blob.core.windows.net/' + @ContainerName + '] WITH IDENTITY = ''SHARED ACCESS SIGNATURE'', SECRET = ''' + REPLACE(@SASKey, '?sv=', 'sv=') + ''';'
SELECT @TSQL
EXEC (@TSQL)

PRINT 'Backuping database ' + @DatabaseName + ' to ' + @URL
SELECT @TSQL = 'BACKUP DATABASE [' + @DatabaseName + '] TO '
SELECT @TSQL += 'URL = N''https://' + @StorageAccountName + '.blob.core.windows.net/' + @ContainerName + '/' + @DatabaseName + '_' + @Date + '.bak'''
SELECT @TSQL += ' WITH COMPRESSION, MAXTRANSFERSIZE = 4194304, BLOCKSIZE = 65536, CHECKSUM, FORMAT, STATS = 1;'
SELECT @TSQL
EXEC (@TSQL)