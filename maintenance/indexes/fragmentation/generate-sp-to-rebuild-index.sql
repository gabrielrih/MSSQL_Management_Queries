CREATE PROCEDURE [dbo].[stp_index_maintenance]
	@MinimumToReorganize AS INT = 10,
	@MinimumToRebuild AS INT = 30,
	@MinimumPageCount AS INT = 1000
AS
BEGIN

SET NOCOUNT ON

IF Object_id('tempdb..#indices_fragmentados') IS NOT NULL
  DROP TABLE #indices_fragmentados

SELECT DISTINCT
	IDENTITY(int, 1, 1) AS Id,
	SCHEMA_NAME(o.schema_id) AS SchemaName
	,OBJECT_NAME(o.object_id) AS TableName
	,i.name  AS IndexName
	,i.type_desc AS IndexType
	,dmv.index_depth
	,CASE WHEN ISNULL(ps.function_id,0) = 0 THEN 'NO' ELSE 'YES' END AS Partitioned
	,COALESCE(fg.name ,fgp.name) AS FileGroupName
	,p.partition_number AS PartitionNumber
	,p.rows AS PartitionRows
	,dmv.page_count
	,ROUND(dmv.Avg_Fragmentation_In_Percent,2) AS Avg_Fragmentation_In_Percent
	,CASE WHEN pf.boundary_value_on_right = 1 THEN 'RIGHT' WHEN pf.boundary_value_on_right = 0 THEN 'LEFT' ELSE 'NONE' END AS PartitionRange
	,pf.name        AS PartitionFunction
	,ds.name AS PartitionScheme
	,IIF((
		CASE 
			WHEN ISNULL(ps.function_id,0) = 0 
				THEN 'NO' ELSE 'YES' 
		END = 'NO'),
			(CASE 
				WHEN dmv.avg_fragmentation_in_percent between @MinimumToReorganize and @MinimumToRebuild THEN
					'ALTER INDEX [' + I.name + '] ON [' + SCHEMA_NAME(o.schema_id) + '].[' + OBJECT_NAME(o.object_id) + '] REORGANIZE'
				WHEN dmv.avg_fragmentation_in_percent >= @MinimumToRebuild THEN
					'ALTER INDEX [' + I.name + '] ON [' + SCHEMA_NAME(o.schema_id) + '].[' + OBJECT_NAME(o.object_id) + '] REBUILD WITH (PAD_INDEX = ON, FILLFACTOR = 90, SORT_IN_TEMPDB = ON, ONLINE = ON)'
			END),
			IIF((
				CASE 
					WHEN ISNULL(ps.function_id,0) = 0 
						THEN 'NO' ELSE 'YES' 
				END = 'YES'),
			(CASE 
				WHEN dmv.avg_fragmentation_in_percent between @MinimumToReorganize and @MinimumToRebuild THEN
					'ALTER INDEX [' + I.name + '] ON [' + SCHEMA_NAME(o.schema_id) + '].[' + OBJECT_NAME(o.object_id) + '] REORGANIZE PARTITION = ' + CONVERT(NVARCHAR,p.partition_number)
				WHEN dmv.avg_fragmentation_in_percent >= @MinimumToRebuild THEN
					'ALTER INDEX [' + I.name + '] ON [' + SCHEMA_NAME(o.schema_id) + '].[' + OBJECT_NAME(o.object_id) + '] REBUILD PARTITION = ' + CONVERT(NVARCHAR,p.partition_number) + ' WITH (SORT_IN_TEMPDB = ON, ONLINE = ON)'
			END),''	)) AS 'INDEXCMD'
INTO #indices_fragmentados
FROM sys.partitions AS p WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
			ON i.object_id = p.object_id
			AND i.index_id = p.index_id
INNER JOIN sys.objects AS o WITH (NOLOCK)
			ON o.object_id = i.object_id
INNER JOIN sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, N'LIMITED') dmv
			ON dmv.OBJECT_ID = i.object_id
			AND dmv.index_id = i.index_id
			AND dmv.partition_number  = p.partition_number
LEFT JOIN sys.data_spaces AS ds WITH (NOLOCK)
		ON ds.data_space_id = i.data_space_id
LEFT JOIN sys.partition_schemes AS ps WITH (NOLOCK)
		ON ps.data_space_id = ds.data_space_id
LEFT JOIN sys.partition_functions AS pf WITH (NOLOCK)
		ON pf.function_id = ps.function_id
LEFT JOIN sys.destination_data_spaces AS dds WITH (NOLOCK)
		ON dds.partition_scheme_id = ps.data_space_id
		AND dds.destination_id = p.partition_number
LEFT JOIN sys.filegroups AS fg WITH (NOLOCK)
		ON fg.data_space_id = i.data_space_id
LEFT JOIN sys.filegroups AS fgp WITH (NOLOCK)
		ON fgp.data_space_id = dds.data_space_id
LEFT JOIN sys.partition_range_values AS prv_left WITH (NOLOCK)
		ON ps.function_id = prv_left.function_id
		AND prv_left.boundary_id = p.partition_number - 1
LEFT JOIN sys.partition_range_values AS prv_right WITH (NOLOCK)
		ON ps.function_id = prv_right.function_id
		AND prv_right.boundary_id = p.partition_number
WHERE
		OBJECTPROPERTY(p.object_id, 'ISMSShipped') = 0  
		AND dmv.index_depth > 0
		AND dmv.avg_fragmentation_in_percent >= @MinimumToReorganize
		AND i.name IS NOT NULL
		AND dmv.page_count >= @MinimumPageCount
ORDER BY
	SchemaName,
	TableName,
	IndexName,
	PartitionNumber

-- Debug
--SELECT * FROM #indices_fragmentados

-- Executing scripts
--  It may has a lot of repeated commands, so we use the distinct to do not run the same command twice
DECLARE @Id INT
DECLARE @Partitioned VARCHAR(3)
DECLARE @Avg_Fragmentation_In_Percent NUMERIC(10,2)
DECLARE @QueryToRun NVARCHAR(max)

WHILE EXISTS (
	SELECT INDEXCMD FROM #indices_fragmentados
	WHERE INDEXCMD IS NOT NULL AND INDEXCMD <> ''
)
BEGIN
	-- Get one command to run
	SELECT TOP 1
		@Id = Id,
		@Partitioned = Partitioned,
		@Avg_Fragmentation_In_Percent = Avg_Fragmentation_In_Percent,
		@QueryToRun = INDEXCMD
	FROM #indices_fragmentados
	WHERE INDEXCMD IS NOT NULL AND INDEXCMD <> ''

	-- Run command
	PRINT 'Running query ' + CAST(@Id AS VARCHAR(MAX))
	PRINT 'Fragmentation: %' + CAST(@Avg_Fragmentation_In_Percent AS VARCHAR(MAX)) + ' - Is it partitioned? ' + CAST(@Partitioned AS VARCHAR(MAX))
	PRINT @QueryToRun
	EXECUTE sp_executesql @QueryToRun

	-- Delete from the temp table the executed command
	DELETE FROM #indices_fragmentados WHERE Id = @Id;
END

SET NOCOUNT OFF

END