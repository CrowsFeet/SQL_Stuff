-- lists all the columns and their datatypes for a specific table
SELECT DISTINCT
    c.name AS 'Column Name',
    t.Name AS 'Data type',
    c.max_length AS 'Max Length',
    c.precision ,
    c.scale ,
    c.is_nullable,
    ISNULL(i.is_primary_key, 0) AS 'Primary Key'
FROM    
    sys.columns c
INNER JOIN 
    sys.types t ON c.user_type_id = t.user_type_id
LEFT OUTER JOIN 
    sys.index_columns ic ON ic.object_id = c.object_id AND ic.column_id = c.column_id
LEFT OUTER JOIN 
    sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
WHERE
c.object_id = OBJECT_ID('<Add Table Name Here>')
ORDER BY ISNULL(i.is_primary_key, 0) desc,c.name
