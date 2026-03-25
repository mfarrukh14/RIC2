-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all item units with related data
-- =============================================
CREATE PROCEDURE [dbo].[ItemUnit_GetAll]
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
        br.Name as BranchName
    FROM dbo.ItemUnits iu
    LEFT JOIN dbo.Branches br ON iu.BranchId = br.Id
    WHERE iu.IsActive = 1
    ORDER BY iu.Name;
END