-- Sweep only Inv/Pharmacy schema tables (skip clinical/HMS-unrelated ones like
-- dbo.Specialities, dbo.SpecimenTestMethods already flagged as irrelevant), and
-- skip the tables already confirmed fully corrected in the previous sweep pass.
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql +
    'IF EXISTS (SELECT 1 FROM ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' WHERE BranchId = 1) ' +
    'SELECT ''' + s.name + '.' + t.name + ''' AS TableName, COUNT(*) AS RemainingBranch1Rows FROM ' +
    QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + ' WHERE BranchId = 1;' + CHAR(10)
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.columns c ON c.object_id = t.object_id AND c.name = 'BranchId'
WHERE s.name IN ('Inv','Pharmacy','Data')
  AND t.name NOT IN (
    'Vendors','Racks','RackRows','RackColumns','RackDrawrs','SurgicalGroups',
    'AssetAllocations','ItemTypes','ItemUnits','Packings','DemandRequests',
    'StockConsumptions','Inventories','Stocks','StockAdjustments',
    'TransferInventory','PurchaseRequisitions','PharmacyStores'
  );

EXEC sp_executesql @sql;
