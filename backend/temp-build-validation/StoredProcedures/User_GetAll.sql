-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all users for dropdown/selection
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'User_GetAll')
    DROP PROCEDURE [dbo].[User_GetAll]
GO

CREATE PROCEDURE [dbo].[User_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Id,
        Name,
        Email,
        UserName,
        Department,
        Designation,
        IsActive
    FROM dbo.Users
    WHERE IsActive = 1
    ORDER BY Name;
END