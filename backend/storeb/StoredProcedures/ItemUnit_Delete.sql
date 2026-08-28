-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Permanently delete an item unit
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[ItemUnit_Delete]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Inv.ItemUnits
    WHERE Id = @Id;

    SELECT @@ROWCOUNT as AffectedRows;
END