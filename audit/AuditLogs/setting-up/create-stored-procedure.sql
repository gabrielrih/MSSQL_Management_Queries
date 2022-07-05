/**
    Create Stored Procedure for smart searching.
    Searching audit log based on keywords.
*/
USE AuditLogs
GO

CREATE PROCEDURE smart_searching
AS
BEGIN

	SET NOCOUNT ON

	-- Temporary table for keywords
	IF OBJECT_ID ('tempdb..#keywords') IS NOT NULL	
		DROP TABLE #keywords

	CREATE TABLE #keywords (
		keyword VARCHAR(20)
	)

	INSERT INTO #keywords SELECT * FROM keywords

	-- Cleaning destination table log results
	TRUNCATE TABLE Temp_Logs_Filter_Results

	-- Searching by each keyword
	DECLARE @keyword AS VARCHAR(20)
	DECLARE @thereIsMoreKeywords BIT = 1

	WHILE @thereIsMoreKeywords = 1
	BEGIN

		-- Get one keyword
		SET @keyword = NULL
		SELECT TOP 1 @keyword = keyword FROM #keywords WITH(NOLOCK)
	
		IF @keyword IS NOT NULL
		BEGIN

			-- Searching (Using keyword has userName)
			INSERT INTO Temp_Logs_Filter_Results
			SELECT @keyword, 'user_name', event_time, action_id, action_description, user_name, server_instance_name, database_name, schema_name, object_name, statement
			FROM Logs WITH(NOLOCK) WHERE user_name LIKE '%' + @keyword + '%'

			INSERT INTO Temp_Logs_Filter_Results
			SELECT @keyword, 'user_name', event_time, action_id, action_description, user_name, server_instance_name, database_name, schema_name, object_name, statement
			FROM Logs WITH(NOLOCK) WHERE user_name LIKE @keyword + '%'

			-- Searching (Using keyword in statement)
			INSERT INTO Temp_Logs_Filter_Results
			SELECT @keyword, 'statement', event_time, action_id, action_description, user_name, server_instance_name, database_name, schema_name, object_name, statement
			FROM Logs WITH(NOLOCK) WHERE statement LIKE '%' + @keyword + '%'

			-- Remove keyword from temporary table
			DELETE FROM #keywords WHERE keyword = @keyword

		END
		ELSE
		BEGIN
			SET @thereIsMoreKeywords = 0 -- force exit
		END

	END

	SET NOCOUNT OFF

END
GO