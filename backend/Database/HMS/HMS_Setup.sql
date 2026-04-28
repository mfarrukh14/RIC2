-- =============================================
-- HMS Database Setup for Store/Inventory Module
-- Creates compatibility views for HMS lookup tables
-- and missing tables in Inv schema
-- =============================================

-- Ensure Inv schema exists
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Inv')
    EXEC('CREATE SCHEMA Inv');
GO

-- =============================================
-- PHASE 1: Compatibility Views
-- These present HMS tables with column names
-- the store module stored procedures expect
-- =============================================

-- Countries view
IF OBJECT_ID('Inv.Countries', 'V') IS NOT NULL DROP VIEW Inv.Countries;
GO
CREATE VIEW Inv.Countries AS
SELECT 
    ID AS Id,
    Name,
    Code,
    CAST(CASE WHEN Status IS NULL OR Status = 1 THEN 1 ELSE 0 END AS BIT) AS IsActive,
    CreatedOn,
    ModifiedOn
FROM dbo.Countries;
GO

-- StateOrProvinces view (HMS uses dbo.Provinces)
IF OBJECT_ID('Inv.StateOrProvinces', 'V') IS NOT NULL DROP VIEW Inv.StateOrProvinces;
GO
CREATE VIEW Inv.StateOrProvinces AS
SELECT 
    ID AS Id,
    Name,
    CountryID AS CountryId,
    Code,
    CAST(CASE WHEN Status IS NULL OR Status = 1 THEN 1 ELSE 0 END AS BIT) AS IsActive,
    CreatedOn,
    ModifiedOn
FROM dbo.Provinces;
GO

-- Cities view
IF OBJECT_ID('Inv.Cities', 'V') IS NOT NULL DROP VIEW Inv.Cities;
GO
CREATE VIEW Inv.Cities AS
SELECT 
    ID AS Id,
    Name,
    ProvinceID AS StateOrProvinceId,
    CAST(CASE WHEN Status IS NULL OR Status = 1 THEN 1 ELSE 0 END AS BIT) AS IsActive,
    CreatedOn,
    ModifiedOn
FROM dbo.Cities;
GO

-- Branches view (HMS uses dbo.Branch)
IF OBJECT_ID('Inv.Branches', 'V') IS NOT NULL DROP VIEW Inv.Branches;
GO
CREATE VIEW Inv.Branches AS
SELECT 
    BranchId AS Id,
    BranchName AS Name,
    Code,
    Address,
    CityId,
    ISNULL(IsActive, CAST(1 AS BIT)) AS IsActive,
    CreatedOn,
    UpdatedOn AS ModifiedOn
FROM dbo.Branch;
GO

-- Departments view
IF OBJECT_ID('Inv.Departments', 'V') IS NOT NULL DROP VIEW Inv.Departments;
GO
CREATE VIEW Inv.Departments AS
SELECT 
    DID AS Id,
    Name,
    Description,
    CAST(NULL AS NVARCHAR(200)) AS Head,
    ISNULL(IsActive, CAST(1 AS BIT)) AS IsActive
FROM dbo.Departments;
GO

-- SubDepartments view
IF OBJECT_ID('Inv.SubDepartments', 'V') IS NOT NULL DROP VIEW Inv.SubDepartments;
GO
CREATE VIEW Inv.SubDepartments AS
SELECT 
    SubDID AS Id,
    Name,
    Description,
    DID AS DepartmentId,
    ISNULL(IsActive, CAST(1 AS BIT)) AS IsActive
FROM dbo.SubDepartments;
GO

-- StoreUsers view (HMS uses dbo.Users)
IF OBJECT_ID('Inv.StoreUsers', 'V') IS NOT NULL DROP VIEW Inv.StoreUsers;
GO
CREATE VIEW Inv.StoreUsers AS
SELECT 
    UserID AS Id,
    ISNULL(UserName, '') AS Name,
    CAST(NULL AS NVARCHAR(200)) AS Email,
    UserName,
    CAST(NULL AS NVARCHAR(200)) AS Department,
    CAST(NULL AS NVARCHAR(200)) AS Designation,
    CAST(CASE WHEN Status IS NULL OR Status = 1 THEN 1 ELSE 0 END AS BIT) AS IsActive
