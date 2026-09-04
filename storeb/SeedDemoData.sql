-- =============================================
-- SeedDemoData.sql
-- Idempotent demo/test data for every sidebar section of the Inventory
-- Management app, targeted at a freshly-cloned shared database (HMS_Jun26)
-- that has the app's schema (Inv/Pharmacy adapters from HMS_Setup.sql) but
-- no operational data yet.
--
-- Safe to re-run: every INSERT is guarded by an IF NOT EXISTS check.
-- Run HMS/HMS_Setup.sql BEFORE this script (it creates Inv.Prices,
-- Inv.TaxTypes, the PharmacyStores/Manufacturers adapter views, etc.).
-- =============================================
SET NOCOUNT ON;

DECLARE @BranchId INT = COALESCE((SELECT TOP 1 Id FROM Inv.Branches WHERE IsActive = 1 ORDER BY Id), 1);
DECLARE @CreatedById INT = COALESCE((SELECT TOP 1 UserID FROM dbo.Users ORDER BY UserID), 1);
DECLARE @DepartmentId INT = (SELECT TOP 1 Id FROM Inv.Departments ORDER BY Id);
DECLARE @SubDepartmentId INT = (SELECT TOP 1 Id FROM Inv.SubDepartments WHERE DepartmentId = @DepartmentId ORDER BY Id);
DECLARE @RoomId INT = (SELECT TOP 1 Id FROM Inv.Rooms ORDER BY Id);
DECLARE @CountryId INT = (SELECT TOP 1 Id FROM Inv.Countries ORDER BY Id);
DECLARE @StateOrProvinceId INT = (SELECT TOP 1 Id FROM Inv.StateOrProvinces ORDER BY Id);
DECLARE @CityId INT = (SELECT TOP 1 Id FROM Inv.Cities ORDER BY Id);

-- =============================================
-- SECTION 0: Shared/legacy tables backing Inv.* adapter views
-- (Pharmacy.Manufacturers -> Inv.Manufacturers / Inv.PharmacyManufacturers,
--  Pharmacy.PharmacyStores -> Inv.PharmacyStores)
-- These are on HMS_Jun26 only (a demo/test clone), never touch live HMS.
-- =============================================

