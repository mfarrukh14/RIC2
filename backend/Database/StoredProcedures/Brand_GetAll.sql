-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all brands with related data
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Brand_GetAll]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        b.Id,
        b.Name,
        b.Description,
        b.BranchId,
        b.IsActive,
        b.CreatedById,
        b.CreatedOn,
        b.ModifiedById,
        b.ModifiedOn,
        br.Name as BranchName
    FROM Inv.Brands b
    LEFT JOIN Inv.Branches br ON b.BranchId = br.Id
    ORDER BY b.Name;
END