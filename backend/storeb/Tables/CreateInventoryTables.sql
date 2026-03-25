-- =============================================
-- Create Inventories Table (Main GRN Table)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Inventories')
BEGIN
    CREATE TABLE [dbo].[Inventories] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [PurchaseOrderNumber] NVARCHAR(MAX),
        [InvoiceNo] NVARCHAR(MAX),
        [PurchaseOrderId] INT,
        [VendorId] INT,
        [StoreId] INT NOT NULL,
        [BranchId] INT NOT NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedById] INT,
        [CreatedOn] DATETIME NOT NULL DEFAULT GETDATE(),
        [ModifiedById] INT,
        [ModifiedOn] DATETIME,
        [IsFinalized] BIT,
        [StockTypeId] INT,
        [VendorInvoiceNumber] NVARCHAR(MAX),
        [VendorInvoiceTimestamp] DATETIME,
        [Amount] REAL,
        [Discount] REAL,
        [DiscountType] INT,
        [Total] REAL,
        [PaidAmount] REAL,
        [PaymentStatusId] INT,
        [TotalPaidAmount] REAL,
        [PayableAccountId] INT,
        [IsPaymentPending] BIT,
        [VoucherId] INT,
        [TotalVoucherPaidAmount] REAL,
        [TotalBuyingPrice] REAL,
        [ReceiptPath] NVARCHAR(MAX),
        [AdvanceTaxPercentage] REAL,
        [AdvanceTaxCalculatedAmount] REAL,
        [RetailCharges] REAL,
        [RetailChargesType] INT,
        [GSTCharges] REAL,
        [RetailChargesCalculatedAmount] REAL,
        [GSTChargesCalculatedAmount] REAL,
        [ManualPurchaseOrderNumber] NVARCHAR(MAX),
        
        -- Foreign Keys
        CONSTRAINT [FK_Inventories_Branches] FOREIGN KEY ([BranchId]) REFERENCES [dbo].[Branches]([Id]),
        CONSTRAINT [FK_Inventories_Stores] FOREIGN KEY ([StoreId]) REFERENCES [dbo].[Stores]([StoreId]),
        CONSTRAINT [FK_Inventories_Vendors] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendors]([Id]),
        CONSTRAINT [FK_Inventories_StockTypes] FOREIGN KEY ([StockTypeId]) REFERENCES [dbo].[StockTypes]([StockTypeId])
    );
    
    PRINT 'Inventories table created successfully';
END
ELSE
BEGIN
    PRINT 'Inventories table already exists';
END
GO

-- =============================================
-- Create InventoryDetails Table (GRN Line Items)
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'InventoryDetails')
BEGIN
    CREATE TABLE [dbo].[InventoryDetails] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [InventoryId] INT NOT NULL,
        [ItemId] INT NOT NULL,
        [ManufacturerId] INT,
        [MfgDate] DATETIME,
        [ExpiryDate] DATETIME,
        [NoOfBoxes] INT,
        [NoOfPackets] INT,
        [ItemsPerPacket] INT,
        [TotalItems] INT,
        [PackQuantity] INT,
        [UnitBuyingPrice] REAL,
        [TotalBuyingPrice] REAL,
        [AdvanceTaxPercentage] REAL,
        [AdvanceTaxAmount] REAL,
        [Discount] BIT,
        [DiscountAmount] REAL,
        [RetailCharges] BIT,
        [RetailChargesAmount] REAL,
        [GSTCharges] BIT,
        [GSTChargesAmount] REAL,
        [UnitSellingPrice] REAL,
        [TotalSellingPrice] REAL,
        [ProfitMarginPerItem] REAL,
        [ProfitPerItem] REAL,
        
        -- Foreign Keys
        CONSTRAINT [FK_InventoryDetails_Inventories] FOREIGN KEY ([InventoryId]) REFERENCES [dbo].[Inventories]([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_InventoryDetails_Items] FOREIGN KEY ([ItemId]) REFERENCES [dbo].[Items]([Id]),
        CONSTRAINT [FK_InventoryDetails_Manufacturers] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturers]([Id])
    );
    
    PRINT 'InventoryDetails table created successfully';
END
ELSE
BEGIN
    PRINT 'InventoryDetails table already exists';
END
GO

-- =============================================
-- Create StockTypes Table if not exists
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StockTypes')
BEGIN
    CREATE TABLE [dbo].[StockTypes] (
        [StockTypeId] INT IDENTITY(1,1) PRIMARY KEY,
        [StockTypeName] NVARCHAR(100) NOT NULL,
        [Description] NVARCHAR(500),
        [IsActive] BIT NOT NULL DEFAULT 1
    );
    
    -- Insert default stock types
    INSERT INTO [dbo].[StockTypes] ([StockTypeName], [Description], [IsActive])
    VALUES 
        ('Regular', 'Regular stock type', 1),
        ('Consignment', 'Consignment stock', 1),
        ('Sample', 'Sample stock', 1);
    
    PRINT 'StockTypes table created successfully with sample data';
END
ELSE
BEGIN
    PRINT 'StockTypes table already exists';
END
GO

-- =============================================
-- Create Stores Table if not exists
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Stores')
BEGIN
    CREATE TABLE [dbo].[Stores] (
        [StoreId] INT IDENTITY(1,1) PRIMARY KEY,
        [StoreName] NVARCHAR(200) NOT NULL,
        [StoreCode] NVARCHAR(50),
        [Description] NVARCHAR(500),
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedOn] DATETIME DEFAULT GETDATE(),
        [ModifiedOn] DATETIME
    );
    
    -- Insert default store
    INSERT INTO [dbo].[Stores] ([StoreName], [StoreCode], [Description], [IsActive])
    VALUES ('Academic Affair Store', 'AAS', 'Main Academic Affairs Store', 1);
    
    PRINT 'Stores table created successfully with sample data';
END
ELSE
BEGIN
    PRINT 'Stores table already exists';
END
GO

-- =============================================
-- Create Branches Table if not exists
-- =============================================
-- Branches table already exists, skip creation
PRINT 'Branches table already exists (managed separately)'
GO
