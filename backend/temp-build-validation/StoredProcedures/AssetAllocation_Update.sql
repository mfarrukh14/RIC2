-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Update existing asset allocation
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_Update')
    DROP PROCEDURE [dbo].[AssetAllocation_Update]
GO

CREATE PROCEDURE [dbo].[AssetAllocation_Update]
    @Id INT,
    @Remarks NVARCHAR(MAX) = NULL,
    @AllocatedDate DATETIME2,
    @ReturnDate DATETIME2 = NULL,
    @UserId INT = NULL,
    @DepartmentId INT = NULL,
    @SubDepartmentId INT = NULL,
    @RoomId INT = NULL,
    @ItemId INT = NULL,
    @BranchId INT = NULL,
    @IsReturn BIT = 0,
    @ReturnRemarks NVARCHAR(MAX) = NULL,
    @Quantity INT = 1,
    @InventoryItemId INT = NULL,
    @SysBatchNo NVARCHAR(MAX) = NULL,
    @BatchNo NVARCHAR(MAX) = NULL,
    @ModifiedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get the current InventoryItemId before update
    DECLARE @CurrentInventoryItemId INT;
    SELECT @CurrentInventoryItemId = InventoryItemId 
    FROM dbo.AssetAllocations 
    WHERE Id = @Id;
    
    UPDATE dbo.AssetAllocations
    SET
        Remarks = @Remarks,
        AllocatedDate = @AllocatedDate,
        ReturnDate = @ReturnDate,
        UserId = @UserId,
        DepartmentId = @DepartmentId,
        SubDepartmentId = @SubDepartmentId,
        RoomId = @RoomId,
        ItemId = @ItemId,
        BranchId = @BranchId,
        IsReturn = @IsReturn,
        ReturnRemarks = @ReturnRemarks,
        Quantity = @Quantity,
        InventoryItemId = @InventoryItemId,
        SysBatchNo = @SysBatchNo,
        BatchNo = @BatchNo,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    -- Update inventory item status based on return status
    IF @InventoryItemId IS NOT NULL
    BEGIN
        IF @IsReturn = 1
        BEGIN
            -- Item is being returned
            UPDATE dbo.InventoryItems 
            SET Status = 'Available', ModifiedOn = GETUTCDATE()
            WHERE Id = @InventoryItemId;
        END
        ELSE
        BEGIN
            -- Item is still allocated
            UPDATE dbo.InventoryItems 
            SET Status = 'Allocated', ModifiedOn = GETUTCDATE()
            WHERE Id = @InventoryItemId;
        END
    END
    
    -- If the inventory item changed, update the previous item status
    IF @CurrentInventoryItemId IS NOT NULL AND @CurrentInventoryItemId != @InventoryItemId
    BEGIN
        UPDATE dbo.InventoryItems 
        SET Status = 'Available', ModifiedOn = GETUTCDATE()
        WHERE Id = @CurrentInventoryItemId;
    END
    
    SELECT @@ROWCOUNT as AffectedRows;
END