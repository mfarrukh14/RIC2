-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get packing by ID with related data
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Packing_GetById]
    @Id INT
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
    WHERE p.Id = @Id;
END
