-- =============================================
-- Insert test asset allocations
-- =============================================
USE InventoryManagementDB_SP;
GO

-- Insert test asset allocations
INSERT INTO dbo.AssetAllocations (
    Remarks, AllocatedDate, UserId, RoomId, InventoryItemId, 
    Quantity, BranchId, IsActive, CreatedById, CreatedOn, IsReturn, IsDeleted
)
VALUES 
-- Room allocations
('Allocated for conference room use', '2025-09-15', NULL, 1, 1, 1, 1, 1, 1, GETUTCDATE(), 0, 0),
('Office equipment allocation', '2025-09-20', NULL, 4, 2, 1, 1, 1, 1, GETUTCDATE(), 0, 0),
('Training room projector', '2025-09-25', NULL, 3, 5, 1, 1, 1, 1, GETUTCDATE(), 0, 0),
('Meeting room furniture', '2025-09-28', NULL, 2, 3, 2, 1, 1, 1, GETUTCDATE(), 0, 0),

-- User allocations
('Personal workstation', '2025-09-10', 1, NULL, 4, 1, 1, 1, 1, GETUTCDATE(), 0, 0),
('IT department laptop', '2025-09-12', 2, NULL, 1, 1, 1, 1, 1, GETUTCDATE(), 0, 0),
('Office manager equipment', '2025-09-18', 3, NULL, 2, 1, 1, 1, 1, GETUTCDATE(), 0, 0);

PRINT 'Test asset allocations inserted successfully!';
GO

-- Verify the data
SELECT 
    aa.Id,
    aa.AllocatedDate,
    u.Name as UserName,
    r.Name as RoomName,
    r.Building,
    r.Floor,
    ii.Name as AssetName,
    aa.Quantity
FROM dbo.AssetAllocations aa
LEFT JOIN dbo.Users u ON aa.UserId = u.Id
LEFT JOIN Inv.Rooms r ON aa.RoomId = r.Id
LEFT JOIN dbo.InventoryItems ii ON aa.InventoryItemId = ii.Id
WHERE aa.IsActive = 1 AND aa.IsDeleted = 0
ORDER BY aa.AllocatedDate DESC;
GO