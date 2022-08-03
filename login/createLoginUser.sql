-- Creates the login
USE MASTER
GO
CREATE LOGIN [userName] WITH PASSWORD = 'thisIsThePassword'
GO

-- Creates the user in a specific database
USE databaseName
GO
CREATE USER [userName] FOR LOGIN [userName] WITH DEFAULT_SCHEMA=[dbo]
GO

-- Add the role role for user
EXEC sp_addrolemember N'db_datareader', N'userName'
GO