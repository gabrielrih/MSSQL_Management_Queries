SELECT  OBJECT_NAME(ID) As Tabela, Rows As Linhas FROM sysindexes
WHERE IndID IN (0,1)
--and  Rows >= 1000000
and OBJECT_NAME(ID) = 'doc_cte' -- table name
ORDER BY Linhas DESC