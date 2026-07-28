-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Insert new asset allocation
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_Insert')
    DROP PROCEDURE [dbo].[AssetAllocation_Insert]
GO

CREATE PROCEDURE [dbo].[AssetAllocation_Insert]
    @Remarks NVARCHAR(MAX) = NULL,
    @AllocatedDate DATETIME2,
    @UserId INT = NULL,
    @DepartmentId INT = NULL,
    @SubDepartmentId INT = NULL,
    @RoomId INT = NULL,
    @ItemId INT = NULL,
    @BranchId INT = NULL,
    @Quantity INT = 1,
    @InventoryItemId INT = NULL,
    @SysBatchNo NVARCHAR(MAX) = NULL,
    @BatchNo NVARCHAR(MAX) = NULL,
    @CreatedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewId INT;
    
    INSERT INTO Inv.AssetAllocations (
        Notes, AllocatedDate, UserId, DepartmentId, SubDepartmentId,
        RoomId, ItemId, BranchId, Quantity,
        IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @Remarks, @AllocatedDate, @UserId, @DepartmentId, @SubDepartmentId,
        @RoomId, @ItemId, @BranchId, @Quantity,
        @IsActive, @CreatedById, GETUTCDATE()
    );
    
    SET @NewId = SCOPE_IDENTITY();
    
    SELECT @NewId as Id;
END