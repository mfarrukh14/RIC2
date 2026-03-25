-- Create GoodsReceivingNotes table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'GoodsReceivingNotes')
BEGIN
    CREATE TABLE dbo.GoodsReceivingNotes (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderId INT,
        InvoiceNo NVARCHAR(100),
        PONumber NVARCHAR(100),
        StockTypeId INT,
        DateAndTime DATETIME,
        VendorInvoiceNo NVARCHAR(100),
        VendorInvoiceDate DATETIME,
        VendorId INT,
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedById INT,
        CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
        ModifiedById INT,
        ModifiedOn DATETIME,
        CONSTRAINT FK_GRN_StockTypes FOREIGN KEY (StockTypeId) REFERENCES StockTypes(StockTypeId),
        CONSTRAINT FK_GRN_Vendors FOREIGN KEY (VendorId) REFERENCES Vendors(Id)
    );
    PRINT 'GoodsReceivingNotes table created successfully';
END
ELSE
BEGIN
    PRINT 'GoodsReceivingNotes table already exists';
END
GO

-- Create GRNItems table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'GRNItems')
BEGIN
    CREATE TABLE dbo.GRNItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        GRNId INT NOT NULL,
        ItemId INT NOT NULL,
        ManufacturerId INT,
        MfgDate DATETIME,
        ExpiryDate DATETIME,
        RegistrationNumber NVARCHAR(100),
        LotNo NVARCHAR(100),
        BatchNo NVARCHAR(100),
        NoOfBoxes INT,
        NoOfPackets INT,
        ItemPerPacket INT,
        TotalItem INT,
        PackQuantity INT,
        ReceivedQuantity INT,
        RemainingQuantity INT,
        TotalBuyingPrice DECIMAL(18,2),
        UnitBuyingPrice DECIMAL(18,2),
        AdvanceTaxPercentage DECIMAL(18,2),
        AdvanceTaxAmount DECIMAL(18,2),
        Discount BIT DEFAULT 0,
        DiscountAmount DECIMAL(18,2),
        RetailCharges BIT DEFAULT 0,
        RetailChargesAmount DECIMAL(18,2),
        GSTCharges BIT DEFAULT 0,
        GSTChargesAmount DECIMAL(18,2),
        UnitSellingPrice DECIMAL(18,2),
        TotalSellingPrice DECIMAL(18,2),
        ProfitMarginPerItem DECIMAL(18,2),
        ProfitPerItem DECIMAL(18,2),
        CONSTRAINT FK_GRNItems_GRN FOREIGN KEY (GRNId) REFERENCES GoodsReceivingNotes(Id),
        CONSTRAINT FK_GRNItems_Items FOREIGN KEY (ItemId) REFERENCES Items(Id),
        CONSTRAINT FK_GRNItems_Manufacturers FOREIGN KEY (ManufacturerId) REFERENCES Manufacturers(Id)
    );
    PRINT 'GRNItems table created successfully';
END
ELSE
BEGIN
    PRINT 'GRNItems table already exists';
END
GO
