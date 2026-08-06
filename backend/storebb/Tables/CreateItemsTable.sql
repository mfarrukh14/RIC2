-- =============================================
-- Create Items Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Items')
BEGIN
    CREATE TABLE [dbo].[Items] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [Name] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX),
        [Model] NVARCHAR(100),
        [BarCode] NVARCHAR(100),
        [Specification] NVARCHAR(500),
        [ItemTypeId] INT,
        [BrandId] INT,
        [PackingId] INT,
        [UnitId] INT,
        [PriceId] INT,
        [CategoryId] INT,
        [SubCategoryId] INT,
        [Frequency] INT,
        [IsProduct] BIT,
        [BatchExpiryRequired] BIT,
        [DescriptionForSale] NVARCHAR(MAX),
        [SaleUnitId] INT,
        [Conversion] DECIMAL(18, 2),
        [CaseContains] NVARCHAR(100),
        [HSCode] NVARCHAR(50),
        [RetailPrice] DECIMAL(18, 2),
        [CostMethod] INT,
        [SalesAccountId] INT,
        [InventoryAccountId] INT,
        [ExpenseAccountId] INT,
        [TaxRateId] INT,
        [TaxDescriptionId] INT,
        [TaxTypeId] INT,
        [Colour] NVARCHAR(50),
        [MinimumPanicLevel] FLOAT,
        [IsHidePanicFromBill] BIT,
        [QuantityPerPacket] FLOAT,
        [IsConsumptionItem] BIT,
        [IsFridgeItem] BIT,
        [Code] NVARCHAR(50),
        [MarketPrice] DECIMAL(18, 2),
        [MinimumOrderPrice] DECIMAL(18, 2),
        [MinimumOrderQuantity] DECIMAL(18, 2),
        [PackageType] NVARCHAR(100),
        [PackageSize] NVARCHAR(100),
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedById] INT,
        [CreatedOn] DATETIME DEFAULT GETDATE(),
        [ModifiedById] INT,
        [ModifiedOn] DATETIME,
        
        -- Foreign Keys
        CONSTRAINT [FK_Items_ItemTypes] FOREIGN KEY ([ItemTypeId]) REFERENCES [dbo].[ItemTypes]([Id]),
        CONSTRAINT [FK_Items_Brands] FOREIGN KEY ([BrandId]) REFERENCES [dbo].[Brands]([Id]),
        CONSTRAINT [FK_Items_Packings] FOREIGN KEY ([PackingId]) REFERENCES [dbo].[Packings]([Id]),
        CONSTRAINT [FK_Items_ItemUnits_Purchase] FOREIGN KEY ([UnitId]) REFERENCES [dbo].[ItemUnits]([Id]),
        CONSTRAINT [FK_Items_ItemUnits_Sale] FOREIGN KEY ([SaleUnitId]) REFERENCES [dbo].[ItemUnits]([Id]),
        CONSTRAINT [FK_Items_Prices] FOREIGN KEY ([PriceId]) REFERENCES [dbo].[Prices]([Id]),
        CONSTRAINT [FK_Items_Categories] FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[Categories]([Id]),
        CONSTRAINT [FK_Items_SubCategories] FOREIGN KEY ([SubCategoryId]) REFERENCES [dbo].[SubCategories]([Id]),
        CONSTRAINT [FK_Items_TaxRates] FOREIGN KEY ([TaxRateId]) REFERENCES [dbo].[TaxRates]([Id]),
        CONSTRAINT [FK_Items_TaxDescriptions] FOREIGN KEY ([TaxDescriptionId]) REFERENCES [dbo].[TaxDescriptions]([Id]),
        CONSTRAINT [FK_Items_TaxTypes] FOREIGN KEY ([TaxTypeId]) REFERENCES [dbo].[TaxTypes]([Id])
    );
    
    PRINT 'Items table created successfully';
END
ELSE
BEGIN
    PRINT 'Items table already exists';
END
GO
