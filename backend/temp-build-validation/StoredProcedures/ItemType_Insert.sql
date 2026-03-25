-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Insert new item type
-- =============================================
CREATE PROCEDURE [dbo].[ItemType_Insert]
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @Value INT = NULL,
    @BranchId INT = NULL,
    @CreatedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewId INT;
    
    INSERT INTO dbo.ItemTypes (
        Name, Description, Value, BranchId,
        IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @Name, @Description, @Value, @BranchId,
        @IsActive, @CreatedById, GETUTCDATE()
    );
    
    SET @NewId = SCOPE_IDENTITY();
    
    SELECT @NewId as Id;
END