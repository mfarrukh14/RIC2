-- Pharmacy.Manufacturers is the real table backing the Inv.Manufacturers /
-- Inv.PharmacyManufacturers read-only compatibility views, so it must be
-- targeted directly (ALTER TABLE against a view is invalid).
IF COL_LENGTH('Pharmacy.Manufacturers', 'NTN') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD NTN NVARCHAR(MAX) NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'STN') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD STN NVARCHAR(MAX) NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'CPName1') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD CPName1 NVARCHAR(MAX) NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'CPEmail1') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD CPEmail1 NVARCHAR(MAX) NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'CPContactNumber1') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD CPContactNumber1 NVARCHAR(MAX) NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'CPName2') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD CPName2 NVARCHAR(MAX) NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'CPEmail2') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD CPEmail2 NVARCHAR(MAX) NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'CPContactNumber2') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD CPContactNumber2 NVARCHAR(MAX) NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'CountryId') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD CountryId INT NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'StateOrProvinceId') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD StateOrProvinceId INT NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'CityId') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD CityId INT NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'BranchId') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD BranchId INT NULL;
END
GO

IF COL_LENGTH('Pharmacy.Manufacturers', 'RegisteredOwner') IS NULL
BEGIN
    ALTER TABLE Pharmacy.Manufacturers
    ADD RegisteredOwner NVARCHAR(MAX) NULL;
END
GO
