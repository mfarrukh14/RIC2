-- Adds the "Partial Issued" demand request status used when a dispatch issues
-- less than the full approved quantity, leaving the remainder dispatchable later.
IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestStatuses WHERE Name = 'Partial Issued')
    INSERT INTO Inv.DemandRequestStatuses (Name, BranchId, IsActive, Value, CreatedOn, ModifiedOn)
    SELECT 'Partial Issued', 1, 1, ISNULL(MAX(Value), 0) + 1, GETDATE(), GETDATE()
    FROM Inv.DemandRequestStatuses;
GO

PRINT 'Partial Issued demand request status verified.';
GO
