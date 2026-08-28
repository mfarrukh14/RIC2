DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql +
    'IF EXISTS (SELECT 1 FROM ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' WHERE BranchId = 1) ' +
    'SELECT ''' + s.name + '.' + t.name + ''' AS TableName, COUNT(*) AS RemainingBranch1Rows FROM ' +
    QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' WHERE BranchId = 1;' + CHAR(10)
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON c.object_id = t.object_id AND c.name = 'BranchId'
WHERE s.name IN ('Inv','Pharmacy','Data');

EXEC sp_executesql @sql;
PRINT 'Sweep complete.';
