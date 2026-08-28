-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get brand by ID with related data
-- =============================================
CREATE PROCEDURE [dbo].[Brand_GetById]
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
        br.BranchName as BranchName
    FROM Inv.Brands b
    LEFT JOIN dbo.Branch br ON b.BranchId = br.BranchId
    WHERE b.Id = @Id AND b.IsActive = 1;
END