FROM dbo.Users;
GO

-- Rooms view
IF OBJECT_ID('Inv.Rooms', 'V') IS NOT NULL DROP VIEW Inv.Rooms;
GO
CREATE VIEW Inv.Rooms AS
SELECT 
    RID AS Id,
    Name,
    Description,
    CAST(NULL AS NVARCHAR(200)) AS Floor,
    CAST(NULL AS NVARCHAR(200)) AS Building,
    Capacity,
    ISNULL(IsActive, CAST(1 AS BIT)) AS IsActive
FROM dbo.Rooms;
GO

-- =============================================
-- PHASE 2: Create missing tables in Inv schema
-- Only creates tables that do NOT already exist
-- =============================================

-- Vendors table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Vendors' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Vendors (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        Email NVARCHAR(MAX) NULL,
        CNo NVARCHAR(MAX) NULL,
        Address NVARCHAR(MAX) NULL,
        NTN NVARCHAR(MAX) NULL,
        STN NVARCHAR(MAX) NULL,
        CPName1 NVARCHAR(MAX) NULL,
        CPEmail1 NVARCHAR(MAX) NULL,
        CPContactNumber1 NVARCHAR(MAX) NULL,
        CPName2 NVARCHAR(MAX) NULL,
        CPEmail2 NVARCHAR(MAX) NULL,
        CPContactNumber2 NVARCHAR(MAX) NULL,
        CountryId INT NULL,
        StateOrProvinceId INT NULL,
        CityId INT NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL,
        Code NVARCHAR(MAX) NULL,
        VendorOrCustomer INT NULL,
        IncomeTaxStatus INT NULL,
        VendorType INT NULL,
        TaxPayerCategoryId INT NULL,
        TaxPayerStatus INT NULL,
        SaleTaxType INT NULL,
        ExemptUnderSRO NVARCHAR(MAX) NULL,
        AccountPayableId INT NULL,
        AccountReceivableId INT NULL,
        CreditStatus INT NULL,
        NetDueDays INT NULL,
        CreditLimit INT NULL,
        FaxNo NVARCHAR(MAX) NULL,
        IsVerified BIT DEFAULT 0
    );
    PRINT 'Created Inv.Vendors';
END
GO

-- Manufacturers table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Manufacturers' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Manufacturers (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        Email NVARCHAR(MAX) NULL,
        Address NVARCHAR(MAX) NULL,
        CNo NVARCHAR(MAX) NULL,
        NTN NVARCHAR(MAX) NULL,
        STN NVARCHAR(MAX) NULL,
        CPName1 NVARCHAR(MAX) NULL,
        CPEmail1 NVARCHAR(MAX) NULL,
        CPContactNumber1 NVARCHAR(MAX) NULL,
        CPName2 NVARCHAR(MAX) NULL,
        CPEmail2 NVARCHAR(MAX) NULL,
        CPContactNumber2 NVARCHAR(MAX) NULL,
        CountryId INT NULL,
        StateOrProvinceId INT NULL,
        CityId INT NULL,
        BranchId INT NULL,
        RegisteredOwner NVARCHAR(MAX) NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.Manufacturers';
END
GO

-- Brands table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Brands' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Brands (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.Brands';
END
GO

-- ItemTypes table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemTypes' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ItemTypes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.ItemTypes';
END
GO

-- ItemUnits table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemUnits' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ItemUnits (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Symbol NVARCHAR(50) NULL,
        Description NVARCHAR(MAX) NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.ItemUnits';
END
GO

-- Packings table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Packings' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Packings (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.Packings';
END
GO

-- Categories table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categories' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Categories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.Categories';
END
GO

-- SubCategories table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SubCategories' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.SubCategories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        CategoryId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.SubCategories';
END
GO

