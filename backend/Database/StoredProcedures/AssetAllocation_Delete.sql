-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Delete asset allocation (soft delete)
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_Delete')
    DROP PROCEDURE [dbo].[AssetAllocation_Delete]
GO

CREATE PROCEDURE [dbo].[AssetAllocation_Delete]
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get the InventoryItemId before soft delete
    DECLARE @InventoryItemId INT;
    SELECT @InventoryItemId = InventoryItemId 
    FROM dbo.AssetAllocations 
    WHERE Id = @Id;
    
    UPDATE dbo.AssetAllocations
    SET
        IsActive = 0,
        IsDeleted = 1,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    -- Update inventory item status back to available
    IF @InventoryItemId IS NOT NULL
    BEGIN
        UPDATE dbo.InventoryItems 
        SET Status = 'Available', ModifiedOn = GETUTCDATE()
        WHERE Id = @InventoryItemId;
    END
    
    SELECT @@ROWCOUNT as AffectedRows;
END