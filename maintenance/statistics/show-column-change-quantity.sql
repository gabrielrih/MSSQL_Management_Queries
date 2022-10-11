WITH Tamanho_Tabelas AS (
SELECT obj.name, prt.rows
FROM sys.objects obj
JOIN sys.indexes idx on obj.object_id= idx.object_id
JOIN sys.partitions prt on obj.object_id= prt.object_id
JOIN sys.allocation_units alloc on alloc.container_id= prt.partition_id
WHERE obj.type= 'U' AND idx.index_id IN (0, 1) --and prt.rows> 1000
GROUP BY obj.name, prt.rows)

SELECT
	A.name AS Statistic_Name,
	B.name AS Table_Name,
	C.rowmodctr AS Column_Changes_Quantity
FROM sys.stats A
join sys.sysobjects B on A.object_id = B.id
join sys.sysindexes C on C.id = B.id and A.name= C.Name
JOIN Tamanho_Tabelas D on  B.name= D.Name
WHERE	substring( B.name,1,3) not in ('sys','dtp')
		and B.name = 'NUC002' -- table name
		--and C.rowmodctr > 100
		--and C.rowmodctr> D.rows*.005
ORDER BY D.rows
GO