IF NOT EXISTS (SELECT 1 FROM Pharmacy.Manufacturers WHERE Name = 'Nisa SF Pvt Ltd')
BEGIN
    INSERT INTO Pharmacy.Manufacturers (Name, Email, MobileNo, Address, Description, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('Nisa SF Pvt Ltd', 'info@nisasf.com', '03915455461', '10-km Mundko Shahzadpur road, Pakistan', 'Leading medical equipment manufacturer', @CreatedById, GETDATE(), 0, 1);
END;

IF NOT EXISTS (SELECT 1 FROM Pharmacy.Manufacturers WHERE Name = 'Beijing Domax Medical')
BEGIN
    INSERT INTO Pharmacy.Manufacturers (Name, Email, MobileNo, Address, Description, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('Beijing Domax Medical', 'info@domaxmedical.com', '0086-10-56771179', 'Tongzhou District, Beijing', 'Advanced medical device manufacturer', @CreatedById, GETDATE(), 0, 1);
END;

IF NOT EXISTS (SELECT 1 FROM Pharmacy.Manufacturers WHERE Name = 'CardioMed Devices')
BEGIN
    INSERT INTO Pharmacy.Manufacturers (Name, Email, MobileNo, Address, Description, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('CardioMed Devices', 'contact@cardiomed.com', '03001234567', 'Industrial Estate, Karachi', 'Cardiology equipment manufacturer', @CreatedById, GETDATE(), 0, 1);
END;

IF NOT EXISTS (SELECT 1 FROM Pharmacy.Manufacturers WHERE Name = 'Vital Surgical Works')
BEGIN
    INSERT INTO Pharmacy.Manufacturers (Name, Email, MobileNo, Address, Description, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('Vital Surgical Works', 'sales@vitalsurgical.com', '03007654321', 'Sundar Industrial Estate, Lahore', 'Disposable and surgical goods manufacturer', @CreatedById, GETDATE(), 0, 1);
END;

IF NOT EXISTS (SELECT 1 FROM Pharmacy.PharmacyStores WHERE Name = 'Medicine Store')
BEGIN
    INSERT INTO Pharmacy.PharmacyStores (Name, Description, BranchId, OpeningTime, ClosingTime, IsActive, IsDeleted, CreatedById, CreatedOn)
    VALUES ('Medicine Store', 'Main medicine dispensing store', @BranchId, '08:00', '20:00', 1, 0, @CreatedById, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Pharmacy.PharmacyStores WHERE Name = 'Main Disposable Store')
BEGIN
    INSERT INTO Pharmacy.PharmacyStores (Name, Description, BranchId, OpeningTime, ClosingTime, IsActive, IsDeleted, CreatedById, CreatedOn)
    VALUES ('Main Disposable Store', 'Disposables and consumables store', @BranchId, '08:00', '20:00', 1, 0, @CreatedById, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Pharmacy.PharmacyStores WHERE Name = 'Emergency Store')
BEGIN
    INSERT INTO Pharmacy.PharmacyStores (Name, Description, BranchId, OpeningTime, ClosingTime, IsActive, IsDeleted, CreatedById, CreatedOn)
    VALUES ('Emergency Store', 'Emergency ward stock holding store', @BranchId, '00:00', '23:59', 1, 0, @CreatedById, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Pharmacy.PharmacyStores WHERE Name = 'Central Store')
BEGIN
    INSERT INTO Pharmacy.PharmacyStores (Name, Description, BranchId, OpeningTime, ClosingTime, IsActive, IsDeleted, CreatedById, CreatedOn)
    VALUES ('Central Store', 'Central receiving and distribution store', @BranchId, '08:00', '18:00', 1, 0, @CreatedById, GETDATE());
END;

-- Link a couple of existing users to pharmacy stores (Pharmacy.UserPharmacyStores)
DECLARE @SeedUser2Id INT = (SELECT TOP 1 UserID FROM dbo.Users WHERE UserID <> @CreatedById ORDER BY UserID);
DECLARE @MedStoreForUserId INT = (SELECT TOP 1 Id FROM Pharmacy.PharmacyStores WHERE Name = 'Medicine Store' ORDER BY Id);
IF @MedStoreForUserId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Pharmacy.UserPharmacyStores WHERE UserId = @CreatedById AND PharmacyStoreId = @MedStoreForUserId)
BEGIN
    INSERT INTO Pharmacy.UserPharmacyStores (UserId, PharmacyStoreId, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES (@CreatedById, @MedStoreForUserId, @CreatedById, GETDATE(), 0, 1);
END;
IF @SeedUser2Id IS NOT NULL AND @MedStoreForUserId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Pharmacy.UserPharmacyStores WHERE UserId = @SeedUser2Id AND PharmacyStoreId = @MedStoreForUserId)
BEGIN
    INSERT INTO Pharmacy.UserPharmacyStores (UserId, PharmacyStoreId, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES (@SeedUser2Id, @MedStoreForUserId, @CreatedById, GETDATE(), 0, 1);
END;

-- =============================================
-- SECTION 1: App-owned lookup tables (Inv schema)
-- =============================================

-- Categories / SubCategories
IF NOT EXISTS (SELECT 1 FROM Inv.Categories WHERE Name = 'Disposables')
    INSERT INTO Inv.Categories (Name, Description, IsActive) VALUES ('Disposables', 'Single-use disposable medical items', 1);
IF NOT EXISTS (SELECT 1 FROM Inv.Categories WHERE Name = 'Medicines')
    INSERT INTO Inv.Categories (Name, Description, IsActive) VALUES ('Medicines', 'Pharmaceutical products', 1);
IF NOT EXISTS (SELECT 1 FROM Inv.Categories WHERE Name = 'Surgical Instruments')
    INSERT INTO Inv.Categories (Name, Description, IsActive) VALUES ('Surgical Instruments', 'Reusable and disposable surgical instruments', 1);
IF NOT EXISTS (SELECT 1 FROM Inv.Categories WHERE Name = 'Laboratory Supplies')
    INSERT INTO Inv.Categories (Name, Description, IsActive) VALUES ('Laboratory Supplies', 'Lab consumables and reagents', 1);
IF NOT EXISTS (SELECT 1 FROM Inv.Categories WHERE Name = 'Diagnostic Equipment')
    INSERT INTO Inv.Categories (Name, Description, IsActive) VALUES ('Diagnostic Equipment', 'Diagnostic devices and accessories', 1);

DECLARE @CatDisposablesId INT = (SELECT TOP 1 Id FROM Inv.Categories WHERE Name = 'Disposables' ORDER BY Id);
DECLARE @CatMedicinesId INT = (SELECT TOP 1 Id FROM Inv.Categories WHERE Name = 'Medicines' ORDER BY Id);
DECLARE @CatLabId INT = (SELECT TOP 1 Id FROM Inv.Categories WHERE Name = 'Laboratory Supplies' ORDER BY Id);

-- Drop any sub-category rows left over from a previous run whose parent Category
-- row no longer exists (e.g. Categories got deleted/recreated with new IDs) so
-- orphans/duplicates can't accumulate across repeated runs.
DELETE sc FROM Inv.SubCategories sc
    LEFT JOIN Inv.Categories c ON c.Id = sc.CategoryId
    WHERE sc.Name IN ('Syringes', 'IV Cannulas', 'Vaccines', 'Lab Consumables')
      AND c.Id IS NULL;

-- De-dupe/repoint by Name alone: these four demo sub-categories are meant to be
-- singletons, so if one already exists under a stale CategoryId, retarget it
-- instead of inserting a duplicate.
IF EXISTS (SELECT 1 FROM Inv.SubCategories WHERE Name = 'Syringes')
    UPDATE Inv.SubCategories SET CategoryId = @CatDisposablesId WHERE Name = 'Syringes';
ELSE
    INSERT INTO Inv.SubCategories (Name, Description, CategoryId, IsActive) VALUES ('Syringes', 'Syringes of various sizes', @CatDisposablesId, 1);

IF EXISTS (SELECT 1 FROM Inv.SubCategories WHERE Name = 'IV Cannulas')
    UPDATE Inv.SubCategories SET CategoryId = @CatDisposablesId WHERE Name = 'IV Cannulas';
ELSE
    INSERT INTO Inv.SubCategories (Name, Description, CategoryId, IsActive) VALUES ('IV Cannulas', 'IV access devices', @CatDisposablesId, 1);

IF EXISTS (SELECT 1 FROM Inv.SubCategories WHERE Name = 'Vaccines')
    UPDATE Inv.SubCategories SET CategoryId = @CatMedicinesId WHERE Name = 'Vaccines';
ELSE
    INSERT INTO Inv.SubCategories (Name, Description, CategoryId, IsActive) VALUES ('Vaccines', 'Injectable vaccines', @CatMedicinesId, 1);

IF EXISTS (SELECT 1 FROM Inv.SubCategories WHERE Name = 'Lab Consumables')
    UPDATE Inv.SubCategories SET CategoryId = @CatLabId WHERE Name = 'Lab Consumables';
ELSE
    INSERT INTO Inv.SubCategories (Name, Description, CategoryId, IsActive) VALUES ('Lab Consumables', 'Test tubes, slides, reagents', @CatLabId, 1);

-- ItemUnits
IF NOT EXISTS (SELECT 1 FROM Inv.ItemUnits WHERE Name = 'Piece')
    INSERT INTO Inv.ItemUnits (Name, Symbol, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('Piece', 'pc', 'Individual piece', @BranchId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.ItemUnits WHERE Name = 'Box')
    INSERT INTO Inv.ItemUnits (Name, Symbol, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('Box', 'bx', 'Box of items', @BranchId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.ItemUnits WHERE Name = 'Vial')
    INSERT INTO Inv.ItemUnits (Name, Symbol, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('Vial', 'vl', 'Single vial', @BranchId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.ItemUnits WHERE Name = 'Pack')
    INSERT INTO Inv.ItemUnits (Name, Symbol, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('Pack', 'pk', 'Pack of items', @BranchId, 1, @CreatedById, GETDATE());

-- Packings
IF NOT EXISTS (SELECT 1 FROM Inv.Packings WHERE Name = 'Carton of 10')
    INSERT INTO Inv.Packings (Name, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('Carton of 10', 'Carton containing 10 packets', @BranchId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.Packings WHERE Name = 'Carton of 20')
    INSERT INTO Inv.Packings (Name, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('Carton of 20', 'Carton containing 20 packets', @BranchId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.Packings WHERE Name = 'Strip of 10')
    INSERT INTO Inv.Packings (Name, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('Strip of 10', 'Strip of 10 units', @BranchId, 1, @CreatedById, GETDATE());

-- ItemTypes
IF NOT EXISTS (SELECT 1 FROM Inv.ItemTypes WHERE Name = 'Disposable')
    INSERT INTO Inv.ItemTypes (Name, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('Disposable', 'Disposable/consumable items', @BranchId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.ItemTypes WHERE Name = 'Medicine')
    INSERT INTO Inv.ItemTypes (Name, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('Medicine', 'Pharmaceutical items', @BranchId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.ItemTypes WHERE Name = 'Equipment')
    INSERT INTO Inv.ItemTypes (Name, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('Equipment', 'Reusable equipment', @BranchId, 1, @CreatedById, GETDATE());

-- Vendors
IF NOT EXISTS (SELECT 1 FROM Inv.Vendors WHERE Name = 'MediSupply Traders')
    INSERT INTO Inv.Vendors (Name, Description, Email, CNo, Address, CountryId, StateOrProvinceId, CityId, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES ('MediSupply Traders', 'General medical supplies distributor', 'sales@medisupply.com', '03211234567', 'Blue Area, Islamabad', @CountryId, @StateOrProvinceId, @CityId, @BranchId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.Vendors WHERE Name = 'SterileCare Supplies')
    INSERT INTO Inv.Vendors (Name, Description, Email, CNo, Address, CountryId, StateOrProvinceId, CityId, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES ('SterileCare Supplies', 'Emergency procurement vendor', 'contact@sterilecare.com', '03219876543', 'G-9, Islamabad', @CountryId, @StateOrProvinceId, @CityId, @BranchId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.Vendors WHERE Name = 'National Pharma Distributors')
    INSERT INTO Inv.Vendors (Name, Description, Email, CNo, Address, CountryId, StateOrProvinceId, CityId, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES ('National Pharma Distributors', 'Vaccine and medicine distributor', 'info@natpharma.com', '03331112233', 'F-8 Markaz, Islamabad', @CountryId, @StateOrProvinceId, @CityId, @BranchId, 1, @CreatedById, GETDATE());

-- Brands (Data.Brands is this app's own table -- backs Items.BrandId FK)
IF NOT EXISTS (SELECT 1 FROM Data.Brands WHERE Name = 'MediLine')
    INSERT INTO Data.Brands (Name, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('MediLine', 'General medical disposables brand', @BranchId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Data.Brands WHERE Name = 'CardioCare')
    INSERT INTO Data.Brands (Name, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('CardioCare', 'Cardiology consumables brand', @BranchId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Data.Brands WHERE Name = 'LabPro')
    INSERT INTO Data.Brands (Name, Description, BranchId, IsActive, CreatedById, CreatedOn) VALUES ('LabPro', 'Laboratory supplies brand', @BranchId, 1, @CreatedById, GETDATE());

-- StockTypes
IF NOT EXISTS (SELECT 1 FROM Inv.StockTypes WHERE Name = 'Regular')
    INSERT INTO Inv.StockTypes (Name, Description, IsActive, IsDeleted, CreatedById, CreatedOn) VALUES ('Regular', 'Regular purchased stock', 1, 0, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.StockTypes WHERE Name = 'Donation')
    INSERT INTO Inv.StockTypes (Name, Description, IsActive, IsDeleted, CreatedById, CreatedOn) VALUES ('Donation', 'Donated stock', 1, 0, @CreatedById, GETDATE());

-- StockTypeAssociations (link stock types to pharmacy stores)
DECLARE @RegularStockTypeIdSetup INT = (SELECT TOP 1 Id FROM Inv.StockTypes WHERE Name = 'Regular' ORDER BY Id);
DECLARE @DonationStockTypeIdSetup INT = (SELECT TOP 1 Id FROM Inv.StockTypes WHERE Name = 'Donation' ORDER BY Id);
DECLARE @MedStoreForAssocId INT = (SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE StoreName = 'Medicine Store' ORDER BY StoreId);
DECLARE @EmergStoreForAssocId INT = (SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE StoreName = 'Emergency Store' ORDER BY StoreId);
IF @MedStoreForAssocId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Inv.StockTypeAssociations WHERE StoreId = @MedStoreForAssocId AND StockTypeId = @RegularStockTypeIdSetup)
    INSERT INTO Inv.StockTypeAssociations (StoreId, StockTypeId, IsActive, CreatedById, CreatedOn) VALUES (@MedStoreForAssocId, @RegularStockTypeIdSetup, 1, @CreatedById, GETDATE());
IF @EmergStoreForAssocId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Inv.StockTypeAssociations WHERE StoreId = @EmergStoreForAssocId AND StockTypeId = @DonationStockTypeIdSetup)
    INSERT INTO Inv.StockTypeAssociations (StoreId, StockTypeId, IsActive, CreatedById, CreatedOn) VALUES (@EmergStoreForAssocId, @DonationStockTypeIdSetup, 1, @CreatedById, GETDATE());

-- AccountCOAs
IF NOT EXISTS (SELECT 1 FROM Inv.AccountCOAs WHERE Name = 'Inventory Asset Account')
    INSERT INTO Inv.AccountCOAs (Name, Code, AccountType, IsActive) VALUES ('Inventory Asset Account', 'COA-1000', 'Asset', 1);
IF NOT EXISTS (SELECT 1 FROM Inv.AccountCOAs WHERE Name = 'Cost of Goods Sold')
    INSERT INTO Inv.AccountCOAs (Name, Code, AccountType, IsActive) VALUES ('Cost of Goods Sold', 'COA-5000', 'Expense', 1);
IF NOT EXISTS (SELECT 1 FROM Inv.AccountCOAs WHERE Name = 'Sales Revenue')
    INSERT INTO Inv.AccountCOAs (Name, Code, AccountType, IsActive) VALUES ('Sales Revenue', 'COA-4000', 'Revenue', 1);

-- TaxRates / TaxDescriptions / TaxPayerCategories / Prices / TaxTypes (Item lookup data)
IF NOT EXISTS (SELECT 1 FROM Inv.TaxRates WHERE Name = 'GST 17%')
    INSERT INTO Inv.TaxRates (Name, Rate, IsActive) VALUES ('GST 17%', 17.00, 1);
IF NOT EXISTS (SELECT 1 FROM Inv.TaxRates WHERE Name = 'GST 5%')
    INSERT INTO Inv.TaxRates (Name, Rate, IsActive) VALUES ('GST 5%', 5.00, 1);
IF NOT EXISTS (SELECT 1 FROM Inv.TaxRates WHERE Name = 'Exempt')
    INSERT INTO Inv.TaxRates (Name, Rate, IsActive) VALUES ('Exempt', 0.00, 1);

IF NOT EXISTS (SELECT 1 FROM Inv.TaxDescriptions WHERE Name = 'Standard GST')
    INSERT INTO Inv.TaxDescriptions (Name, Description, IsActive) VALUES ('Standard GST', 'Standard general sales tax', 1);
IF NOT EXISTS (SELECT 1 FROM Inv.TaxDescriptions WHERE Name = 'Reduced Rate')
    INSERT INTO Inv.TaxDescriptions (Name, Description, IsActive) VALUES ('Reduced Rate', 'Reduced tax rate for essential items', 1);
IF NOT EXISTS (SELECT 1 FROM Inv.TaxDescriptions WHERE Name = 'Tax Exempt')
    INSERT INTO Inv.TaxDescriptions (Name, Description, IsActive) VALUES ('Tax Exempt', 'No tax applicable', 1);

IF NOT EXISTS (SELECT 1 FROM Inv.TaxPayerCategories WHERE Name = 'Filer')
    INSERT INTO Inv.TaxPayerCategories (Name, Code, IsActive) VALUES ('Filer', 'FLR', 1);
IF NOT EXISTS (SELECT 1 FROM Inv.TaxPayerCategories WHERE Name = 'Non-Filer')
    INSERT INTO Inv.TaxPayerCategories (Name, Code, IsActive) VALUES ('Non-Filer', 'NFLR', 1);

IF NOT EXISTS (SELECT 1 FROM Inv.Prices WHERE RetailPrice = 10.00 AND SalePrice = 8.00)
    INSERT INTO Inv.Prices (RetailPrice, SalePrice, MarketPrice, IsActive) VALUES (10.00, 8.00, 9.00, 1);
IF NOT EXISTS (SELECT 1 FROM Inv.Prices WHERE RetailPrice = 35.00 AND SalePrice = 30.00)
    INSERT INTO Inv.Prices (RetailPrice, SalePrice, MarketPrice, IsActive) VALUES (35.00, 30.00, 32.00, 1);

IF NOT EXISTS (SELECT 1 FROM Inv.TaxTypes WHERE Name = 'Sales Tax')
    INSERT INTO Inv.TaxTypes (Name, Description, IsActive) VALUES ('Sales Tax', 'General sales tax', 1);
IF NOT EXISTS (SELECT 1 FROM Inv.TaxTypes WHERE Name = 'Withholding Tax')
    INSERT INTO Inv.TaxTypes (Name, Description, IsActive) VALUES ('Withholding Tax', 'Withholding tax on purchases', 1);

-- FinancialYears
IF NOT EXISTS (SELECT 1 FROM Inv.FinancialYears WHERE Name = 'FY 2025-2026')
    INSERT INTO Inv.FinancialYears (Name, StartDate, EndDate, IsActive, CreatedOn) VALUES ('FY 2025-2026', '2025-07-01', '2026-06-30', 1, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.FinancialYears WHERE Name = 'FY 2024-2025')
    INSERT INTO Inv.FinancialYears (Name, StartDate, EndDate, IsActive, CreatedOn) VALUES ('FY 2024-2025', '2024-07-01', '2025-06-30', 0, GETDATE());

-- DemandWiseValues (lookup; the live "Demand Wise Value" report is computed from
-- DemandRequests/Inventories seeded below, this table just backs its own dropdown if used)
IF NOT EXISTS (SELECT 1 FROM Inv.DemandWiseValues WHERE Name = 'High Priority')
    INSERT INTO Inv.DemandWiseValues (Name, Value, IsActive) VALUES ('High Priority', 3, 1);
IF NOT EXISTS (SELECT 1 FROM Inv.DemandWiseValues WHERE Name = 'Medium Priority')
    INSERT INTO Inv.DemandWiseValues (Name, Value, IsActive) VALUES ('Medium Priority', 2, 1);
IF NOT EXISTS (SELECT 1 FROM Inv.DemandWiseValues WHERE Name = 'Low Priority')
    INSERT INTO Inv.DemandWiseValues (Name, Value, IsActive) VALUES ('Low Priority', 1, 1);

-- EstimatedPurchaseOrders (simple lookup table; the live report is computed elsewhere)
IF NOT EXISTS (SELECT 1 FROM Inv.EstimatedPurchaseOrders WHERE Name = 'Monthly Estimate')
    INSERT INTO Inv.EstimatedPurchaseOrders (Name, Description, IsActive, CreatedOn) VALUES ('Monthly Estimate', 'Estimated monthly replenishment', 1, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.EstimatedPurchaseOrders WHERE Name = 'Quarterly Estimate')
    INSERT INTO Inv.EstimatedPurchaseOrders (Name, Description, IsActive, CreatedOn) VALUES ('Quarterly Estimate', 'Estimated quarterly replenishment', 1, GETDATE());

-- SurgicalItemGroups (Surgical Group sidebar item)
IF NOT EXISTS (SELECT 1 FROM Inv.SurgicalItemGroups WHERE Name = 'Cardiac Surgery Set')
    INSERT INTO Inv.SurgicalItemGroups (Name, Description, BranchId, IsActive, CreatedOn) VALUES ('Cardiac Surgery Set', 'Items grouped for cardiac procedures', @BranchId, 1, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.SurgicalItemGroups WHERE Name = 'General Surgery Set')
    INSERT INTO Inv.SurgicalItemGroups (Name, Description, BranchId, IsActive, CreatedOn) VALUES ('General Surgery Set', 'Items grouped for general surgery', @BranchId, 1, GETDATE());

-- Inv.Stores (Store Management sidebar item -- distinct from Pharmacy.PharmacyStores)
IF NOT EXISTS (SELECT 1 FROM Inv.Stores WHERE StoreName = 'Main Warehouse')
    INSERT INTO Inv.Stores (StoreName, StoreCode, Description, IsActive, CreatedById, CreatedOn) VALUES ('Main Warehouse', 'WH-01', 'Central inventory warehouse', 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.Stores WHERE StoreName = 'OT Store')
    INSERT INTO Inv.Stores (StoreName, StoreCode, Description, IsActive, CreatedById, CreatedOn) VALUES ('OT Store', 'WH-02', 'Operation theatre supplies store', 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.Stores WHERE StoreName = 'ER Store')
    INSERT INTO Inv.Stores (StoreName, StoreCode, Description, IsActive, CreatedById, CreatedOn) VALUES ('ER Store', 'WH-03', 'Emergency room supplies store', 1, @CreatedById, GETDATE());

PRINT 'Section 0-1 complete: shared lookup data seeded.';
GO

-- =============================================
-- SECTION 2: Items, Purchase Orders, GRN, Inventory receipts, Racks/Space
-- Allocation, Transfer/Return Inventory, Stock Adjustments, Purchase
-- Summaries, Contingent Bills, Store Allocation To User, Asset Allocations,
-- Demand Requests.
-- (Adapted from Database/HMS/HMS_TestDataSeed.sql; Brand1Id/Brand2Id source
-- from Data.Brands -- the live table Items.BrandId actually has an FK to on
-- HMSMAIN_TF (confirmed live: 64 real rows). An earlier version of this
-- script assumed a separate "Inv.Brands" table existed and was the correct
-- target instead - it does not exist on this database at all ("Invalid
-- object name 'Inv.Brands'" at runtime); Data.Brands was always the real one.)
-- =============================================
SET NOCOUNT ON;

DECLARE @BranchId INT = COALESCE((SELECT TOP 1 Id FROM Inv.Branches WHERE IsActive = 1 ORDER BY Id), 1);
DECLARE @CreatedById INT = COALESCE((SELECT TOP 1 UserID FROM dbo.Users ORDER BY UserID), 1);
DECLARE @DepartmentId INT = (SELECT TOP 1 Id FROM Inv.Departments ORDER BY Id);
DECLARE @SubDepartmentId INT = (SELECT TOP 1 Id FROM Inv.SubDepartments WHERE DepartmentId = @DepartmentId ORDER BY Id);
DECLARE @RoomId INT = (SELECT TOP 1 Id FROM Inv.Rooms ORDER BY Id);

DECLARE @MedicineStoreId INT = COALESCE((SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE StoreName = 'Medicine Store' ORDER BY StoreId), (SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE IsActive = 1 ORDER BY StoreId));
DECLARE @DisposableStoreId INT = COALESCE((SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE StoreName = 'Main Disposable Store' ORDER BY StoreId), (SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE IsActive = 1 AND StoreId <> @MedicineStoreId ORDER BY StoreId));
DECLARE @EmergencyStoreId INT = COALESCE((SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE StoreName = 'Emergency Store' ORDER BY StoreId), (SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE IsActive = 1 AND StoreId NOT IN (@MedicineStoreId, @DisposableStoreId) ORDER BY StoreId));
DECLARE @RackStoreId INT = COALESCE(
    (SELECT TOP 1 s.StoreId FROM Inv.PharmacyStores s INNER JOIN Pharmacy.PharmacyStores ps ON ps.Id = s.StoreId WHERE s.StoreId = @DisposableStoreId),
    (SELECT TOP 1 s.StoreId FROM Inv.PharmacyStores s INNER JOIN Pharmacy.PharmacyStores ps ON ps.Id = s.StoreId WHERE s.StoreId = @EmergencyStoreId),
    (SELECT TOP 1 s.StoreId FROM Inv.PharmacyStores s INNER JOIN Pharmacy.PharmacyStores ps ON ps.Id = s.StoreId ORDER BY s.StoreId)
);

DECLARE @RegularStockTypeId INT = COALESCE((SELECT TOP 1 Id FROM Inv.StockTypes WHERE Name = 'Regular' ORDER BY Id), (SELECT TOP 1 Id FROM Inv.StockTypes ORDER BY Id));
DECLARE @DonationStockTypeId INT = COALESCE((SELECT TOP 1 Id FROM Inv.StockTypes WHERE Name = 'Donation' ORDER BY Id), @RegularStockTypeId);
DECLARE @Vendor1Id INT = (SELECT TOP 1 Id FROM Inv.Vendors WHERE IsActive = 1 ORDER BY Id);
DECLARE @Vendor2Id INT = COALESCE((SELECT TOP 1 Id FROM Inv.Vendors WHERE IsActive = 1 AND Id <> @Vendor1Id ORDER BY Id), @Vendor1Id);
DECLARE @Manufacturer1Id INT = (SELECT TOP 1 Id FROM Inv.PharmacyManufacturers ORDER BY Id);
DECLARE @Manufacturer2Id INT = COALESCE((SELECT TOP 1 Id FROM Inv.PharmacyManufacturers WHERE Id <> @Manufacturer1Id ORDER BY Id), @Manufacturer1Id);
DECLARE @Brand1Id INT = (SELECT TOP 1 Id FROM Data.Brands WHERE IsActive = 1 ORDER BY Id);
DECLARE @Brand2Id INT = COALESCE((SELECT TOP 1 Id FROM Data.Brands WHERE IsActive = 1 AND Id <> @Brand1Id ORDER BY Id), @Brand1Id);
DECLARE @ItemType1Id INT = (SELECT TOP 1 Id FROM Inv.ItemTypes ORDER BY Id);
DECLARE @ItemType2Id INT = COALESCE((SELECT TOP 1 Id FROM Inv.ItemTypes WHERE Id <> @ItemType1Id ORDER BY Id), @ItemType1Id);
DECLARE @UnitId INT = (SELECT TOP 1 Id FROM Inv.ItemUnits ORDER BY Id);
DECLARE @PackingId INT = (SELECT TOP 1 Id FROM Inv.Packings ORDER BY Id);
DECLARE @CategoryId INT = (SELECT TOP 1 Id FROM Inv.Categories ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderTypes WHERE Name = 'Local Purchase')
BEGIN
    INSERT INTO Inv.PurchaseOrderTypes (Name, Description, IsActive, CreatedById, CreatedOn)
    VALUES ('Local Purchase', 'Seeded HMS local purchase type', 1, 'seed', GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderTypes WHERE Name = 'Emergency Purchase')
BEGIN
    INSERT INTO Inv.PurchaseOrderTypes (Name, Description, IsActive, CreatedById, CreatedOn)
    VALUES ('Emergency Purchase', 'Seeded HMS emergency purchase type', 1, 'seed', GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestStatuses WHERE Name = 'Pending')
BEGIN
    INSERT INTO Inv.DemandRequestStatuses (Name, Description, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, Value)
    VALUES ('Pending', 'Seeded pending status', @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestStatuses WHERE Name = 'Approved')
BEGIN
    INSERT INTO Inv.DemandRequestStatuses (Name, Description, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, Value)
    VALUES ('Approved', 'Seeded approved status', @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 2);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestStatuses WHERE Name = 'Issued')
BEGIN
    INSERT INTO Inv.DemandRequestStatuses (Name, Description, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, Value)
    VALUES ('Issued', 'Seeded issued status', @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 3);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestStatuses WHERE Name = 'Received')
BEGIN
    INSERT INTO Inv.DemandRequestStatuses (Name, Description, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, Value)
    VALUES ('Received', 'Seeded received status', @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 4);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.ItemTypeSaleLevels WHERE ItemTypeId = @ItemType1Id)
BEGIN
    INSERT INTO Inv.ItemTypeSaleLevels (ItemTypeId, FastRunningLevel, SlowMovingLevel, DeadLevel, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES (@ItemType1Id, 80, 40, 10, @BranchId, 1, @CreatedById, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.ItemTypeSaleLevels WHERE ItemTypeId = @ItemType2Id)
BEGIN
    INSERT INTO Inv.ItemTypeSaleLevels (ItemTypeId, FastRunningLevel, SlowMovingLevel, DeadLevel, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES (@ItemType2Id, 50, 25, 5, @BranchId, 1, @CreatedById, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Items WHERE Name = 'HMS Seed Syringe 10ml')
BEGIN
    INSERT INTO Inv.Items (Name, Description, ItemTypeId, BrandId, CategoryId, PackingId, UnitId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, IsProduct, BatchExpiryRequired, Conversion, CaseContains, RetailPrice, SalePrice, CostMethod, Preference, MinimumPanicLevel, IsExpensiveItem, IsFridgeItem, Code, MarketPrice, QuantityPerPacket)
    VALUES ('HMS Seed Syringe 10ml', 'Seed disposable syringe for HMS testing', @ItemType1Id, @Brand1Id, @CategoryId, @PackingId, @UnitId, @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1, 1, 1, 10, 12, 10, 0, 0, 25, 0, 0, 'HMS-SYR-10', 11, 10);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Items WHERE Name = 'HMS Seed IV Cannula 20G')
BEGIN
    INSERT INTO Inv.Items (Name, Description, ItemTypeId, BrandId, CategoryId, PackingId, UnitId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, IsProduct, BatchExpiryRequired, Conversion, CaseContains, RetailPrice, SalePrice, CostMethod, Preference, MinimumPanicLevel, IsExpensiveItem, IsFridgeItem, Code, MarketPrice, QuantityPerPacket)
    VALUES ('HMS Seed IV Cannula 20G', 'Seed IV cannula for HMS testing', @ItemType1Id, @Brand2Id, @CategoryId, @PackingId, @UnitId, @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1, 1, 1, 10, 38, 35, 0, 0, 20, 0, 0, 'HMS-CAN-20', 36, 10);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Items WHERE Name = 'HMS Seed ECG Electrode')
BEGIN
    INSERT INTO Inv.Items (Name, Description, ItemTypeId, BrandId, CategoryId, PackingId, UnitId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, IsProduct, BatchExpiryRequired, Conversion, CaseContains, RetailPrice, SalePrice, CostMethod, Preference, MinimumPanicLevel, IsExpensiveItem, IsFridgeItem, Code, MarketPrice, QuantityPerPacket)
    VALUES ('HMS Seed ECG Electrode', 'Seed ECG electrode for HMS testing', @ItemType2Id, @Brand1Id, @CategoryId, @PackingId, @UnitId, @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1, 1, 1, 20, 22, 20, 0, 0, 15, 0, 0, 'HMS-ECG-01', 21, 20);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Items WHERE Name = 'HMS Seed Test Tube 5ml')
BEGIN
    INSERT INTO Inv.Items (Name, Description, ItemTypeId, BrandId, CategoryId, PackingId, UnitId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, IsProduct, BatchExpiryRequired, Conversion, CaseContains, RetailPrice, SalePrice, CostMethod, Preference, MinimumPanicLevel, IsExpensiveItem, IsFridgeItem, Code, MarketPrice, QuantityPerPacket)
    VALUES ('HMS Seed Test Tube 5ml', 'Seed laboratory tube for HMS testing', @ItemType2Id, @Brand2Id, @CategoryId, @PackingId, @UnitId, @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1, 1, 1, 50, 7, 5, 0, 0, 100, 0, 0, 'HMS-TUBE-5', 6, 50);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Items WHERE Name = 'HMS Seed Vaccine Vial')
BEGIN
    INSERT INTO Inv.Items (Name, Description, ItemTypeId, BrandId, CategoryId, PackingId, UnitId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedOn, IsProduct, BatchExpiryRequired, Conversion, CaseContains, RetailPrice, SalePrice, CostMethod, Preference, MinimumPanicLevel, IsExpensiveItem, IsFridgeItem, Code, MarketPrice, QuantityPerPacket)
    VALUES ('HMS Seed Vaccine Vial', 'Seed fridge-sensitive vial for HMS testing', @ItemType1Id, @Brand1Id, @CategoryId, @PackingId, @UnitId, @BranchId, 1, @CreatedById, GETDATE(), GETDATE(), 1, 1, 1, 1, 165, 150, 0, 0, 8, 1, 1, 'HMS-VAC-01', 155, 1);
END;

DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed Syringe 10ml' ORDER BY Id);
DECLARE @CannulaItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed IV Cannula 20G' ORDER BY Id);
DECLARE @ElectrodeItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed ECG Electrode' ORDER BY Id);
DECLARE @TubeItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed Test Tube 5ml' ORDER BY Id);
DECLARE @VaccineItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed Vaccine Vial' ORDER BY Id);

DECLARE @Po1Id INT;
IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrders WHERE PONumber = 'PO-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.PurchaseOrders (PONumber, ManualPONumber, StoreId, VendorId, POValidityDate, Subject, Instructions, TermsAndConditions, Status, TotalQuantity, TotalAmount, IsActive, CreatedById, CreatedOn)
    VALUES ('PO-HMS-SEED-001', 'MPO-HMS-001', @MedicineStoreId, @Vendor1Id, DATEADD(DAY, 14, GETDATE()), 'Seeded medicine replenishment', 'Deliver by next shift', 'Payment after verification', 'Approved', 220, 4860, 1, @CreatedById, DATEADD(DAY, -12, GETDATE()));
    SET @Po1Id = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES
        (@Po1Id, @SyringeItemId, 'Disposable', 8, 160, 1600, 10, 1600, 1, @CreatedById, DATEADD(DAY, -12, GETDATE())),
        (@Po1Id, @CannulaItemId, 'Disposable', 3, 60, 2100, 35, 2100, 1, @CreatedById, DATEADD(DAY, -12, GETDATE())),
        (@Po1Id, @VaccineItemId, 'Medicine', 1, 12, 1160, 96.67, 1160, 1, @CreatedById, DATEADD(DAY, -12, GETDATE()));

    INSERT INTO Inv.PurchaseOrderStatus (PurchaseOrderId, Status, Notes, CreatedById, CreatedOn)
    VALUES (@Po1Id, 'Approved', 'Seeded approved purchase order', @CreatedById, DATEADD(DAY, -11, GETDATE()));
END
ELSE
BEGIN
    SET @Po1Id = (SELECT TOP 1 PurchaseOrderId FROM Inv.PurchaseOrders WHERE PONumber = 'PO-HMS-SEED-001' ORDER BY PurchaseOrderId);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po1Id, @SyringeItemId, 'Disposable', 8, 160, 1600, 10, 1600, 1, @CreatedById, DATEADD(DAY, -12, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @CannulaItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po1Id, @CannulaItemId, 'Disposable', 3, 60, 2100, 35, 2100, 1, @CreatedById, DATEADD(DAY, -12, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @VaccineItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po1Id, @VaccineItemId, 'Medicine', 1, 12, 1160, 96.67, 1160, 1, @CreatedById, DATEADD(DAY, -12, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderStatus WHERE PurchaseOrderId = @Po1Id AND Status = 'Approved')
BEGIN
    INSERT INTO Inv.PurchaseOrderStatus (PurchaseOrderId, Status, Notes, CreatedById, CreatedOn)
    VALUES (@Po1Id, 'Approved', 'Seeded approved purchase order', @CreatedById, DATEADD(DAY, -11, GETDATE()));
END;

DECLARE @Po2Id INT;
IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrders WHERE PONumber = 'PO-HMS-SEED-002')
BEGIN
    INSERT INTO Inv.PurchaseOrders (PONumber, ManualPONumber, StoreId, VendorId, POValidityDate, Subject, Instructions, TermsAndConditions, Status, TotalQuantity, TotalAmount, IsActive, CreatedById, CreatedOn)
    VALUES ('PO-HMS-SEED-002', 'MPO-HMS-002', @DisposableStoreId, @Vendor2Id, DATEADD(DAY, 10, GETDATE()), 'Seeded disposables and lab order', 'Handle with care', 'Partial delivery allowed', 'Pending', 330, 3760, 1, @CreatedById, DATEADD(DAY, -7, GETDATE()));
    SET @Po2Id = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES
        (@Po2Id, @ElectrodeItemId, 'Disposable', 5, 100, 2000, 20, 2000, 1, @CreatedById, DATEADD(DAY, -7, GETDATE())),
        (@Po2Id, @TubeItemId, 'Item', 4, 200, 800, 4, 800, 1, @CreatedById, DATEADD(DAY, -7, GETDATE())),
        (@Po2Id, @SyringeItemId, 'Disposable', 8, 160, 960, 6, 960, 1, @CreatedById, DATEADD(DAY, -7, GETDATE()));

    INSERT INTO Inv.PurchaseOrderStatus (PurchaseOrderId, Status, Notes, CreatedById, CreatedOn)
    VALUES (@Po2Id, 'Pending', 'Seeded pending purchase order', @CreatedById, DATEADD(DAY, -6, GETDATE()));
END
ELSE
BEGIN
    SET @Po2Id = (SELECT TOP 1 PurchaseOrderId FROM Inv.PurchaseOrders WHERE PONumber = 'PO-HMS-SEED-002' ORDER BY PurchaseOrderId);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po2Id AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po2Id, @ElectrodeItemId, 'Disposable', 5, 100, 2000, 20, 2000, 1, @CreatedById, DATEADD(DAY, -7, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po2Id AND ItemId = @TubeItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po2Id, @TubeItemId, 'Item', 4, 200, 800, 4, 800, 1, @CreatedById, DATEADD(DAY, -7, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po2Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.PurchaseOrderItems (PurchaseOrderId, ItemId, ItemType, PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice, IsActive, CreatedById, CreatedOn)
    VALUES (@Po2Id, @SyringeItemId, 'Disposable', 8, 160, 960, 6, 960, 1, @CreatedById, DATEADD(DAY, -7, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseOrderStatus WHERE PurchaseOrderId = @Po2Id AND Status = 'Pending')
BEGIN
    INSERT INTO Inv.PurchaseOrderStatus (PurchaseOrderId, Status, Notes, CreatedById, CreatedOn)
    VALUES (@Po2Id, 'Pending', 'Seeded pending purchase order', @CreatedById, DATEADD(DAY, -6, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GoodsReceivingNotes WHERE InvoiceNo = 'GRN-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.GoodsReceivingNotes (PurchaseOrderId, InvoiceNo, PONumber, StockTypeId, DateAndTime, VendorInvoiceNo, VendorInvoiceDate, VendorId, IsActive, CreatedById, CreatedOn)
    VALUES (@Po1Id, 'GRN-HMS-SEED-001', 'PO-HMS-SEED-001', @RegularStockTypeId, DATEADD(DAY, -9, GETDATE()), 'VINV-HMS-001', DATEADD(DAY, -9, GETDATE()), @Vendor1Id, 1, @CreatedById, DATEADD(DAY, -9, GETDATE()));

    DECLARE @Grn1Id INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES
        (@Grn1Id, @SyringeItemId, @Manufacturer1Id, DATEADD(MONTH, -2, GETDATE()), DATEADD(MONTH, 10, GETDATE()), 'REG-HMS-001', 'LOT-HMS-001', 'BATCH-HMS-001', 8, 16, 10, 160, 10, 160, 140, 1600, 10, 0, 0, 0, 0, 0, 0, 0, 0, 12, 1920, 2, 320),
        (@Grn1Id, @CannulaItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 14, GETDATE()), 'REG-HMS-002', 'LOT-HMS-002', 'BATCH-HMS-002', 3, 6, 10, 60, 10, 60, 48, 2100, 35, 0, 0, 0, 0, 0, 0, 0, 0, 38, 2280, 3, 180),
        (@Grn1Id, @VaccineItemId, @Manufacturer1Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 6, GETDATE()), 'REG-HMS-003', 'LOT-HMS-003', 'BATCH-HMS-003', 1, 12, 1, 12, 1, 12, 9, 1160, 96.67, 0, 0, 0, 0, 0, 0, 0, 0, 150, 1800, 53.33, 640);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GoodsReceivingNotes WHERE InvoiceNo = 'GRN-HMS-SEED-002')
BEGIN
    INSERT INTO Inv.GoodsReceivingNotes (PurchaseOrderId, InvoiceNo, PONumber, StockTypeId, DateAndTime, VendorInvoiceNo, VendorInvoiceDate, VendorId, IsActive, CreatedById, CreatedOn)
    VALUES (@Po2Id, 'GRN-HMS-SEED-002', 'PO-HMS-SEED-002', @DonationStockTypeId, DATEADD(DAY, -4, GETDATE()), 'VINV-HMS-002', DATEADD(DAY, -4, GETDATE()), @Vendor2Id, 1, @CreatedById, DATEADD(DAY, -4, GETDATE()));

    DECLARE @Grn2Id INT = CAST(SCOPE_IDENTITY() AS INT);

    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES
        (@Grn2Id, @ElectrodeItemId, @Manufacturer1Id, DATEADD(MONTH, -3, GETDATE()), DATEADD(MONTH, 8, GETDATE()), 'REG-HMS-004', 'LOT-HMS-004', 'BATCH-HMS-004', 5, 10, 10, 100, 10, 100, 90, 2000, 20, 0, 0, 0, 0, 0, 0, 0, 0, 22, 2200, 2, 200),
        (@Grn2Id, @TubeItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 18, GETDATE()), 'REG-HMS-005', 'LOT-HMS-005', 'BATCH-HMS-005', 4, 8, 25, 200, 25, 200, 180, 800, 4, 0, 0, 0, 0, 0, 0, 0, 0, 5, 1000, 1, 200);
END;

DECLARE @Grn1IdExisting INT = (SELECT TOP 1 Id FROM Inv.GoodsReceivingNotes WHERE InvoiceNo = 'GRN-HMS-SEED-001' ORDER BY Id);
DECLARE @Grn2IdExisting INT = (SELECT TOP 1 Id FROM Inv.GoodsReceivingNotes WHERE InvoiceNo = 'GRN-HMS-SEED-002' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.GRNItems WHERE GRNId = @Grn1IdExisting AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES (@Grn1IdExisting, @SyringeItemId, @Manufacturer1Id, DATEADD(MONTH, -2, GETDATE()), DATEADD(MONTH, 10, GETDATE()), 'REG-HMS-001', 'LOT-HMS-001', 'BATCH-HMS-001', 8, 16, 10, 160, 10, 160, 140, 1600, 10, 0, 0, 0, 0, 0, 0, 0, 0, 12, 1920, 2, 320);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GRNItems WHERE GRNId = @Grn1IdExisting AND ItemId = @CannulaItemId)
BEGIN
    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES (@Grn1IdExisting, @CannulaItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 14, GETDATE()), 'REG-HMS-002', 'LOT-HMS-002', 'BATCH-HMS-002', 3, 6, 10, 60, 10, 60, 48, 2100, 35, 0, 0, 0, 0, 0, 0, 0, 0, 38, 2280, 3, 180);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GRNItems WHERE GRNId = @Grn1IdExisting AND ItemId = @VaccineItemId)
BEGIN
    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES (@Grn1IdExisting, @VaccineItemId, @Manufacturer1Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 6, GETDATE()), 'REG-HMS-003', 'LOT-HMS-003', 'BATCH-HMS-003', 1, 12, 1, 12, 1, 12, 9, 1160, 96.67, 0, 0, 0, 0, 0, 0, 0, 0, 150, 1800, 53.33, 640);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GRNItems WHERE GRNId = @Grn2IdExisting AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES (@Grn2IdExisting, @ElectrodeItemId, @Manufacturer1Id, DATEADD(MONTH, -3, GETDATE()), DATEADD(MONTH, 8, GETDATE()), 'REG-HMS-004', 'LOT-HMS-004', 'BATCH-HMS-004', 5, 10, 10, 100, 10, 100, 90, 2000, 20, 0, 0, 0, 0, 0, 0, 0, 0, 22, 2200, 2, 200);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.GRNItems WHERE GRNId = @Grn2IdExisting AND ItemId = @TubeItemId)
BEGIN
    INSERT INTO Inv.GRNItems (GRNId, ItemId, ManufacturerId, MfgDate, ExpiryDate, RegistrationNumber, LotNo, BatchNo, NoOfBoxes, NoOfPackets, ItemPerPacket, TotalItem, PackQuantity, ReceivedQuantity, RemainingQuantity, TotalBuyingPrice, UnitBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES (@Grn2IdExisting, @TubeItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 18, GETDATE()), 'REG-HMS-005', 'LOT-HMS-005', 'BATCH-HMS-005', 4, 8, 25, 200, 25, 200, 180, 800, 4, 0, 0, 0, 0, 0, 0, 0, 0, 5, 1000, 1, 200);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Inventories WHERE InvoiceNo = 'INV-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.Inventories (PurchaseOrderNumber, InvoiceNo, PurchaseOrderId, VendorId, StoreId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, IsFinalized, StockTypeId, VendorInvoiceNumber, VendorInvoiceTimestamp, Amount, Discount, DiscountType, Total, PaidAmount, IsPaymentPending, TotalBuyingPrice, AdvanceTaxPercentage, AdvanceTaxCalculatedAmount, RetailCharges, RetailChargesCalculatedAmount, GSTCharges, GSTChargesCalculatedAmount, ManualPurchaseOrderNumber)
    VALUES ('PO-HMS-SEED-001', 'INV-HMS-SEED-001', @Po1Id, @Vendor1Id, @MedicineStoreId, @BranchId, 1, @CreatedById, DATEADD(DAY, -9, GETDATE()), @CreatedById, DATEADD(DAY, -9, GETDATE()), 1, @RegularStockTypeId, 'VINV-HMS-001', DATEADD(DAY, -9, GETDATE()), 4860, 0, 0, 4860, 0, 0, 4860, 0, 0, 0, 0, 0, 0, 'MPO-HMS-001');
END;

IF NOT EXISTS (SELECT 1 FROM Inv.Inventories WHERE InvoiceNo = 'INV-HMS-SEED-002')
BEGIN
    INSERT INTO Inv.Inventories (PurchaseOrderNumber, InvoiceNo, PurchaseOrderId, VendorId, StoreId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, IsFinalized, StockTypeId, VendorInvoiceNumber, VendorInvoiceTimestamp, Amount, Discount, DiscountType, Total, PaidAmount, IsPaymentPending, TotalBuyingPrice, AdvanceTaxPercentage, AdvanceTaxCalculatedAmount, RetailCharges, RetailChargesCalculatedAmount, GSTCharges, GSTChargesCalculatedAmount, ManualPurchaseOrderNumber)
    VALUES ('PO-HMS-SEED-002', 'INV-HMS-SEED-002', @Po2Id, @Vendor2Id, @DisposableStoreId, @BranchId, 1, @CreatedById, DATEADD(DAY, -4, GETDATE()), @CreatedById, DATEADD(DAY, -4, GETDATE()), 1, @DonationStockTypeId, 'VINV-HMS-002', DATEADD(DAY, -4, GETDATE()), 2800, 0, 0, 2800, 0, 0, 2800, 0, 0, 0, 0, 0, 0, 'MPO-HMS-002');
END;

DECLARE @Inventory1Id INT = (SELECT TOP 1 Id FROM Inv.Inventories WHERE InvoiceNo = 'INV-HMS-SEED-001' ORDER BY Id);
DECLARE @Inventory2Id INT = (SELECT TOP 1 Id FROM Inv.Inventories WHERE InvoiceNo = 'INV-HMS-SEED-002' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.InventoryDetails WHERE InventoryId = @Inventory1Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.InventoryDetails (InventoryId, ItemId, ManufacturerId, MfgDate, ExpiryDate, NoOfBoxes, NoOfPackets, ItemsPerPacket, TotalItems, PackQuantity, UnitBuyingPrice, TotalBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES
        (@Inventory1Id, @SyringeItemId, @Manufacturer1Id, DATEADD(MONTH, -2, GETDATE()), DATEADD(MONTH, 10, GETDATE()), 8, 16, 10, 160, 10, 10, 1600, 0, 0, 0, 0, 0, 0, 0, 0, 12, 1920, 2, 320),
        (@Inventory1Id, @CannulaItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 14, GETDATE()), 3, 6, 10, 60, 10, 35, 2100, 0, 0, 0, 0, 0, 0, 0, 0, 38, 2280, 3, 180),
        (@Inventory1Id, @VaccineItemId, @Manufacturer1Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 6, GETDATE()), 1, 12, 1, 12, 1, 96.67, 1160, 0, 0, 0, 0, 0, 0, 0, 0, 150, 1800, 53.33, 640);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.InventoryDetails WHERE InventoryId = @Inventory2Id AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.InventoryDetails (InventoryId, ItemId, ManufacturerId, MfgDate, ExpiryDate, NoOfBoxes, NoOfPackets, ItemsPerPacket, TotalItems, PackQuantity, UnitBuyingPrice, TotalBuyingPrice, AdvanceTaxPercentage, AdvanceTaxAmount, Discount, DiscountAmount, RetailCharges, RetailChargesAmount, GSTCharges, GSTChargesAmount, UnitSellingPrice, TotalSellingPrice, ProfitMarginPerItem, ProfitPerItem)
    VALUES
        (@Inventory2Id, @ElectrodeItemId, @Manufacturer1Id, DATEADD(MONTH, -3, GETDATE()), DATEADD(MONTH, 8, GETDATE()), 5, 10, 10, 100, 10, 20, 2000, 0, 0, 0, 0, 0, 0, 0, 0, 22, 2200, 2, 200),
        (@Inventory2Id, @TubeItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 18, GETDATE()), 4, 8, 25, 200, 25, 4, 800, 0, 0, 0, 0, 0, 0, 0, 0, 5, 1000, 1, 200);
END;

DECLARE @Po1SyringeLineId INT = (SELECT TOP 1 Id FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @SyringeItemId ORDER BY Id);
DECLARE @Po1CannulaLineId INT = (SELECT TOP 1 Id FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @CannulaItemId ORDER BY Id);
DECLARE @Po1VaccineLineId INT = (SELECT TOP 1 Id FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po1Id AND ItemId = @VaccineItemId ORDER BY Id);
DECLARE @Po2ElectrodeLineId INT = (SELECT TOP 1 Id FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po2Id AND ItemId = @ElectrodeItemId ORDER BY Id);
DECLARE @Po2TubeLineId INT = (SELECT TOP 1 Id FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @Po2Id AND ItemId = @TubeItemId ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.InventoryItems WHERE InventoryId = @Inventory1Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.InventoryItems (InventoryId, ItemId, ManufacturerId, ManufacturingDate, ExpiryDate, Batch, NumberOfPackets, ItemsPerPacket, TotalItems, TotalBuyingPriceId, UnitBuyingPriceId, UnitSellingPriceId, TotalSellingPriceId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, NumberOfBoxes, PurchaseOrderItemId, StockTypeId, SysBatchNo, BalanceTotalItems, Amount, Discount, DiscountType, Total, RetailCharges, RetailChargesType, IsDeleted, AdvanceTaxPercentage, AdvanceTaxCalculatedAmount, GSTCharges, GSTChargesType, RetailChargesCalculatedAmount, GSTChargesCalculatedAmount)
    VALUES
        (@Inventory1Id, @SyringeItemId, @Manufacturer1Id, DATEADD(MONTH, -2, GETDATE()), DATEADD(MONTH, 10, GETDATE()), 'BATCH-HMS-001', 16, 10, 160, 0, 0, 0, 0, @BranchId, 1, @CreatedById, DATEADD(DAY, -9, GETDATE()), @CreatedById, DATEADD(DAY, -9, GETDATE()), 8, @Po1SyringeLineId, @RegularStockTypeId, 'SYS-BATCH-HMS-001', 140, 1600, 0, 0, 1600, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (@Inventory1Id, @CannulaItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 14, GETDATE()), 'BATCH-HMS-002', 6, 10, 60, 0, 0, 0, 0, @BranchId, 1, @CreatedById, DATEADD(DAY, -9, GETDATE()), @CreatedById, DATEADD(DAY, -9, GETDATE()), 3, @Po1CannulaLineId, @RegularStockTypeId, 'SYS-BATCH-HMS-002', 48, 2100, 0, 0, 2100, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (@Inventory1Id, @VaccineItemId, @Manufacturer1Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 6, GETDATE()), 'BATCH-HMS-003', 12, 1, 12, 0, 0, 0, 0, @BranchId, 1, @CreatedById, DATEADD(DAY, -9, GETDATE()), @CreatedById, DATEADD(DAY, -9, GETDATE()), 1, @Po1VaccineLineId, @RegularStockTypeId, 'SYS-BATCH-HMS-003', 9, 1160, 0, 0, 1160, 0, 0, 0, 0, 0, 0, 0, 0, 0);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.InventoryItems WHERE InventoryId = @Inventory2Id AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.InventoryItems (InventoryId, ItemId, ManufacturerId, ManufacturingDate, ExpiryDate, Batch, NumberOfPackets, ItemsPerPacket, TotalItems, TotalBuyingPriceId, UnitBuyingPriceId, UnitSellingPriceId, TotalSellingPriceId, BranchId, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, NumberOfBoxes, PurchaseOrderItemId, StockTypeId, SysBatchNo, BalanceTotalItems, Amount, Discount, DiscountType, Total, RetailCharges, RetailChargesType, IsDeleted, AdvanceTaxPercentage, AdvanceTaxCalculatedAmount, GSTCharges, GSTChargesType, RetailChargesCalculatedAmount, GSTChargesCalculatedAmount)
    VALUES
        (@Inventory2Id, @ElectrodeItemId, @Manufacturer1Id, DATEADD(MONTH, -3, GETDATE()), DATEADD(MONTH, 8, GETDATE()), 'BATCH-HMS-004', 10, 10, 100, 0, 0, 0, 0, @BranchId, 1, @CreatedById, DATEADD(DAY, -4, GETDATE()), @CreatedById, DATEADD(DAY, -4, GETDATE()), 5, @Po2ElectrodeLineId, @DonationStockTypeId, 'SYS-BATCH-HMS-004', 90, 2000, 0, 0, 2000, 0, 0, 0, 0, 0, 0, 0, 0, 0),
        (@Inventory2Id, @TubeItemId, @Manufacturer2Id, DATEADD(MONTH, -1, GETDATE()), DATEADD(MONTH, 18, GETDATE()), 'BATCH-HMS-005', 8, 25, 200, 0, 0, 0, 0, @BranchId, 1, @CreatedById, DATEADD(DAY, -4, GETDATE()), @CreatedById, DATEADD(DAY, -4, GETDATE()), 4, @Po2TubeLineId, @DonationStockTypeId, 'SYS-BATCH-HMS-005', 180, 800, 0, 0, 800, 0, 0, 0, 0, 0, 0, 0, 0, 0);
END;

DECLARE @RackId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.Racks WHERE Name = 'HMS Seed Rack A')
BEGIN
    INSERT INTO Inv.Racks (Name, Description, Location, NumberOfRows, NumberOfCols, NumberOfDrawrs, StoreId, BranchId, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('HMS Seed Rack A', 'Seed rack for stock expiry testing', 'Seeded main aisle', 2, 2, 2, @RackStoreId, @BranchId, @CreatedById, GETDATE(), 0, 1);
END;
SET @RackId = (SELECT TOP 1 Id FROM Inv.Racks WHERE Name = 'HMS Seed Rack A' ORDER BY Id);

DECLARE @RackRowId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.RackRows WHERE Name = 'Row A1' AND RackId = @RackId)
BEGIN
    INSERT INTO Inv.RackRows (Name, Description, StoreId, RackId, BranchId, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('Row A1', 'Seed rack row', @RackStoreId, @RackId, @BranchId, @CreatedById, GETDATE(), 0, 1);
END;
SET @RackRowId = (SELECT TOP 1 Id FROM Inv.RackRows WHERE Name = 'Row A1' AND RackId = @RackId ORDER BY Id);

DECLARE @RackColumnId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.RackColumns WHERE Name = 'Column A1' AND RackId = @RackId)
BEGIN
    INSERT INTO Inv.RackColumns (Name, Description, StoreId, RackId, BranchId, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('Column A1', 'Seed rack column', @RackStoreId, @RackId, @BranchId, @CreatedById, GETDATE(), 0, 1);
END;
SET @RackColumnId = (SELECT TOP 1 Id FROM Inv.RackColumns WHERE Name = 'Column A1' AND RackId = @RackId ORDER BY Id);

DECLARE @RackDrawrId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.RackDrawrs WHERE Name = 'Drawer A1' AND RackId = @RackId)
BEGIN
    INSERT INTO Inv.RackDrawrs (Name, Description, StoreId, RackId, RackRowId, RackColumnId, BranchId, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES ('Drawer A1', 'Seed rack drawer', @RackStoreId, @RackId, @RackRowId, @RackColumnId, @BranchId, @CreatedById, GETDATE(), 0, 1);
END;
SET @RackDrawrId = (SELECT TOP 1 Id FROM Inv.RackDrawrs WHERE Name = 'Drawer A1' AND RackId = @RackId ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.SpaceAllocations WHERE ItemId = @SyringeItemId AND StoreId = @RackStoreId)
BEGIN
    INSERT INTO Inv.SpaceAllocations (StoreId, ItemId, RackId, RackRowId, RackColumnId, RackDrawrId, CreatedById, CreatedOn, IsDeleted, IsActive, BranchId)
    VALUES (@RackStoreId, @SyringeItemId, @RackId, @RackRowId, @RackColumnId, @RackDrawrId, @CreatedById, GETDATE(), 0, 1, @BranchId);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.SpaceAllocations WHERE ItemId = @CannulaItemId AND StoreId = @RackStoreId)
BEGIN
    INSERT INTO Inv.SpaceAllocations (StoreId, ItemId, RackId, RackRowId, RackColumnId, RackDrawrId, CreatedById, CreatedOn, IsDeleted, IsActive, BranchId)
    VALUES (@RackStoreId, @CannulaItemId, @RackId, @RackRowId, @RackColumnId, @RackDrawrId, @CreatedById, GETDATE(), 0, 1, @BranchId);
END;

DECLARE @TransferId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.TransferInventory WHERE TransferNumber = 'TI-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.TransferInventory (TransferNumber, FromStoreId, ToStoreId, BranchId, TransferDate, Notes, Status, IsActive, CreatedById, CreatedOn)
    VALUES ('TI-HMS-SEED-001', @MedicineStoreId, @EmergencyStoreId, @BranchId, DATEADD(DAY, -2, GETDATE()), 'Seeded inter-store transfer', 'Completed', 1, @CreatedById, DATEADD(DAY, -2, GETDATE()));
END;
SET @TransferId = (SELECT TOP 1 Id FROM Inv.TransferInventory WHERE TransferNumber = 'TI-HMS-SEED-001' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.TransferInventoryItems WHERE TransferInventoryId = @TransferId AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.TransferInventoryItems (TransferInventoryId, ItemId, Quantity, Notes, IsActive, CreatedOn)
    VALUES (@TransferId, @SyringeItemId, 24, 'Seeded transfer item', 1, DATEADD(DAY, -2, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.TransferInventoryItems WHERE TransferInventoryId = @TransferId AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.TransferInventoryItems (TransferInventoryId, ItemId, Quantity, Notes, IsActive, CreatedOn)
    VALUES (@TransferId, @ElectrodeItemId, 10, 'Seeded transfer item', 1, DATEADD(DAY, -2, GETDATE()));
END;

DECLARE @ReturnId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.ReturnInventory WHERE ReturnNumber = 'RI-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.ReturnInventory (ReturnNumber, VendorId, StoreId, BranchId, ReturnDate, Reason, Notes, Status, IsActive, CreatedById, CreatedOn)
    VALUES ('RI-HMS-SEED-001', @Vendor1Id, @MedicineStoreId, @BranchId, DATEADD(DAY, -1, GETDATE()), 'Damaged outer packs', 'Seeded vendor return', 'Submitted', 1, @CreatedById, DATEADD(DAY, -1, GETDATE()));
END;
SET @ReturnId = (SELECT TOP 1 Id FROM Inv.ReturnInventory WHERE ReturnNumber = 'RI-HMS-SEED-001' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.ReturnInventoryItems WHERE ReturnInventoryId = @ReturnId AND ItemId = @CannulaItemId)
BEGIN
    INSERT INTO Inv.ReturnInventoryItems (ReturnInventoryId, ItemId, Quantity, Reason, Notes, IsActive, CreatedOn)
    VALUES (@ReturnId, @CannulaItemId, 5, 'Packaging issue', 'Seeded return item', 1, DATEADD(DAY, -1, GETDATE()));
END;

DECLARE @InventoryItemSyringeId INT = (SELECT TOP 1 Id FROM Inv.InventoryItems WHERE InventoryId = @Inventory1Id AND ItemId = @SyringeItemId ORDER BY Id);

DECLARE @StockAdjustmentId INT;
IF NOT EXISTS (SELECT 1 FROM Inv.StockAdjustments WHERE StoreId = @MedicineStoreId AND CAST(CreatedOn AS DATE) = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE))
BEGIN
    INSERT INTO Inv.StockAdjustments (StoreId, Type, VoucherId, BranchId, CreatedById, CreatedOn, IsActive, IsDeleted)
    VALUES (@MedicineStoreId, 1, NULL, @BranchId, @CreatedById, DATEADD(DAY, -1, GETDATE()), 1, 0);
END;
SET @StockAdjustmentId = (SELECT TOP 1 Id FROM Inv.StockAdjustments WHERE StoreId = @MedicineStoreId ORDER BY Id DESC);

IF NOT EXISTS (SELECT 1 FROM Inv.StockAdjustmentDetails WHERE StockAdjustmentId = @StockAdjustmentId AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.StockAdjustmentDetails (StockAdjustmentId, ItemId, Type, StockTypeId, Quantity, BranchId, CreatedById, CreatedOn, IsActive, IsDeleted, InventoryItemId, SysBatchNo, BatchNo, PurchaseValue, SaleValue)
    VALUES (@StockAdjustmentId, @SyringeItemId, 1, @RegularStockTypeId, 4, @BranchId, @CreatedById, DATEADD(DAY, -1, GETDATE()), 1, 0, @InventoryItemSyringeId, 'SYS-BATCH-HMS-001', 'BATCH-HMS-001', 40, 48);
END;

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseSummaries WHERE Notes = 'Seeded HMS purchase summary')
BEGIN
    INSERT INTO Inv.PurchaseSummaries (StoreId, BranchId, VendorId, SummaryDate, TotalAmount, Status, Notes, IsActive, CreatedById, CreatedOn)
    VALUES (@MedicineStoreId, @BranchId, @Vendor1Id, GETDATE(), 4860, 'Open', 'Seeded HMS purchase summary', 1, @CreatedById, GETDATE());
END;

DECLARE @PurchaseSummaryId INT = (SELECT TOP 1 Id FROM Inv.PurchaseSummaries WHERE Notes = 'Seeded HMS purchase summary' ORDER BY Id DESC);

IF NOT EXISTS (SELECT 1 FROM Inv.PurchaseSummaryInvoices WHERE PurchaseSummaryId = @PurchaseSummaryId AND InvoiceNumber = 'PSI-HMS-001')
BEGIN
    INSERT INTO Inv.PurchaseSummaryInvoices (PurchaseSummaryId, InvoiceNumber, InvoiceDate, Amount, Notes, IsActive, CreatedOn)
    VALUES (@PurchaseSummaryId, 'PSI-HMS-001', GETDATE(), 4860, 'Seeded HMS purchase summary invoice', 1, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.ContingentBills WHERE BillNumber = 'CB-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.ContingentBills (BillNumber, VendorId, StoreId, BranchId, BillDate, Amount, Notes, Status, IsActive, CreatedById, CreatedOn)
    VALUES ('CB-HMS-SEED-001', @Vendor2Id, @DisposableStoreId, @BranchId, GETDATE(), 1250, 'Seeded contingent bill', 'Pending', 1, @CreatedById, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.StoreAllocationToUser WHERE StoreId = @MedicineStoreId AND UserId = @CreatedById)
BEGIN
    INSERT INTO Inv.StoreAllocationToUser (StoreId, UserId, BranchId, IsActive, CreatedById, CreatedOn)
    VALUES (@MedicineStoreId, @CreatedById, @BranchId, 1, @CreatedById, GETDATE());
END;

IF NOT EXISTS (SELECT 1 FROM Inv.AssetAllocations WHERE AllocationNumber = 'AA-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.AssetAllocations (ItemId, BranchId, DepartmentId, SubDepartmentId, UserId, RoomId, AllocatedDate, AllocationNumber, SerialNumber, Quantity, Condition, Notes, IsActive, CreatedById, CreatedOn)
    VALUES (@ElectrodeItemId, @BranchId, @DepartmentId, @SubDepartmentId, @CreatedById, @RoomId, GETDATE(), 'AA-HMS-SEED-001', 'SER-HMS-001', 2, 'Good', 'Seeded asset allocation', 1, @CreatedById, GETDATE());
END;

DECLARE @IssuedStatusId INT = (SELECT TOP 1 Id FROM Inv.DemandRequestStatuses WHERE Name = 'Issued' ORDER BY Id);
DECLARE @PendingStatusId INT = (SELECT TOP 1 Id FROM Inv.DemandRequestStatuses WHERE Name = 'Pending' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequests WHERE DemandRequestNumber = 'DR-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.DemandRequests (RequestedToStoreId, RequestingDepartmentId, RequestingStoreId, DemandNotes, DemandRequestStatusId, BranchId, Detail, DemandRequestNumber, IsManual, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, ApprovedDate, IssuedDate, StockTypeId, TotalUnitBuyingPrice, RequestNumber, IndentNumber)
    VALUES (@EmergencyStoreId, @DepartmentId, @MedicineStoreId, 'Seeded issued demand request', @IssuedStatusId, @BranchId, 'Seeded detail', 'DR-HMS-SEED-001', 1, 1, @CreatedById, DATEADD(DAY, -1, GETDATE()), @CreatedById, DATEADD(DAY, -1, GETDATE()), DATEADD(DAY, -1, GETDATE()), DATEADD(HOUR, -12, GETDATE()), @RegularStockTypeId, 640, 'REQ-HMS-SEED-001', 'IND-HMS-SEED-001');
END;

DECLARE @DemandRequest1Id INT = (SELECT TOP 1 Id FROM Inv.DemandRequests WHERE DemandRequestNumber = 'DR-HMS-SEED-001' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestItems WHERE DemandRequestId = @DemandRequest1Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.DemandRequestItems (DemandRequestId, ItemId, RequestedQuantity, ApprovedQuantity, IssuedQuantity, ReceivedQuantity, Notes, IsActive, CreatedOn)
    VALUES
        (@DemandRequest1Id, @SyringeItemId, 40, 35, 30, 0, 'Seeded issued syringe line', 1, DATEADD(DAY, -1, GETDATE())),
        (@DemandRequest1Id, @VaccineItemId, 8, 8, 6, 0, 'Seeded issued vaccine line', 1, DATEADD(DAY, -1, GETDATE()));
END;

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequests WHERE DemandRequestNumber = 'DR-HMS-SEED-002')
BEGIN
    INSERT INTO Inv.DemandRequests (RequestedToStoreId, RequestingDepartmentId, RequestingStoreId, DemandNotes, DemandRequestStatusId, BranchId, Detail, DemandRequestNumber, IsManual, IsActive, CreatedById, CreatedOn, ModifiedById, ModifiedOn, StockTypeId, TotalUnitBuyingPrice, RequestNumber, IndentNumber)
    VALUES (@DisposableStoreId, @DepartmentId, @EmergencyStoreId, 'Seeded pending demand request', @PendingStatusId, @BranchId, 'Seeded pending detail', 'DR-HMS-SEED-002', 1, 1, @CreatedById, GETDATE(), @CreatedById, GETDATE(), @DonationStockTypeId, 220, 'REQ-HMS-SEED-002', 'IND-HMS-SEED-002');
END;

DECLARE @DemandRequest2Id INT = (SELECT TOP 1 Id FROM Inv.DemandRequests WHERE DemandRequestNumber = 'DR-HMS-SEED-002' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.DemandRequestItems WHERE DemandRequestId = @DemandRequest2Id AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.DemandRequestItems (DemandRequestId, ItemId, RequestedQuantity, ApprovedQuantity, IssuedQuantity, ReceivedQuantity, Notes, IsActive, CreatedOn)
    VALUES (@DemandRequest2Id, @ElectrodeItemId, 15, 0, 0, 0, 'Seeded pending electrode line', 1, GETDATE());
END;

PRINT 'Section 2 complete: items, purchase orders, GRN, inventory, racks, transfers, returns, demand requests seeded.';
GO

-- =============================================
-- SECTION 3: Remaining gaps -- Stock Consumption, Stock Audit, Stock (current
-- balance snapshot), Stock Transactions, Stock Transitions.
-- =============================================
SET NOCOUNT ON;

DECLARE @BranchId INT = COALESCE((SELECT TOP 1 Id FROM Inv.Branches WHERE IsActive = 1 ORDER BY Id), 1);
DECLARE @CreatedById INT = COALESCE((SELECT TOP 1 UserID FROM dbo.Users ORDER BY UserID), 1);
DECLARE @MedicineStoreId INT = (SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE StoreName = 'Medicine Store' ORDER BY StoreId);
DECLARE @EmergencyStoreId INT = (SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE StoreName = 'Emergency Store' ORDER BY StoreId);
DECLARE @DisposableStoreId INT = (SELECT TOP 1 StoreId FROM Inv.PharmacyStores WHERE StoreName = 'Main Disposable Store' ORDER BY StoreId);
DECLARE @RegularStockTypeId INT = COALESCE((SELECT TOP 1 Id FROM Inv.StockTypes WHERE Name = 'Regular' ORDER BY Id), (SELECT TOP 1 Id FROM Inv.StockTypes ORDER BY Id));
DECLARE @DonationStockTypeId INT = COALESCE((SELECT TOP 1 Id FROM Inv.StockTypes WHERE Name = 'Donation' ORDER BY Id), @RegularStockTypeId);
DECLARE @SyringeItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed Syringe 10ml' ORDER BY Id);
DECLARE @CannulaItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed IV Cannula 20G' ORDER BY Id);
DECLARE @ElectrodeItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed ECG Electrode' ORDER BY Id);
DECLARE @TubeItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed Test Tube 5ml' ORDER BY Id);
DECLARE @VaccineItemId INT = (SELECT TOP 1 Id FROM Inv.Items WHERE Name = 'HMS Seed Vaccine Vial' ORDER BY Id);
DECLARE @InventoryItemSyringeId2 INT = (SELECT TOP 1 ii.Id FROM Inv.InventoryItems ii WHERE ii.ItemId = @SyringeItemId ORDER BY ii.Id);
DECLARE @DemandRequest2IdForTransition INT = (SELECT TOP 1 Id FROM Inv.DemandRequests WHERE DemandRequestNumber = 'DR-HMS-SEED-002' ORDER BY Id);

-- Stock Consumption
DECLARE @StockConsumption1Id INT;
IF NOT EXISTS (SELECT 1 FROM Inv.StockConsumptions WHERE Remarks = 'Seeded ward consumption batch' AND StoreId = @MedicineStoreId)
BEGIN
    INSERT INTO Inv.StockConsumptions (StoreId, Type, BranchId, IsActive, CreatedById, CreatedOn, IsDeleted, Remarks)
    VALUES (@MedicineStoreId, 1, @BranchId, 1, @CreatedById, DATEADD(DAY, -3, GETDATE()), 0, 'Seeded ward consumption batch');
END;
SET @StockConsumption1Id = (SELECT TOP 1 Id FROM Inv.StockConsumptions WHERE Remarks = 'Seeded ward consumption batch' AND StoreId = @MedicineStoreId ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.StockConsumptionDetails WHERE StockConsumptionId = @StockConsumption1Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.StockConsumptionDetails (StoreId, ItemId, Type, StockTypeId, Quantity, BranchId, InventoryItemId, IsActive, CreatedById, CreatedOn, IsDeleted, StockConsumptionId)
    VALUES (@MedicineStoreId, @SyringeItemId, 1, @RegularStockTypeId, 20, @BranchId, @InventoryItemSyringeId2, 1, @CreatedById, DATEADD(DAY, -3, GETDATE()), 0, @StockConsumption1Id);
END;

DECLARE @StockConsumption2Id INT;
IF NOT EXISTS (SELECT 1 FROM Inv.StockConsumptions WHERE Remarks = 'Seeded emergency ward consumption' AND StoreId = @EmergencyStoreId)
BEGIN
    INSERT INTO Inv.StockConsumptions (StoreId, Type, BranchId, IsActive, CreatedById, CreatedOn, IsDeleted, Remarks)
    VALUES (@EmergencyStoreId, 1, @BranchId, 1, @CreatedById, DATEADD(DAY, -1, GETDATE()), 0, 'Seeded emergency ward consumption');
END;
SET @StockConsumption2Id = (SELECT TOP 1 Id FROM Inv.StockConsumptions WHERE Remarks = 'Seeded emergency ward consumption' AND StoreId = @EmergencyStoreId ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.StockConsumptionDetails WHERE StockConsumptionId = @StockConsumption2Id AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.StockConsumptionDetails (StoreId, ItemId, Type, StockTypeId, Quantity, BranchId, IsActive, CreatedById, CreatedOn, IsDeleted, StockConsumptionId)
    VALUES (@EmergencyStoreId, @ElectrodeItemId, 1, @DonationStockTypeId, 12, @BranchId, 1, @CreatedById, DATEADD(DAY, -1, GETDATE()), 0, @StockConsumption2Id);
END;

-- Stock Audit
DECLARE @StockAudit1Id INT;
IF NOT EXISTS (SELECT 1 FROM Inv.StockAudits WHERE AuditNumber = 'SA-HMS-SEED-001')
BEGIN
    INSERT INTO Inv.StockAudits (AuditNumber, StoreId, BranchId, AuditDate, Notes, Status, IsActive, CreatedById, CreatedOn)
    VALUES ('SA-HMS-SEED-001', @MedicineStoreId, @BranchId, DATEADD(DAY, -2, GETDATE()), 'Seeded quarterly stock audit', 'Completed', 1, @CreatedById, DATEADD(DAY, -2, GETDATE()));
END;
SET @StockAudit1Id = (SELECT TOP 1 Id FROM Inv.StockAudits WHERE AuditNumber = 'SA-HMS-SEED-001' ORDER BY Id);

IF NOT EXISTS (SELECT 1 FROM Inv.StockAuditItems WHERE StockAuditId = @StockAudit1Id AND ItemId = @SyringeItemId)
BEGIN
    INSERT INTO Inv.StockAuditItems (StockAuditId, ItemId, SystemQuantity, PhysicalQuantity, VarianceQuantity, Notes, IsActive, CreatedOn)
    VALUES (@StockAudit1Id, @SyringeItemId, 140, 138, -2, 'Minor variance -- 2 units damaged', 1, DATEADD(DAY, -2, GETDATE()));
END;
IF NOT EXISTS (SELECT 1 FROM Inv.StockAuditItems WHERE StockAuditId = @StockAudit1Id AND ItemId = @CannulaItemId)
BEGIN
    INSERT INTO Inv.StockAuditItems (StockAuditId, ItemId, SystemQuantity, PhysicalQuantity, VarianceQuantity, Notes, IsActive, CreatedOn)
    VALUES (@StockAudit1Id, @CannulaItemId, 48, 48, 0, 'No variance', 1, DATEADD(DAY, -2, GETDATE()));
END;

DECLARE @StockAudit2Id INT;
IF NOT EXISTS (SELECT 1 FROM Inv.StockAudits WHERE AuditNumber = 'SA-HMS-SEED-002')
BEGIN
    INSERT INTO Inv.StockAudits (AuditNumber, StoreId, BranchId, AuditDate, Notes, Status, IsActive, CreatedById, CreatedOn)
    VALUES ('SA-HMS-SEED-002', @EmergencyStoreId, @BranchId, GETDATE(), 'Seeded pending stock audit', 'Pending', 1, @CreatedById, GETDATE());
END;
SET @StockAudit2Id = (SELECT TOP 1 Id FROM Inv.StockAudits WHERE AuditNumber = 'SA-HMS-SEED-002' ORDER BY Id);
IF NOT EXISTS (SELECT 1 FROM Inv.StockAuditItems WHERE StockAuditId = @StockAudit2Id AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.StockAuditItems (StockAuditId, ItemId, SystemQuantity, PhysicalQuantity, VarianceQuantity, Notes, IsActive, CreatedOn)
    VALUES (@StockAudit2Id, @ElectrodeItemId, 88, 85, -3, 'Pending recount', 1, GETDATE());
END;

-- Inv.Stocks (current balance snapshot)
IF NOT EXISTS (SELECT 1 FROM Inv.Stocks WHERE ItemId = @SyringeItemId AND StoreId = @MedicineStoreId)
    INSERT INTO Inv.Stocks (ItemId, TotalItems, MinimumPanicLevel, BranchId, StoreId, IsActive, CreatedById, CreatedOn) VALUES (@SyringeItemId, 138, 25, @BranchId, @MedicineStoreId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.Stocks WHERE ItemId = @CannulaItemId AND StoreId = @MedicineStoreId)
    INSERT INTO Inv.Stocks (ItemId, TotalItems, MinimumPanicLevel, BranchId, StoreId, IsActive, CreatedById, CreatedOn) VALUES (@CannulaItemId, 48, 20, @BranchId, @MedicineStoreId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.Stocks WHERE ItemId = @VaccineItemId AND StoreId = @MedicineStoreId)
    INSERT INTO Inv.Stocks (ItemId, TotalItems, MinimumPanicLevel, BranchId, StoreId, IsActive, CreatedById, CreatedOn) VALUES (@VaccineItemId, 9, 8, @BranchId, @MedicineStoreId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.Stocks WHERE ItemId = @ElectrodeItemId AND StoreId = @EmergencyStoreId)
    INSERT INTO Inv.Stocks (ItemId, TotalItems, MinimumPanicLevel, BranchId, StoreId, IsActive, CreatedById, CreatedOn) VALUES (@ElectrodeItemId, 85, 15, @BranchId, @EmergencyStoreId, 1, @CreatedById, GETDATE());
IF NOT EXISTS (SELECT 1 FROM Inv.Stocks WHERE ItemId = @TubeItemId AND StoreId = @DisposableStoreId)
    INSERT INTO Inv.Stocks (ItemId, TotalItems, MinimumPanicLevel, BranchId, StoreId, IsActive, CreatedById, CreatedOn) VALUES (@TubeItemId, 180, 100, @BranchId, @DisposableStoreId, 1, @CreatedById, GETDATE());

-- Stock Transactions (Stock Flow sidebar item)
IF NOT EXISTS (SELECT 1 FROM Inv.StockTransactions WHERE StoreId = @MedicineStoreId AND ItemId = @SyringeItemId AND TypeBit = 1)
    INSERT INTO Inv.StockTransactions (StoreId, ItemId, OpeningQty, ReceivedQty, IssuedQty, BalanceQty, StockTypeId, BranchId, InventoryItemId, TypeBit, CreatedOn, ModifiedOn, CreatedBy)
    VALUES (@MedicineStoreId, @SyringeItemId, 0, 160, 22, 138, @RegularStockTypeId, @BranchId, @InventoryItemSyringeId2, 1, DATEADD(DAY, -9, GETDATE()), DATEADD(DAY, -1, GETDATE()), @CreatedById);
IF NOT EXISTS (SELECT 1 FROM Inv.StockTransactions WHERE StoreId = @EmergencyStoreId AND ItemId = @ElectrodeItemId AND TypeBit = 1)
    INSERT INTO Inv.StockTransactions (StoreId, ItemId, OpeningQty, ReceivedQty, IssuedQty, BalanceQty, StockTypeId, BranchId, TypeBit, CreatedOn, ModifiedOn, CreatedBy)
    VALUES (@EmergencyStoreId, @ElectrodeItemId, 0, 100, 15, 85, @DonationStockTypeId, @BranchId, 1, DATEADD(DAY, -4, GETDATE()), GETDATE(), @CreatedById);

-- Stock Transitions (Stock Transitions sidebar item -- items in transit for a demand request)
IF @DemandRequest2IdForTransition IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Inv.StockTransitions WHERE DemandRequestId = @DemandRequest2IdForTransition AND ItemId = @ElectrodeItemId)
BEGIN
    INSERT INTO Inv.StockTransitions (DemandRequestId, RequestedStoreId, RequestingStoreId, ItemId, TotalItemsInTransition, TypeBit, StockTypeId, CreatedById, CreatedOn, IsDeleted, IsActive)
    VALUES (@DemandRequest2IdForTransition, @DisposableStoreId, @EmergencyStoreId, @ElectrodeItemId, 15, 1, @DonationStockTypeId, @CreatedById, GETDATE(), 0, 1);
END;

PRINT 'Section 3 complete: stock consumption, stock audit, stock snapshot, stock transactions/transitions seeded.';
GO
