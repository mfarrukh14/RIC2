-- =============================================
-- Fix: Store creation/update fails with
-- "Update or insert of view or function 'Inv.PharmacyStores' failed
--  because it contains a derived or constant field" (SQL error 4406)
--
-- Root cause: dbo.Store_Insert / dbo.Store_Update write to Inv.PharmacyStores,
-- a compatibility view over Pharmacy.PharmacyStores. Several columns exposed
-- by that view (StoreCode, StoreType, ReceiptType, POSType, BuildingId,
-- FloorId, QueuePatientCallStatusValue, PricingType, DayClosing, Country,
-- StateOrProvince, City) were CAST()/constant expressions rather than direct
-- column references, which SQL Server refuses to INSERT/UPDATE through a view.
--
-- Fix: add dedicated backing columns on Pharmacy.PharmacyStores for the
-- values the Store Management UI actually sends (plain text, since the UI
-- doesn't use the legacy StoreTypeId/CountryId/... lookup FKs - and
-- Data.StoreTypes has no rows to map against anyway), then redefine the view
-- so every exposed column is a direct passthrough, making it insertable.
--
-- Required-ness (NOT NULL) mirrors which fields the Store Management form
-- marks as required: Store Name, Store Type, POS Type, Day Closing, Pricing
-- Type. Parent Store/Building/Floor/Room stay nullable since a top-level
-- store cannot always have those.
-- =============================================

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'StoreCode')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD StoreCode NVARCHAR(50) NULL;
    PRINT 'Added Pharmacy.PharmacyStores.StoreCode';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'BuildingId')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD BuildingId INT NULL;
    PRINT 'Added Pharmacy.PharmacyStores.BuildingId';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'FloorId')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD FloorId INT NULL;
    PRINT 'Added Pharmacy.PharmacyStores.FloorId';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'StoreTypeName')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD StoreTypeName NVARCHAR(50) NOT NULL CONSTRAINT DF_PharmacyStores_StoreTypeName DEFAULT ('General Store');
    PRINT 'Added Pharmacy.PharmacyStores.StoreTypeName';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'ReceiptTypeName')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD ReceiptTypeName NVARCHAR(50) NULL;
    PRINT 'Added Pharmacy.PharmacyStores.ReceiptTypeName';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'POSTypeName')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD POSTypeName NVARCHAR(50) NOT NULL CONSTRAINT DF_PharmacyStores_POSTypeName DEFAULT ('Inventory');
    PRINT 'Added Pharmacy.PharmacyStores.POSTypeName';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'PricingTypeName')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD PricingTypeName NVARCHAR(50) NOT NULL CONSTRAINT DF_PharmacyStores_PricingTypeName DEFAULT ('Branch Wise');
    PRINT 'Added Pharmacy.PharmacyStores.PricingTypeName';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'QueuePatientCallStatusValueName')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD QueuePatientCallStatusValueName NVARCHAR(100) NULL;
    PRINT 'Added Pharmacy.PharmacyStores.QueuePatientCallStatusValueName';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'DayClosingName')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD DayClosingName NVARCHAR(50) NOT NULL CONSTRAINT DF_PharmacyStores_DayClosingName DEFAULT ('Store Wise');
    PRINT 'Added Pharmacy.PharmacyStores.DayClosingName';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'CountryName')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD CountryName NVARCHAR(100) NULL;
    PRINT 'Added Pharmacy.PharmacyStores.CountryName';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'StateOrProvinceName')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD StateOrProvinceName NVARCHAR(100) NULL;
    PRINT 'Added Pharmacy.PharmacyStores.StateOrProvinceName';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Pharmacy.PharmacyStores') AND name = 'CityName')
BEGIN
    ALTER TABLE Pharmacy.PharmacyStores ADD CityName NVARCHAR(100) NULL;
    PRINT 'Added Pharmacy.PharmacyStores.CityName';
END
GO

-- Redefine the view so every exposed column is a direct 1:1 column reference
-- (no CAST/constant expressions), which makes it insertable/updatable.
CREATE OR ALTER VIEW Inv.PharmacyStores AS
SELECT
    [Id] AS StoreId,
    [Name] AS StoreName,
    [StoreCode] AS StoreCode,
    [Description] AS Description,
    [StoreTypeName] AS StoreType,
    [ReceiptTypeName] AS ReceiptType,
    [POSTypeName] AS POSType,
    [ParentId] AS ParentStoreId,
    [BuildingId] AS BuildingId,
    [FloorId] AS FloorId,
    [RoomId] AS RoomId,
    [Email] AS Email,
    [CellNumber] AS CellNumber,
    [QueuePatientCallStatusValueName] AS QueuePatientCallStatusValue,
    [IsMarkTokenAsAutoCollectedOnDispense] AS MarkTokenAsAutoCollectedOnDispense,
    [IsDisplayRequestsWithoutTokenIssuedInUserPharmacyQueue] AS DisplayRequestsWithoutTokenIssued,
    [EnglishNote] AS EnglishNote,
    [UrduNote] AS UrduNote,
    [IsPercentageServiceCharges] AS ServiceCharges,
    [IsPercentageGST] AS GST,
    [PricingTypeName] AS PricingType,
    [IsDisableRetailSale] AS DisableRetailSale,
    [GSTN] AS GSTN,
    [NTN] AS NTN,
    [DayClosingName] AS DayClosing,
    [DayClosingCashAccountId] AS ClosingCashAccountId,
    [DayClosingRevenueAccountId] AS ClosingRevenueAccountId,
    [DayClosingInventoryAccountId] AS ClosingInventoryAccountId,
    [DayClosingInventoryExpenseAccountId] AS ClosingInventoryExpenseAccountId,
    [DayClosingTaxExpenseAccountId] AS ClosingTaxExpenseAccountId,
    [PayableAccountId] AS PayableAccountId,
    [AdvanceTaxPercentageAccountId] AS AdvanceTaxPercentageAccountId,
    [RevenueDiscountAccountId] AS RevenueDiscountAccountId,
    [Address] AS Address,
    [Latitude] AS Latitude,
    [Longitude] AS Longitude,
    [CountryName] AS Country,
    [StateOrProvinceName] AS StateOrProvince,
    [CityName] AS City,
    [ImagePath] AS StoreImage,
    [BranchId] AS BranchId,
    [IsActive] AS IsActive,
    [CreatedById] AS CreatedById,
    [CreatedOn] AS CreatedOn,
    [ModifiedById] AS ModifiedById,
    [ModifiedOn] AS ModifiedOn
FROM Pharmacy.PharmacyStores;
GO

PRINT 'Inv.PharmacyStores is now fully insertable/updatable';
GO
