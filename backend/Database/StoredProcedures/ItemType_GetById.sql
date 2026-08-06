-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get item type by ID with related data
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[ItemType_GetById]
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
        br.Name as BranchName
    FROM Inv.ItemTypes it
    LEFT JOIN Inv.Branches br ON it.BranchId = br.Id
    WHERE it.Id = @Id AND it.IsActive = 1;
END