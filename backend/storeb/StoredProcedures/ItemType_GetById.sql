-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get item type by ID with related data
-- =============================================
CREATE PROCEDURE [dbo].[ItemType_GetById]
    @Id INT
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
        br.BranchName as BranchName
    FROM Inv.ItemTypes it
    LEFT JOIN dbo.Branch br ON it.BranchId = br.BranchId
    WHERE it.Id = @Id AND it.IsActive = 1;
END