-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get item unit by ID with related data
-- =============================================
CREATE PROCEDURE [dbo].[ItemUnit_GetById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        iu.Id,
        iu.Name,
        iu.Description,
        iu.BranchId,
        iu.IsActive,
        iu.CreatedById,
        iu.CreatedOn,
        iu.ModifiedById,
        iu.ModifiedOn,
        br.BranchName as BranchName
    FROM Inv.ItemUnits iu
    LEFT JOIN dbo.Branch br ON iu.BranchId = br.BranchId
    WHERE iu.Id = @Id AND iu.IsActive = 1;
END