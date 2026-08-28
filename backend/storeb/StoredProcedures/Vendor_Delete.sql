-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Permanently delete a vendor
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Vendor_Delete]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Inv.Vendors
    WHERE Id = @Id;

    SELECT @@ROWCOUNT as RowsAffected;
END