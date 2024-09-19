-- Query to get PK and columns
SELECT '[' + s.NAME + '].[' + so.NAME + ']' AS 'table_name'
    ,+ i.NAME AS 'index_name'
    ,CASE 
        WHEN i.is_disabled = 1
            THEN '<disabled> ' 
        ELSE '' 
        END + LOWER(i.type_desc) + CASE 
            WHEN i.is_unique = 1
                THEN ', unique' + CASE
                    WHEN i.is_unique_constraint = 1
                        THEN ' (constraint)'
                    ELSE '' END
            ELSE ''
            END + CASE 
            WHEN i.is_primary_key = 1
                THEN ', primary key'
            ELSE ''
        END AS 'index_description'
    ,STUFF((
            SELECT ', [' + sc.name + ']' AS "text()"
            FROM sys.columns AS sc
            INNER JOIN sys.index_columns AS ic ON ic.object_id = sc.object_id
                AND ic.column_id = sc.column_id
            WHERE sc.object_id = so.object_id
                AND ic.index_id = i.index_id
                AND ic.is_included_column = 0
            ORDER BY key_ordinal
            FOR XML PATH('')
            ), 1, 2, '') AS 'indexed_columns'
    ,STUFF((
            SELECT ', [' + sc.name + ']' AS "text()"
            FROM sys.columns AS sc
            INNER JOIN sys.index_columns AS ic ON ic.object_id = sc.object_id AND ic.column_id = sc.column_id
            WHERE sc.object_id = so.object_id
                AND ic.index_id = i.index_id
                AND ic.is_included_column = 1
            FOR XML PATH('')
            ), 1, 2, '') AS 'included_columns'
FROM sys.indexes AS i
INNER JOIN sys.objects AS so ON so.object_id = i.object_id 
    AND so.is_ms_shipped = 0 -- Exclude objects created by internal component
INNER JOIN sys.schemas AS s ON s.schema_id = so.schema_id
WHERE
	so.type = 'U' AND
	i.type = 1 AND -- 1 = PK, 0 = heap
	s.name NOT IN ('ItensTarefaRefugo', 'RefugoFotos', 'Refugos', 'TarefaConferenciaRefugo', 'TarefaRefugo', 'CollectAgeTask',
	'StockCountConfigurationHistory', 'Balanca', 'ConfiguracaoFefoCliente', 'ItemOcp', 'BusinessTaskRequest', 'UnloadTask', 'ItemColetaIdade',
	'LancamentoOcorrencia', 'Rota', 'AgrupadorTarefaMovimentacaoInterna', 'ConfiguracaoAgendamento', 'ConfiguracaoLayout', 'VehicleStorageTask', 'ItemMovement',
	'DocumentStorageTask', 'LocationStorageTask', 'StorageTask', 'ItemStock', 'Company', 'Cliente', 'CurvaItem', 'Item', 'Load', 'LoadPhoto', 'Location', 'User') AND
    so.NAME <> 'sysdiagrams'
ORDER BY 'table_name', 'index_name'
