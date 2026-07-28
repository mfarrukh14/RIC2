-- =============================================
-- Author: System Generated
-- Create date: 2025-10-03
-- Description: Get unique buildings from rooms
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Room_GetBuildings')
    DROP PROCEDURE [dbo].[Room_GetBuildings]
GO

CREATE PROCEDURE [dbo].[Room_GetBuildings]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Name AS Building
    FROM dbo.Building
    WHERE Status = 1
    ORDER BY Name;
END
GO

-- =============================================
-- Author: System Generated
-- Create date: 2025-10-03
-- Description: Get floors by building
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Room_GetFloorsByBuilding')
    DROP PROCEDURE [dbo].[Room_GetFloorsByBuilding]
GO

CREATE PROCEDURE [dbo].[Room_GetFloorsByBuilding]
    @Building NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT f.Name AS Floor
    FROM dbo.Floors f
    JOIN dbo.Building b ON f.BID = b.BID
    WHERE f.Status = 1
        AND (@Building IS NULL OR b.Name = @Building)
    ORDER BY f.Name;
END
GO