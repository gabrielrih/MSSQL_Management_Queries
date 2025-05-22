SET NOCOUNT ON

DECLARE @DatabaseName AS VARCHAR(50) = 'database-name'
DECLARE @CurrentState AS VARCHAR(50)
DECLARE @Now AS VARCHAR(50)
DECLARE @Message AS VARCHAR(200);

WHILE 1 = 1
BEGIN
    SELECT @CurrentState = state_desc FROM sys.databases WHERE name = @DatabaseName
	SET @Now = CONVERT(VARCHAR(50), GETDATE(), 120)
	SET @Message = 'Timestamp: ' + @Now + ' | State: ' + @CurrentState;
	RAISERROR(@Message, 0, 1) WITH NOWAIT;
    RAISERROR('Waiting 2 minutes...', 0, 1) WITH NOWAIT;
    WAITFOR DELAY '00:02:00';  -- 2 minutes
END

SET NOCOUNT OFF
GO
