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
    
    SELECT 
        Id,
        Name,
        Description,
        Head,
        IsActive
    FROM dbo.Departments
    WHERE IsActive = 1
    ORDER BY Name;
END