-- =============================================
-- Author: System Generated
-- Create date: 2025-09-30
-- Description: Get all manufacturers with related data
-- =============================================
CREATE PROCEDURE [dbo].[Manufacturer_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        m.Id,
        m.Name,
        m.Description,
        m.Email,
        m.Address,
        m.CNo,
        m.NTN,
        m.STN,
        m.CPName1,
        m.CPEmail1,
        m.CPContactNumber1,
        m.CPName2,
        m.CPEmail2,
        m.CPContactNumber2,
        m.CountryId,
        c.Name as CountryName,
        m.StateOrProvinceId,
        sp.Name as StateOrProvinceName,
        m.CityId,
        ct.Name as CityName,
        m.BranchId,
        b.Name as BranchName,
        m.RegisteredOwner,
        m.IsActive,
        m.CreatedById,
        m.CreatedOn,
        m.ModifiedById,
        m.ModifiedOn
    FROM Inv.Manufacturers m
    LEFT JOIN Inv.Countries c ON m.CountryId = c.Id
    LEFT JOIN Inv.StateOrProvinces sp ON m.StateOrProvinceId = sp.Id
    LEFT JOIN Inv.Cities ct ON m.CityId = ct.Id
    LEFT JOIN Inv.Branches b ON m.BranchId = b.Id
    ORDER BY m.Name;
END