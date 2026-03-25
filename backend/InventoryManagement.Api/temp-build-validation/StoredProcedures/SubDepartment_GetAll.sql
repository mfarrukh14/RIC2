-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all sub-departments for dropdown/selection
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SubDepartment_GetAll')
    DROP PROCEDURE [dbo].[SubDepartment_GetAll]
GO

CREATE PROCEDURE [dbo].[SubDepartment_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sd.Id,
        sd.Name,
        sd.Description,
        sd.DepartmentId,
        d.Name as DepartmentName,
        sd.IsActive
    FROM dbo.SubDepartments sd
    LEFT JOIN dbo.Departments d ON sd.DepartmentId = d.Id
    WHERE sd.IsActive = 1
    ORDER BY d.Name, sd.Name;
END