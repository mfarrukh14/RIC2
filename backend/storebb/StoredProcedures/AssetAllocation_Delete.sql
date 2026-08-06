-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Permanently delete an asset allocation
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[AssetAllocation_Delete]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Inv.AssetAllocations
    WHERE Id = @Id;

    SELECT @@ROWCOUNT as AffectedRows;
END