-- Prices table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Prices' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Prices (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        RetailPrice DECIMAL(18,4) DEFAULT 0,
        SalePrice DECIMAL(18,4) DEFAULT 0,
        MarketPrice DECIMAL(18,4) DEFAULT 0,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.Prices';
END
GO

-- TaxRates table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TaxRates' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TaxRates (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Rate DECIMAL(5,2) NOT NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.TaxRates';
END
GO

-- TaxDescriptions table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TaxDescriptions' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TaxDescriptions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.TaxDescriptions';
END
GO

-- TaxTypes table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TaxTypes' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TaxTypes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.TaxTypes';
END
GO

-- TaxPayerCategories table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TaxPayerCategories' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TaxPayerCategories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Code NVARCHAR(20) NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.TaxPayerCategories';
END
GO

-- AccountCOAs table (Chart of Accounts)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AccountCOAs' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.AccountCOAs (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Code NVARCHAR(20) NULL,
        AccountType NVARCHAR(50) NULL,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.AccountCOAs';
END
GO

-- Stores table (store module specific - different from Pharmacy.PharmacyStores)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Stores' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Stores (
        StoreId INT IDENTITY(1,1) PRIMARY KEY,
        StoreName NVARCHAR(200) NOT NULL,
        StoreCode NVARCHAR(50) NULL,
        Description NVARCHAR(500) NULL,
        StoreType NVARCHAR(50) NULL,
        ReceiptType NVARCHAR(50) NULL,
        POSType NVARCHAR(50) NULL,
        ParentStoreId INT NULL,
        BuildingId INT NULL,
        FloorId INT NULL,
        RoomId INT NULL,
        Email NVARCHAR(200) NULL,
        CellNumber NVARCHAR(50) NULL,
        QueuePatientCallStatusValue NVARCHAR(100) NULL,
        MarkTokenAsAutoCollectedOnDispense BIT NULL,
        DisplayRequestsWithoutTokenIssued BIT NULL,
        EnglishNote NVARCHAR(MAX) NULL,
        UrduNote NVARCHAR(MAX) NULL,
        ServiceCharges BIT NULL,
        GST BIT NULL,
        PricingType NVARCHAR(50) NULL,
        DisableRetailSale BIT NULL,
        GSTN NVARCHAR(50) NULL,
        NTN NVARCHAR(50) NULL,
        DayClosing NVARCHAR(50) NULL,
        ClosingCashAccountId INT NULL,
        ClosingRevenueAccountId INT NULL,
        ClosingInventoryAccountId INT NULL,
        ClosingInventoryExpenseAccountId INT NULL,
        ClosingTaxExpenseAccountId INT NULL,
        PayableAccountId INT NULL,
        AdvanceTaxPercentageAccountId INT NULL,
        RevenueDiscountAccountId INT NULL,
        Address NVARCHAR(500) NULL,
        Latitude NVARCHAR(50) NULL,
        Longitude NVARCHAR(50) NULL,
        Country NVARCHAR(100) NULL,
        StateOrProvince NVARCHAR(100) NULL,
        City NVARCHAR(100) NULL,
        StoreImage NVARCHAR(500) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.Stores';
END
GO

-- Inventories table (GRN header)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Inventories' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Inventories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderNumber NVARCHAR(MAX) NULL,
        InvoiceNo NVARCHAR(MAX) NULL,
        PurchaseOrderId INT NULL,
        VendorId INT NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL,
        IsFinalized BIT NULL,
        StockTypeId INT NULL,
        VendorInvoiceNumber NVARCHAR(MAX) NULL,
        VendorInvoiceTimestamp DATETIME NULL,
        Amount REAL NULL,
        Discount REAL NULL,
        DiscountType INT NULL,
        Total REAL NULL,
        PaidAmount REAL NULL,
        PaymentStatusId INT NULL,
        TotalPaidAmount REAL NULL,
        PayableAccountId INT NULL,
        IsPaymentPending BIT NULL,
        VoucherId INT NULL,
        TotalVoucherPaidAmount REAL NULL,
        TotalBuyingPrice REAL NULL,
        ReceiptPath NVARCHAR(MAX) NULL,
        AdvanceTaxPercentage REAL NULL,
        AdvanceTaxCalculatedAmount REAL NULL,
        RetailCharges REAL NULL,
        RetailChargesType INT NULL,
        GSTCharges REAL NULL,
        RetailChargesCalculatedAmount REAL NULL,
        GSTChargesCalculatedAmount REAL NULL,
        ManualPurchaseOrderNumber NVARCHAR(MAX) NULL
    );
    PRINT 'Created Inv.Inventories';
