-- Inv.PharmacyManufacturers is a compatibility view over the real table,
-- Pharmacy.Manufacturers. It was originally written before Pharmacy.Manufacturers
-- had NTN/STN/CPName1/CPEmail1/CPContactNumber1/CPName2/CPEmail2/CPContactNumber2/
-- CountryId/StateOrProvinceId/CityId/BranchId/RegisteredOwner, so those columns
-- were hardcoded to NULL here. AlterPharmacyManufacturersTable.sql later added all
-- of them to the real table, but this view was never updated to select them -
-- meaning every manufacturer read through Inv.Manufacturers (which selects * from
-- this view) silently lost its real BranchId (and NTN/STN/contact/location data).
CREATE OR ALTER VIEW Inv.PharmacyManufacturers AS
SELECT
    [ManufacturerId] AS Id,
    [Name] AS Name,
    [Description] AS Description,
    [Email] AS Email,
    [Address] AS Address,
    [MobileNo] AS CNo,
    [NTN] AS NTN,
    [STN] AS STN,
    [CPName1] AS CPName1,
    [CPEmail1] AS CPEmail1,
    [CPContactNumber1] AS CPContactNumber1,
    [CPName2] AS CPName2,
    [CPEmail2] AS CPEmail2,
    [CPContactNumber2] AS CPContactNumber2,
    [CountryId] AS CountryId,
    [StateOrProvinceId] AS StateOrProvinceId,
    [CityId] AS CityId,
    [BranchId] AS BranchId,
    CAST(ISNULL([IsActive], 1) AS BIT) AS IsActive,
    [CreatedById] AS CreatedById,
    [CreatedOn] AS CreatedOn,
    [ModifiedById] AS ModifiedById,
    [ModifiedOn] AS ModifiedOn,
    [RegisteredOwner] AS RegisteredOwner
FROM Pharmacy.Manufacturers;
