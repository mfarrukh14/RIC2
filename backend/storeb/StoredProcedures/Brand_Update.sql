-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Update existing brand
-- =============================================
CREATE PROCEDURE [dbo].[Brand_Update]
    @Id INT,
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @BranchId INT = NULL,
    @ModifiedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Inv.Brands
    SET
        Name = @Name,
        Description = @Description,
        BranchId = @BranchId,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END