-- =============================================
-- Alter Stores Table to add comprehensive fields
-- =============================================

-- Add new columns if they don't exist
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'StoreType')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [StoreType] NVARCHAR(50);
    PRINT 'Added StoreType column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'ReceiptType')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [ReceiptType] NVARCHAR(50);
    PRINT 'Added ReceiptType column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'POSType')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [POSType] NVARCHAR(50);
    PRINT 'Added POSType column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'ParentStoreId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [ParentStoreId] INT;
    PRINT 'Added ParentStoreId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'BuildingId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [BuildingId] INT;
    PRINT 'Added BuildingId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'FloorId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [FloorId] INT;
    PRINT 'Added FloorId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'RoomId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [RoomId] INT;
    PRINT 'Added RoomId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'Email')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [Email] NVARCHAR(200);
    PRINT 'Added Email column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'CellNumber')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [CellNumber] NVARCHAR(50);
    PRINT 'Added CellNumber column';
END

-- Queue Settings
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'QueuePatientCallStatusValue')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [QueuePatientCallStatusValue] NVARCHAR(100);
    PRINT 'Added QueuePatientCallStatusValue column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'MarkTokenAsAutoCollectedOnDispense')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [MarkTokenAsAutoCollectedOnDispense] BIT;
    PRINT 'Added MarkTokenAsAutoCollectedOnDispense column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'DisplayRequestsWithoutTokenIssued')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [DisplayRequestsWithoutTokenIssued] BIT;
    PRINT 'Added DisplayRequestsWithoutTokenIssued column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'EnglishNote')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [EnglishNote] NVARCHAR(MAX);
    PRINT 'Added EnglishNote column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'UrduNote')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [UrduNote] NVARCHAR(MAX);
    PRINT 'Added UrduNote column';
END

-- Financial Settings
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'ServiceCharges')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [ServiceCharges] BIT;
    PRINT 'Added ServiceCharges column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'GST')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [GST] BIT;
    PRINT 'Added GST column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'PricingType')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [PricingType] NVARCHAR(50);
    PRINT 'Added PricingType column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'DisableRetailSale')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [DisableRetailSale] BIT;
    PRINT 'Added DisableRetailSale column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'GSTN')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [GSTN] NVARCHAR(50);
    PRINT 'Added GSTN column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'NTN')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [NTN] NVARCHAR(50);
    PRINT 'Added NTN column';
END

-- Day Closing
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'DayClosing')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [DayClosing] NVARCHAR(50);
    PRINT 'Added DayClosing column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'ClosingCashAccountId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [ClosingCashAccountId] INT;
    PRINT 'Added ClosingCashAccountId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'ClosingRevenueAccountId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [ClosingRevenueAccountId] INT;
    PRINT 'Added ClosingRevenueAccountId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'ClosingInventoryAccountId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [ClosingInventoryAccountId] INT;
    PRINT 'Added ClosingInventoryAccountId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'ClosingInventoryExpenseAccountId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [ClosingInventoryExpenseAccountId] INT;
    PRINT 'Added ClosingInventoryExpenseAccountId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'ClosingTaxExpenseAccountId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [ClosingTaxExpenseAccountId] INT;
    PRINT 'Added ClosingTaxExpenseAccountId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'PayableAccountId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [PayableAccountId] INT;
    PRINT 'Added PayableAccountId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'AdvanceTaxPercentageAccountId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [AdvanceTaxPercentageAccountId] INT;
    PRINT 'Added AdvanceTaxPercentageAccountId column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'RevenueDiscountAccountId')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [RevenueDiscountAccountId] INT;
    PRINT 'Added RevenueDiscountAccountId column';
END

-- Address Details
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'Address')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [Address] NVARCHAR(500);
    PRINT 'Added Address column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'Latitude')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [Latitude] NVARCHAR(50);
    PRINT 'Added Latitude column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'Longitude')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [Longitude] NVARCHAR(50);
    PRINT 'Added Longitude column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'Country')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [Country] NVARCHAR(100);
    PRINT 'Added Country column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'StateOrProvince')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [StateOrProvince] NVARCHAR(100);
    PRINT 'Added StateOrProvince column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'City')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [City] NVARCHAR(100);
    PRINT 'Added City column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'StoreImage')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [StoreImage] NVARCHAR(500);
    PRINT 'Added StoreImage column';
END

-- Audit columns
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'CreatedById')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [CreatedById] INT;
    PRINT 'Added CreatedById column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('dbo.Stores') AND name = 'ModifiedById')
BEGIN
    ALTER TABLE [dbo].[Stores] ADD [ModifiedById] INT;
    PRINT 'Added ModifiedById column';
END

PRINT 'Stores table alteration completed successfully';
GO
