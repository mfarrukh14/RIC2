-- =============================================
-- Author: System Generated
-- Create date: 2025-10-03
-- Description: Permanently delete an item
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Item_Delete]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Inv.Items
    WHERE Id = @Id;

    SELECT @@ROWCOUNT as AffectedRows;
END
GO