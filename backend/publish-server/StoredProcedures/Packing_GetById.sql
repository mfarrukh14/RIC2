-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get packing by ID with related data
-- =============================================
CREATE PROCEDURE [dbo].[Packing_GetById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        p.Id,
        p.Name,
        p.Description,
        p.BranchId,
        p.IsActive,
        p.CreatedById,
        p.CreatedOn,
        p.ModifiedById,
        p.ModifiedOn,
        br.Name as BranchName
    FROM dbo.Packings p
    LEFT JOIN dbo.Branches br ON p.BranchId = br.Id
    WHERE p.Id = @Id AND p.IsActive = 1;
END