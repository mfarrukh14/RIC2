-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all packings with related data
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Packing_GetAll]
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
    FROM Inv.Packings p
    LEFT JOIN Inv.Branches br ON p.BranchId = br.Id
    ORDER BY p.Name;
END