END
GO

-- InventoryDetails table (GRN line items)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'InventoryDetails' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.InventoryDetails (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        InventoryId INT NOT NULL,
        ItemId INT NOT NULL,
        ManufacturerId INT NULL,
        MfgDate DATETIME NULL,
        ExpiryDate DATETIME NULL,
        NoOfBoxes INT NULL,
        NoOfPackets INT NULL,
        ItemsPerPacket INT NULL,
        TotalItems INT NULL,
        PackQuantity INT NULL,
        UnitBuyingPrice REAL NULL,
        TotalBuyingPrice REAL NULL,
        AdvanceTaxPercentage REAL NULL,
        AdvanceTaxAmount REAL NULL,
        Discount BIT NULL,
        DiscountAmount REAL NULL,
        RetailCharges BIT NULL,
        RetailChargesAmount REAL NULL,
        GSTCharges BIT NULL,
        GSTChargesAmount REAL NULL,
        UnitSellingPrice REAL NULL,
        TotalSellingPrice REAL NULL,
        ProfitMarginPerItem REAL NULL,
        ProfitPerItem REAL NULL
    );
    PRINT 'Created Inv.InventoryDetails';
END
GO

-- Stocks table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Stocks' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.Stocks (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ItemId INT NULL,
        TotalItems INT NULL,
        MinimumPanicLevel INT NULL,
        BranchId INT NULL,
        StoreId INT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.Stocks';
END
GO

-- PurchaseOrders table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrders' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseOrders (
        PurchaseOrderId INT IDENTITY(1,1) PRIMARY KEY,
        PONumber NVARCHAR(50) NOT NULL,
        ManualPONumber NVARCHAR(100) NULL,
        StoreId INT NOT NULL,
        VendorId INT NOT NULL,
        POValidityDate DATETIME2 NULL,
        Subject NVARCHAR(500) NULL,
        Instructions NVARCHAR(MAX) NULL,
        TermsAndConditions NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) NOT NULL DEFAULT 'Pending',
        TotalQuantity DECIMAL(18,2) NOT NULL DEFAULT 0,
        TotalAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL,
        CONSTRAINT UQ_Inv_PurchaseOrders_PONumber UNIQUE (PONumber)
    );
    PRINT 'Created Inv.PurchaseOrders';
END
GO

-- PurchaseOrderItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrderItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseOrderItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderId INT NOT NULL,
        ItemId INT NOT NULL,
        ItemType NVARCHAR(50) NULL,
        PacketQuantity DECIMAL(18,2) NULL,
        UnitQuantity DECIMAL(18,2) NOT NULL,
        PacketPrice DECIMAL(18,2) NULL,
        UnitPrice DECIMAL(18,2) NOT NULL,
        TotalPrice DECIMAL(18,2) NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL
    );
    PRINT 'Created Inv.PurchaseOrderItems';
END
GO

-- PurchaseOrderTypes table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrderTypes' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseOrderTypes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById NVARCHAR(450) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById NVARCHAR(450) NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.PurchaseOrderTypes';
END
GO

-- PurchaseOrderStatus table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrderStatus' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseOrderStatus (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderId INT NOT NULL,
        Status NVARCHAR(50) NOT NULL,
        Notes NVARCHAR(MAX) NULL,
        CreatedById INT NULL,
        CreatedOn DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
    );
    PRINT 'Created Inv.PurchaseOrderStatus';
END
GO

-- PurchaseOrderStatusItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseOrderStatusItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseOrderStatusItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderStatusId INT NOT NULL,
        ItemId INT NOT NULL,
        ReceivedQuantity DECIMAL(18,2) NULL,
        RemainingQuantity DECIMAL(18,2) NULL,
        Notes NVARCHAR(MAX) NULL
    );
    PRINT 'Created Inv.PurchaseOrderStatusItems';
END
GO

-- FinancialYears table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'FinancialYears' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.FinancialYears (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        StartDate DATETIME NOT NULL,
        EndDate DATETIME NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById NVARCHAR(450) NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById NVARCHAR(450) NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.FinancialYears';
END
GO

-- StockConsumptions table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockConsumptions' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockConsumptions (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ConsumptionNumber NVARCHAR(50) NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        DepartmentId INT NULL,
        ConsumptionDate DATETIME NOT NULL DEFAULT GETDATE(),
        Notes NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.StockConsumptions';
END
GO

-- StockConsumptionDetails table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockConsumptionDetails' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockConsumptionDetails (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StockConsumptionId INT NOT NULL,
        ItemId INT NOT NULL,
        Quantity INT NOT NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.StockConsumptionDetails';
END
GO

-- StockAdjustments table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAdjustments' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockAdjustments (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        AdjustmentNumber NVARCHAR(50) NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        AdjustmentDate DATETIME NOT NULL DEFAULT GETDATE(),
        Reason NVARCHAR(MAX) NULL,
        Notes NVARCHAR(MAX) NULL,
        AdjustmentType NVARCHAR(50) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.StockAdjustments';
END
GO

-- StockAdjustmentDetails table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAdjustmentDetails' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockAdjustmentDetails (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StockAdjustmentId INT NOT NULL,
        ItemId INT NOT NULL,
        CurrentQuantity INT NULL,
        AdjustedQuantity INT NOT NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.StockAdjustmentDetails';
END
GO

-- StockAudits table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAudits' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockAudits (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        AuditNumber NVARCHAR(50) NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        AuditDate DATETIME NOT NULL DEFAULT GETDATE(),
        Notes NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.StockAudits';
END
GO

-- StockAuditItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockAuditItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockAuditItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StockAuditId INT NOT NULL,
        ItemId INT NOT NULL,
        SystemQuantity INT NULL,
        PhysicalQuantity INT NOT NULL,
        VarianceQuantity INT NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.StockAuditItems';
END
GO

-- TransferInventory table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TransferInventory' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TransferInventory (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        TransferNumber NVARCHAR(50) NULL,
        FromStoreId INT NOT NULL,
        ToStoreId INT NOT NULL,
        BranchId INT NOT NULL,
        TransferDate DATETIME NOT NULL DEFAULT GETDATE(),
        Notes NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.TransferInventory';
END
GO

-- TransferInventoryItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'TransferInventoryItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.TransferInventoryItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        TransferInventoryId INT NOT NULL,
        ItemId INT NOT NULL,
        Quantity INT NOT NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.TransferInventoryItems';
END
GO

-- ReturnInventory table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ReturnInventory' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ReturnInventory (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ReturnNumber NVARCHAR(50) NULL,
        VendorId INT NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        ReturnDate DATETIME NOT NULL DEFAULT GETDATE(),
        Reason NVARCHAR(MAX) NULL,
        Notes NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.ReturnInventory';
END
GO

-- ReturnInventoryItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ReturnInventoryItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ReturnInventoryItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ReturnInventoryId INT NOT NULL,
        ItemId INT NOT NULL,
        Quantity INT NOT NULL,
        Reason NVARCHAR(MAX) NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.ReturnInventoryItems';
END
GO

-- ContingentBills table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ContingentBills' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ContingentBills (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        BillNumber NVARCHAR(50) NULL,
        VendorId INT NULL,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        BillDate DATETIME NOT NULL DEFAULT GETDATE(),
        Amount DECIMAL(18,2) NULL,
        Notes NVARCHAR(MAX) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.ContingentBills';
END
GO

-- AssetAllocations table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AssetAllocations' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.AssetAllocations (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ItemId INT NOT NULL,
        BranchId INT NULL,
        DepartmentId INT NULL,
        SubDepartmentId INT NULL,
        UserId INT NULL,
        RoomId INT NULL,
        AllocatedDate DATETIME NULL DEFAULT GETDATE(),
        AllocationNumber NVARCHAR(50) NULL,
        SerialNumber NVARCHAR(100) NULL,
        Quantity INT NOT NULL DEFAULT 1,
        Condition NVARCHAR(50) NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.AssetAllocations';
END
GO

-- StoreAllocationToUser table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StoreAllocationToUser' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StoreAllocationToUser (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StoreId INT NOT NULL,
        UserId INT NOT NULL,
        BranchId INT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.StoreAllocationToUser';
END
GO

-- ItemTypeSaleLevels table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemTypeSaleLevels' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ItemTypeSaleLevels (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ItemTypeId INT NULL,
        FastRunningLevel INT NOT NULL DEFAULT 0,
        SlowMovingLevel INT NOT NULL DEFAULT 0,
        DeadLevel INT NOT NULL DEFAULT 0,
        BranchId INT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.ItemTypeSaleLevels';
END
GO

-- StockTypeAssociations table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockTypeAssociations' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.StockTypeAssociations (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StoreId INT NOT NULL,
        StockTypeId INT NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.StockTypeAssociations';
END
GO

-- ItemCategories table (linking items to categories for stores)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ItemCategories' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.ItemCategories (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        ItemId INT NOT NULL,
        CategoryId INT NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.ItemCategories';
END
GO

-- PurchaseSummaries table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseSummaries' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseSummaries (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        StoreId INT NOT NULL,
        BranchId INT NOT NULL,
        VendorId INT NULL,
        SummaryDate DATETIME NOT NULL DEFAULT GETDATE(),
        TotalAmount DECIMAL(18,2) NULL,
        Status NVARCHAR(50) DEFAULT 'Pending',
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME NULL
    );
    PRINT 'Created Inv.PurchaseSummaries';
