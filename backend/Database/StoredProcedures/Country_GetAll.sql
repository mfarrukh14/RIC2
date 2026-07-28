-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all countries for dropdowns
-- =============================================
CREATE PROCEDURE [dbo].[Country_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT
        Id,
        Name
    FROM Inv.Countries
    WHERE IsActive = 1
    ORDER BY Name;
END