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
    
    UPDATE dbo.AssetAllocations
    SET
        Notes = @Remarks,
        AllocatedDate = @AllocatedDate,
        UserId = @UserId,
        DepartmentId = @DepartmentId,
        SubDepartmentId = @SubDepartmentId,
        RoomId = @RoomId,
        ItemId = @ItemId,
        BranchId = @BranchId,
        Quantity = @Quantity,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END