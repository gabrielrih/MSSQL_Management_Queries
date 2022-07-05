USE [AuditLogs]
GO

-- Defining keywords
TRUNCATE TABLE keywords
INSERT INTO keywords VALUES ('auditoria')
INSERT INTO keywords VALUES ('test')
GO

-- Running smart searching (using keywords)
DECLARE @RC int
EXECUTE @RC = [dbo].[smart_searching] 
GO