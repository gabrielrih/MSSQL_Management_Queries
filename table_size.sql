USE Traces
GO

SELECT
    t.NAME AS Entidade,
    p.rows AS Registros,
	DB.physical_name  ARQUIVO,
    (SUM(a.total_pages) * 8 / 1024) AS EspacoTotalMB,
    (SUM(a.used_pages) * 8 / 1024) AS EspacoUsadoMB,
    ((SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024) AS EspacoNaoUsadoMB
FROM
    sys.tables t
INNER JOIN
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN 
	sys.data_spaces DS ON DS.data_space_id = A.data_space_id
INNER JOIN 
	sys.database_files 
	DB ON DB.data_space_id = DS.data_space_id
WHERE
    t.NAME NOT LIKE 'dt%'
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255
GROUP BY
    t.Name, s.Name, p.Rows,DB.physical_name
ORDER BY
    EspacoTotalMB DESC
GO