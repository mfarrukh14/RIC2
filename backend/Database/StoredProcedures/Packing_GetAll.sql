-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all packings with related data
-- =============================================
CREATE PROCEDURE [dbo].[Packing_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.Id,
        p.Name,
        p.Description,
        p.Pack,
        p.Leaf,
        p.NumberOfItems,
        p.BranchId,
        p.IsActive,
        p.CreatedById,
        p.CreatedOn,
        p.ModifiedById,
        p.ModifiedOn,
        br.Name as BranchName
    FROM dbo.Packings p
    LEFT JOIN dbo.Branches br ON p.BranchId = br.Id
    WHERE p.IsActive = 1
    ORDER BY p.Name;
END