-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get states/provinces by country
-- =============================================
CREATE PROCEDURE [dbo].[StateOrProvince_GetByCountry]
    @CountryId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT
        Id,
        Name,
        CountryId
    FROM Inv.StateOrProvinces
    WHERE CountryId = @CountryId
    ORDER BY Name;
END