-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Delete vendor (soft delete by setting IsActive = 0)
-- =============================================
CREATE PROCEDURE [dbo].[Vendor_Delete]
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.Vendors 
    SET 
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as RowsAffected;
END