END
GO

-- PurchaseSummaryInvoices table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PurchaseSummaryInvoices' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.PurchaseSummaryInvoices (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseSummaryId INT NOT NULL,
        InvoiceNumber NVARCHAR(100) NULL,
        InvoiceDate DATETIME NULL,
        Amount DECIMAL(18,2) NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.PurchaseSummaryInvoices';
END
GO

-- =============================================
-- PHASE 3: Add missing columns to existing Inv tables
-- =============================================

-- Add missing columns to Inv.Items if they don't exist
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Items' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'IsConsumptionItem')
        ALTER TABLE Inv.Items ADD IsConsumptionItem BIT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'IsHidePanicFromBill')
        ALTER TABLE Inv.Items ADD IsHidePanicFromBill BIT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'SaleUnitId')
        ALTER TABLE Inv.Items ADD SaleUnitId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'TaxRateId')
        ALTER TABLE Inv.Items ADD TaxRateId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'TaxDescriptionId')
        ALTER TABLE Inv.Items ADD TaxDescriptionId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'SalesAccountId')
        ALTER TABLE Inv.Items ADD SalesAccountId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'InventoryAccountId')
        ALTER TABLE Inv.Items ADD InventoryAccountId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'ExpenseAccountId')
        ALTER TABLE Inv.Items ADD ExpenseAccountId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'Frequency')
        ALTER TABLE Inv.Items ADD Frequency INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'IsProduct')
        ALTER TABLE Inv.Items ADD IsProduct BIT NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'BatchExpiryRequired')
        ALTER TABLE Inv.Items ADD BatchExpiryRequired BIT NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'DescriptionForSale')
        ALTER TABLE Inv.Items ADD DescriptionForSale NVARCHAR(MAX) NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'Conversion')
        ALTER TABLE Inv.Items ADD Conversion DECIMAL(18,2) NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'CaseContains')
        ALTER TABLE Inv.Items ADD CaseContains INT NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'SalePrice')
        ALTER TABLE Inv.Items ADD SalePrice DECIMAL(18,2) NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'CostMethod')
        ALTER TABLE Inv.Items ADD CostMethod INT NOT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'PriceId')
        ALTER TABLE Inv.Items ADD PriceId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'ItemTypeId')
        ALTER TABLE Inv.Items ADD ItemTypeId INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'MinimumOrderPrice')
        ALTER TABLE Inv.Items ADD MinimumOrderPrice DECIMAL(18,2) NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'MinimumOrderQuantity')
        ALTER TABLE Inv.Items ADD MinimumOrderQuantity DECIMAL(18,2) NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Items') AND name = 'StripPerPacket')
        ALTER TABLE Inv.Items ADD StripPerPacket REAL NULL;
    PRINT 'Added missing columns to Inv.Items';
