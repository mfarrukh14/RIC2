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
        r.Id,
        r.Name,
        r.Description,
        flr.Name AS Floor,
        bld.Name AS Building,
        r.Capacity,
        r.IsActive
    FROM Inv.Rooms r
    LEFT JOIN dbo.Rooms dr ON r.Id = dr.RID
    LEFT JOIN dbo.Building bld ON dr.BID = bld.BID
    LEFT JOIN dbo.Floors flr ON dr.FID = flr.FID
    WHERE r.IsActive = 1
    ORDER BY bld.Name, flr.Name, r.Name;
END