DECLARE @DBName AS VARCHAR(50)
SET @DBName = 'DBINVOICY_URUGUAI'

SELECT
    db.name as DBName,
	mf.name as FileName,
    type_desc,
    Physical_Name,
	size,
	growth
FROM
    sys.master_files mf
INNER JOIN 
    sys.databases db ON db.database_id = mf.database_id
WHERE
	db.name = @DBName
ORDER BY mf.name