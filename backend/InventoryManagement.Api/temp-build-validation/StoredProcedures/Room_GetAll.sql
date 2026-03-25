-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all rooms for dropdown/selection
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Room_GetAll')
    DROP PROCEDURE [dbo].[Room_GetAll]
GO

CREATE PROCEDURE [dbo].[Room_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        Id,
        Name,
        Description,
        Floor,
        Building,
        Capacity,
        IsActive
    FROM dbo.Rooms
    WHERE IsActive = 1
    ORDER BY Building, Floor, Name;
END