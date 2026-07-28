-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all departments for dropdown/selection
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Department_GetAll')
    DROP PROCEDURE [dbo].[Department_GetAll]
GO

CREATE PROCEDURE [dbo].[Department_GetAll]
AS
BEGIN
    SET NOCOUNT ON;

    -- Inv.Departments has many duplicate Name rows (same department seeded
    -- multiple times). This is a dropdown/lookup source only (no admin CRUD
    -- screen depends on seeing every duplicate), so collapse to one row per
    -- distinct Name, keeping the lowest Id as the representative.
    ;WITH DedupedDepartments AS (
        SELECT
            Id, Name, Description, Head, IsActive,
            ROW_NUMBER() OVER (PARTITION BY Name ORDER BY Id) AS rn
        FROM Inv.Departments
        WHERE IsActive = 1
    )
    SELECT Id, Name, Description, Head, IsActive
    FROM DedupedDepartments
    WHERE rn = 1
    ORDER BY Name;
END