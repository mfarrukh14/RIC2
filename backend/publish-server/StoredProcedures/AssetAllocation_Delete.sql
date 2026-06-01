-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Delete asset allocation (soft delete)
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'AssetAllocation_Delete')
    DROP PROCEDURE [dbo].[AssetAllocation_Delete]
GO

CREATE PROCEDURE [dbo].[AssetAllocation_Delete]
    @Id INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE dbo.AssetAllocations
    SET
        IsActive = 0,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETUTCDATE()
    WHERE Id = @Id;
    
    SELECT @@ROWCOUNT as AffectedRows;
END