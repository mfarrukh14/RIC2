-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Permanently delete a packing
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Packing_Delete]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Inv.Packings
    WHERE Id = @Id;

    SELECT @@ROWCOUNT as AffectedRows;
END