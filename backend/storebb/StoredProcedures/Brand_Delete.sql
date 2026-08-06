-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Permanently delete a brand. If items still reference the brand,
-- the caller must pass @Force = 1 to unassign the brand from those items first;
-- otherwise the delete is skipped and the affected item count is reported back.
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Brand_Delete]
    @Id INT,
    @Force BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ItemCount INT;
    SELECT @ItemCount = COUNT(*) FROM Inv.Items WHERE BrandId = @Id;

    IF @ItemCount > 0 AND @Force = 0
    BEGIN
        SELECT 0 as AffectedRows, @ItemCount as ItemCount;
        RETURN;
    END

    IF @ItemCount > 0
    BEGIN
        UPDATE Inv.Items SET BrandId = NULL WHERE BrandId = @Id;
    END

    DELETE FROM Inv.Brands WHERE Id = @Id;

    SELECT @@ROWCOUNT as AffectedRows, @ItemCount as ItemCount;
END