-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Permanently delete a manufacturer
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Manufacturer_Delete]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Pharmacy.Manufacturers
    WHERE ManufacturerId = @Id;

    SELECT @@ROWCOUNT as AffectedRows;
END
