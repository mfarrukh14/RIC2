-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Delete brand (soft delete)
-- =============================================
CREATE PROCEDURE [dbo].[Brand_Delete]
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.Brands
    SET
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END