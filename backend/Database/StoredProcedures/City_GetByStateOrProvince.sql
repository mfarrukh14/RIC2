-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get cities by state/province
-- =============================================
CREATE PROCEDURE [dbo].[City_GetByStateOrProvince]
    @StateOrProvinceId INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT
        Id,
        Name,
        StateOrProvinceId
    FROM Inv.Cities
    WHERE StateOrProvinceId = @StateOrProvinceId
    ORDER BY Name;
END