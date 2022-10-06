drop table if exists #TEMP
SELECT DISTINCT
    O.name  [TABLE],
    cast(prv.value as date) as [Boundary Point],
    max(P.rows) Total_Registro,i.index_id,i.name ix_name,P.object_id, partition_number, cast(null as numeric(15,2)) avg_fragmentation_in_percent 
into #TEMP
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
WHERE
    o.name = 'table_name'
and A.total_pages > 1000
group by O.name ,
    cast(prv.value as date)  ,i.index_id,P.object_id, partition_number,i.name
declare @index_id int,@object_id int,@partition_number int,@avg_fragmentation_in_percent numeric(15,2)
while exists(select top 1 * from #TEMP where avg_fragmentation_in_percent is null)
begin
    select top 1 @index_id=index_id,@object_id=object_id,@partition_number=partition_number
    from #TEMP 
    where avg_fragmentation_in_percent is null
    SELECT @avg_fragmentation_in_percent = avg_fragmentation_in_percent
    FROM sys.dm_db_index_physical_stats(db_id(), @object_id, @index_id, @partition_number, 'LIMITED')
    WHERE alloc_unit_type_desc = 'IN_ROW_DATA' AND index_level = 0
    update #TEMP
    set avg_fragmentation_in_percent = @avg_fragmentation_in_percent
    where @index_id=index_id and @object_id=object_id and @partition_number=partition_number
end
    select * from #TEMP
    order by avg_fragmentation_in_percent desc
    select  a.[Table], [Boundary Point],partition_number, IX_NAME,
                    CASE WHEN Ix_Name IS null
                            THEN
                                'ALTER TABLE [dbo].['+ a.[Table] + '] REBUILD'
                            ELSE
                                'ALTER INDEX ['+ ix_name+ '] ON  [dbo].['+ a.[Table] +
                                    CASE when Avg_Fragmentation_In_Percent < 30 then '] REORGANIZE PARTITION='+CAST(partition_number AS VARCHAR(5)) else '] REBUILD PARTITION='+CAST(partition_number AS VARCHAR(5))+' with (PAD_INDEX = on,FILLFACTOR =80,SORT_IN_TEMPDB =on, ONLINE =on)' end
                    END Comando,avg_fragmentation_in_percent            
    FROM #TEMP A WITH(NOLOCK) -- tabela que armazena o histórico de fragmentação
    WHERE  ((Avg_Fragmentation_In_Percent >=10 AND ix_name IS NOT NULL ) OR (ix_name IS null  AND  avg_fragmentation_in_percent > 30))
    order by ix_name