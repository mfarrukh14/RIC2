-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Update existing packing
-- =============================================
CREATE PROCEDURE [dbo].[Packing_Update]
    @Id INT,
    @Name NVARCHAR(MAX),
    @Description NVARCHAR(MAX) = NULL,
    @Pack INT = NULL,
    @Leaf INT = NULL,
    @NumberOfItems INT = NULL,
    @BranchId INT = NULL,
    @ModifiedById INT,
    @IsActive BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.Packings
    SET
        Name = @Name,
        Description = @Description,
        Pack = @Pack,
        Leaf = @Leaf,
        NumberOfItems = @NumberOfItems,
        BranchId = @BranchId,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END