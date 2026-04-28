-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all item types with related data
-- =============================================
CREATE PROCEDURE [dbo].[ItemType_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        it.Id,
        it.Name,
        it.Description,
        it.BranchId,
        it.IsActive,
        it.CreatedById,
        it.CreatedOn,
        it.ModifiedById,
        it.ModifiedOn,
        br.Name as BranchName
    FROM dbo.ItemTypes it
    LEFT JOIN dbo.Branches br ON it.BranchId = br.Id
    WHERE it.IsActive = 1
    ORDER BY it.Name;
END