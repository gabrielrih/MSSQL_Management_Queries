-- DESTINO
-- Restore backup full
DECLARE @Date AS NVARCHAR(25),
        @TSQL AS NVARCHAR(MAX),
        @ContainerName AS NVARCHAR(MAX),
        @StorageAccountName AS VARCHAR(MAX),
        @BackupFilename AS VARCHAR(100),
        @URL AS VARCHAR(MAX),
        @SASKey AS VARCHAR(MAX),
        @DatabaseName AS SYSNAME;

-- Change it (Storage Account)
SET @StorageAccountName = 'this-is-my-sa'
SET @ContainerName = 'mycontainer'
SET @SASKey = 'token'

-- Change it (Target database)
SET @BackupFilename = 'database_2023_06_13T13_55.bak'
SET @DatabaseName = 'database'

-- Do not change it
SET @Date = REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR, GETDATE(), 100), '  ', '_'), ' ', '_'), '-', '_'), ':', '_')
SET @URL = 'https://' + @StorageAccountName + '.blob.core.windows.net/' + @ContainerName

IF EXISTS (SELECT * FROM sys.credentials WHERE name = @URL)
BEGIN
	DROP CREDENTIAL [@URL]
END

PRINT 'Creating credential ' + @URL
SELECT @TSQL = 'CREATE CREDENTIAL [https://' + @StorageAccountName + '.blob.core.windows.net/' + @ContainerName + '] WITH IDENTITY = ''SHARED ACCESS SIGNATURE'', SECRET = ''' + REPLACE(@SASKey, '?sv=', 'sv=') + ''';'
SELECT @TSQL
EXEC (@TSQL)

SET @URL = 'https://' + @StorageAccountName + '.blob.core.windows.net/' + @ContainerName + '/' + @BackupFilename
PRINT 'Testing connection to ' + @URL
SELECT @TSQL = 'RESTORE FILELISTONLY FROM '
SELECT @TSQL += 'URL = N''' + @URL + ''';'
SELECT @TSQL
EXEC (@TSQL)

PRINT 'Restoring database ' + @DatabaseName + ' from ' + @URL
SELECT @TSQL = 'RESTORE DATABASE [' + @DatabaseName + '] FROM '
SELECT @TSQL += 'URL = N''' + @URL + ''';'
SELECT @TSQL
EXEC (@TSQL)