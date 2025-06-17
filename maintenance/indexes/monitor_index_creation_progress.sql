-- Monitoring the progress of an index creation/rebuild
-- Pre requisites:
--  You must run the following command before the CREATE INDEX or ALTER INDEX: SET STATISTICS PROFILE ON

-- Then, on another session, you run the query below pointing to the session_id of the index creation
SELECT
	node_id,
	physical_operator_name, 
	SUM(row_count) row_count, 
	SUM(estimate_row_count) AS estimate_row_count,
	CAST(SUM(row_count)*100 AS float)/SUM(estimate_row_count)  as estimate_percent_complete
FROM sys.dm_exec_query_profiles
WHERE session_id = 102
GROUP BY node_id,physical_operator_name
ORDER BY node_id DESC
GO