END
GO

-- Add missing columns to Inv.Racks if needed
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Racks' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.Racks') AND name = 'Location')
        ALTER TABLE Inv.Racks ADD Location NVARCHAR(MAX) NULL;
    PRINT 'Verified Inv.Racks columns';
END
GO

-- Add missing columns to Inv.StockTypes if needed (HMS has Id/Name/Description only)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'StockTypes' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'IsActive')
        ALTER TABLE Inv.StockTypes ADD IsActive BIT NOT NULL DEFAULT 1;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'IsDeleted')
        ALTER TABLE Inv.StockTypes ADD IsDeleted BIT NULL DEFAULT 0;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'CreatedById')
        ALTER TABLE Inv.StockTypes ADD CreatedById INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'CreatedOn')
        ALTER TABLE Inv.StockTypes ADD CreatedOn DATETIME NULL DEFAULT GETDATE();
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'ModifiedById')
        ALTER TABLE Inv.StockTypes ADD ModifiedById INT NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.StockTypes') AND name = 'ModifiedOn')
        ALTER TABLE Inv.StockTypes ADD ModifiedOn DATETIME NULL;
    PRINT 'Verified Inv.StockTypes columns';
END
GO

-- Add missing columns to Inv.SpaceAllocations if needed 
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SpaceAllocations' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.SpaceAllocations') AND name = 'BranchId')
        ALTER TABLE Inv.SpaceAllocations ADD BranchId INT NULL;
    PRINT 'Verified Inv.SpaceAllocations columns';
END
GO

-- Add missing columns to Inv.DemandRequests if needed
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'DemandRequests' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.DemandRequests') AND name = 'RequestNumber')
        ALTER TABLE Inv.DemandRequests ADD RequestNumber NVARCHAR(MAX) NULL;
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Inv.DemandRequests') AND name = 'IndentNumber')
        ALTER TABLE Inv.DemandRequests ADD IndentNumber NVARCHAR(MAX) NULL;
    PRINT 'Verified Inv.DemandRequests columns';
END
GO

-- DemandRequestItems table (for demand request line items)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DemandRequestItems' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.DemandRequestItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        DemandRequestId INT NOT NULL,
        ItemId INT NOT NULL,
        RequestedQuantity INT NOT NULL DEFAULT 0,
        ApprovedQuantity INT NULL,
        IssuedQuantity INT NULL,
        ReceivedQuantity INT NULL,
        Notes NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.DemandRequestItems';
END
GO

-- SurgicalItemGroups (reference view to Data.SurgicalItemGroups)
-- Already exists in Data schema, no need to create

-- SampleCollectionConsumptionItems (reference view to Lab.SampleCollectionConsumptionItems)
-- Already exists in Lab schema, no need to create

-- EstimatedPurchaseOrders table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EstimatedPurchaseOrders' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.EstimatedPurchaseOrders (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.EstimatedPurchaseOrders';
END
GO

-- DemandWiseValues table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'DemandWiseValues' AND schema_id = SCHEMA_ID('Inv'))
BEGIN
    CREATE TABLE Inv.DemandWiseValues (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Value INT NOT NULL DEFAULT 0,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE()
    );
    PRINT 'Created Inv.DemandWiseValues';
END
GO

PRINT '====================================';
PRINT 'HMS Setup completed successfully!';
PRINT '====================================';
GO
