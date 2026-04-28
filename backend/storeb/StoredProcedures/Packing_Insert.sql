-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Insert new packing
-- =============================================
CREATE PROCEDURE [dbo].[Packing_Insert]
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @BranchId INT = NULL,
    @CreatedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @NewId INT;
    
    INSERT INTO dbo.Packings (
        Name, Description, BranchId,
        IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @Name, @Description, @BranchId,
        @IsActive, @CreatedById, GETUTCDATE()
    );
    
    SET @NewId = SCOPE_IDENTITY();
    
    SELECT @NewId as Id;
END