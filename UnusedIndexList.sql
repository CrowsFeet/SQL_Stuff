-- hmmm needs a table.
-- i am sure i have better ones than this.
--SELECT * FROM Tbl_Indexes
;WITH cte
AS
(
	SELECT 
		ti.TableName,
		ti.IndexName,
		sum(ti.user_seeks) AS SumOfSeeks,
		sum(ti.User_Scans) AS SumOfScans,
		sum(ti.User_Lookups) AS SumOfLookups,
		sum(ti.RowCounts) AS SumOfRows,
		Count(ti.IndexName) AS CountOfIndexes
	FROM Tbl_Indexes ti
	GROUP BY ti.TableName,ti.IndexName
)

SELECT 
	cte.TableName,
	cte.indexname,
	cte.SumOfSeeks,
	cte.SumOfScans,
	cte.SumOfLookups,
	CountOfIndexes,
	cte.SumOfRows
FROM cte
WHERE 
	cte.SumOfSeeks <= 10
AND cte.SumOfScans <= 10
AND cte.SumOfLookups <= 10
AND cte.IndexName NOT LIKE '%PK_%'
ORDER BY TableName,IndexName


/*
--SELECT * FROM Tbl_Indexes

SELECT 
	IndexName,
	Count(IndexName)
FROM Tbl_Indexes
--WHERE User_Seeks = 0
GROUP BY IndexName
ORDER BY IndexName

/*
SELECT * FROM Tbl_Indexes
WHERE IndexName = 'ATTRIBUTE_VALUE_TEXT_IDX1'

--DELETE FROM Tbl_Indexes
--WHERE IndexName = 'c1sysarticles'



*/

--SELECT * FROM sys.indexes
--where name = 'ATTRIBUTE_VALUE_TEXT_IDX1'





*/
