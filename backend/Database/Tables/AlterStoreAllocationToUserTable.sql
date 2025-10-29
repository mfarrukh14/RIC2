-- =============================================
-- Alter StoreAllocationToUser Table - Change EmployeeId to EmployeeName
-- =============================================

-- Check if EmployeeId column exists and EmployeeName doesn't
IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.StoreAllocationToUser') AND name = 'EmployeeId')
AND NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.StoreAllocationToUser') AND name = 'EmployeeName')
BEGIN
    -- Drop the old EmployeeId column
    ALTER TABLE dbo.StoreAllocationToUser
    DROP COLUMN EmployeeId;
    
    -- Add the new EmployeeName column
    ALTER TABLE dbo.StoreAllocationToUser
    ADD EmployeeName NVARCHAR(255) NOT NULL DEFAULT '';
    
    PRINT 'StoreAllocationToUser table altered successfully - EmployeeId replaced with EmployeeName';
END
ELSE
BEGIN
    PRINT 'StoreAllocationToUser table already has correct schema';
END
GO
