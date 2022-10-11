CREATE PROCEDURE [dbo].[stp_partitioned_index_maintenance]
AS
BEGIN
    DECLARE @Debug AS BIT = 0
	DECLARE @Fragmentation_To_Reorganize_In_Percent AS INT = 10
	DECLARE @Fragmentation_To_Rebuild_In_Percent AS INT = 30
	DECLARE @Min_Total_Pages AS INT = 1000

SET NOCOUNT ON

DROP TABLE IF EXISTS #TEMP_INDEXES
DROP TABLE IF EXISTS #TEMP_COMMANDS

-- Search partition indexes
SELECT DISTINCT
    O.name  [TABLE],
    cast(prv.value as date) as [Boundary Point],
    max(P.rows) Total_Registro,i.index_id,i.name ix_name,P.object_id, partition_number, cast(null as numeric(15,2)) avg_fragmentation_in_percent 
INTO #TEMP_INDEXES
FROM
    sys.objects O
    join sys.indexes i on o.object_id = i.object_id
    INNER JOIN sys.partition_schemes s ON i.data_space_id = s.data_space_id
    INNER JOIN sys.partition_functions AS pf  on s.function_id=pf.function_id
    INNER JOIN sys.partitions P ON O.object_id = P.object_id
    INNER JOIN sys.allocation_units A ON A.container_id = P.hobt_id
    INNER JOIN sys.tables T ON O.object_id = T.object_id
    INNER JOIN sys.data_spaces DS ON DS.data_space_id = A.data_space_id
    INNER JOIN sys.database_files DB ON DB.data_space_id = DS.data_space_id
    LEFT JOIN sys.partition_range_values as prv on prv.function_id=pf.function_id
    and p.partition_number=
        CASE pf.boundary_value_on_right WHEN 1
            THEN prv.boundary_id + 1
        ELSE prv.boundary_id
        END
WHERE A.total_pages > @Min_Total_Pages
GROUP BY O.name, CAST(prv.value as date), i.index_id, P.object_id, partition_number, i.name

-- Get index avg fragmentation
DECLARE @index_id int, @object_id int, @partition_number int, @avg_fragmentation_in_percent numeric(15,2)
WHILE EXISTS(SELECT TOP 1 * FROM #TEMP_INDEXES WHERE avg_fragmentation_in_percent IS NULL)
BEGIN

    SELECT TOP 1 @index_id=index_id, @object_id=object_id, @partition_number=partition_number
    FROM #TEMP_INDEXES
    WHERE avg_fragmentation_in_percent IS NULL

    SELECT @avg_fragmentation_in_percent = avg_fragmentation_in_percent
    FROM sys.dm_db_index_physical_stats(db_id(), @object_id, @index_id, @partition_number, 'LIMITED')
    WHERE alloc_unit_type_desc = 'IN_ROW_DATA' AND index_level = 0

    UPDATE #TEMP_INDEXES SET avg_fragmentation_in_percent = @avg_fragmentation_in_percent
    WHERE @index_id=index_id and @object_id=object_id and @partition_number=partition_number

END

-- PRINT ALL INDEXES
IF @Debug = 1
BEGIN
	SELECT * FROM #TEMP_INDEXES ORDER BY avg_fragmentation_in_percent DESC
END

-- PRINT COMMAND TO RUN
SELECT  a.[Table] AS Tabela, [Boundary Point],partition_number, IX_NAME,
	CASE WHEN IX_NAME IS NULL
			THEN
				'ALTER TABLE [dbo].['+ a.[Table] + '] REBUILD'
			ELSE
				'ALTER INDEX ['+ IX_NAME + '] ON  [dbo].['+ a.[Table] +
					CASE
						WHEN Avg_Fragmentation_In_Percent < @Fragmentation_To_Rebuild_In_Percent THEN '] REORGANIZE PARTITION=' + CAST(partition_number AS VARCHAR(5))
						ELSE '] REBUILD PARTITION=' + CAST(partition_number AS VARCHAR(5)) + ' WITH (PAD_INDEX = ON, FILLFACTOR =80, SORT_IN_TEMPDB =ON, ONLINE =ON)'
					END
	END Comando, avg_fragmentation_in_percent, 'Pending' AS Status  
INTO #TEMP_COMMANDS
FROM #TEMP_INDEXES A
WHERE Avg_Fragmentation_In_Percent >= @Fragmentation_To_Reorganize_In_Percent
ORDER BY ix_name

-- ALL COMMANDS TO RUN
IF @Debug = 1
BEGIN
	SELECT * FROM #TEMP_COMMANDS
END

-- Execute REBUILD/REORGANIZE one by one
DECLARE @Tabela AS VARCHAR(50), @IX_NAME AS VARCHAR(200), @CommandToRun AS NVARCHAR(500)
WHILE EXISTS(SELECT TOP 1 * FROM #TEMP_COMMANDS WHERE Status = 'Pending')
	BEGIN

		SELECT TOP 1 @Tabela = Tabela, @partition_number = partition_number, @IX_NAME = IX_NAME, @CommandToRun = Comando
		FROM #TEMP_COMMANDS
		WHERE Status = 'Pending'

		-- T-SQL to be executed
		PRINT @CommandToRun

		/** Descomente a linha abaixo para executar */
		EXECUTE sp_executesql @CommandToRun

		UPDATE #TEMP_COMMANDS SET Status = 'Done'
		WHERE Tabela = @Tabela AND partition_number = @partition_number AND IX_NAME = @IX_NAME

	END
END

SET NOCOUNT OFF

GO


