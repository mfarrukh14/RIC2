-- =============================================
-- Author: System Generated
-- Create date: 2025-10-03
-- Description: Delete item (soft delete)
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Item_Delete')
    DROP PROCEDURE [dbo].[Item_Delete]
GO

CREATE PROCEDURE [dbo].[Item_Delete]
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.Items
    SET
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END
GO