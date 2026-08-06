-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get brand by ID with related data
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Brand_GetById]
    @Id INT
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
    FROM Inv.DataBrands b
    LEFT JOIN Inv.Branches br ON b.BranchId = br.Id
    WHERE b.Id = @Id AND b.IsActive = 1;
END