-- =============================================
-- Add BranchId to Store CRUD procedures.
--
-- Pharmacy.PharmacyStores.BranchId is NOT NULL, but no parameter/column for it
-- existed anywhere in the Store_* procs, so every INSERT failed. BranchId is
-- always set server-side from the logged-in user's own branch (BaseController),
-- never trusted from the client - same pattern as the rest of the app's
-- branch-locking.
-- =============================================

CREATE OR ALTER PROCEDURE dbo.Store_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.StoreId,
        s.StoreName,
        s.StoreCode,
        s.Description,
        s.StoreType,
        s.ReceiptType,
        s.POSType,
        s.ParentStoreId,
        ps.StoreName AS ParentStoreName,
        s.BuildingId,
        s.FloorId,
        s.RoomId,
        s.Email,
        s.CellNumber,
        s.QueuePatientCallStatusValue,
        s.MarkTokenAsAutoCollectedOnDispense,
        s.DisplayRequestsWithoutTokenIssued,
        s.EnglishNote,
        s.UrduNote,
        s.ServiceCharges,
        s.GST,
        s.PricingType,
        s.DisableRetailSale,
        s.GSTN,
        s.NTN,
        s.DayClosing,
        s.ClosingCashAccountId,
        s.ClosingRevenueAccountId,
        s.ClosingInventoryAccountId,
        s.ClosingInventoryExpenseAccountId,
        s.ClosingTaxExpenseAccountId,
        s.PayableAccountId,
        s.AdvanceTaxPercentageAccountId,
        s.RevenueDiscountAccountId,
        s.Address,
        s.Latitude,
        s.Longitude,
        s.Country,
        s.StateOrProvince,
        s.City,
        s.StoreImage,
        s.BranchId,
        b.Name AS BranchName,
        s.IsActive,
        s.CreatedById,
        s.CreatedOn,
        s.ModifiedById,
        s.ModifiedOn
    FROM Inv.PharmacyStores s
    LEFT JOIN Inv.PharmacyStores ps ON s.ParentStoreId = ps.StoreId
    LEFT JOIN Inv.Branches b ON s.BranchId = b.Id
    ORDER BY s.StoreName;
END
GO

CREATE OR ALTER PROCEDURE dbo.Store_GetById
    @StoreId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.StoreId,
        s.StoreName,
        s.StoreCode,
        s.Description,
        s.StoreType,
        s.ReceiptType,
        s.POSType,
        s.ParentStoreId,
        ps.StoreName AS ParentStoreName,
        s.BuildingId,
        s.FloorId,
        s.RoomId,
        s.Email,
        s.CellNumber,
        s.QueuePatientCallStatusValue,
        s.MarkTokenAsAutoCollectedOnDispense,
        s.DisplayRequestsWithoutTokenIssued,
        s.EnglishNote,
        s.UrduNote,
        s.ServiceCharges,
        s.GST,
        s.PricingType,
        s.DisableRetailSale,
        s.GSTN,
        s.NTN,
        s.DayClosing,
        s.ClosingCashAccountId,
        s.ClosingRevenueAccountId,
        s.ClosingInventoryAccountId,
        s.ClosingInventoryExpenseAccountId,
        s.ClosingTaxExpenseAccountId,
        s.PayableAccountId,
        s.AdvanceTaxPercentageAccountId,
        s.RevenueDiscountAccountId,
        s.Address,
        s.Latitude,
        s.Longitude,
        s.Country,
        s.StateOrProvince,
        s.City,
        s.StoreImage,
        s.BranchId,
        b.Name AS BranchName,
        s.IsActive,
        s.CreatedById,
        s.CreatedOn,
        s.ModifiedById,
        s.ModifiedOn
    FROM Inv.PharmacyStores s
    LEFT JOIN Inv.PharmacyStores ps ON s.ParentStoreId = ps.StoreId
    LEFT JOIN Inv.Branches b ON s.BranchId = b.Id
    WHERE s.StoreId = @StoreId;
END
GO

CREATE OR ALTER PROCEDURE dbo.Store_Insert
    @StoreName NVARCHAR(200),
    @StoreCode NVARCHAR(50) = NULL,
    @Description NVARCHAR(500) = NULL,
    @StoreType NVARCHAR(50) = NULL,
    @ReceiptType NVARCHAR(50) = NULL,
    @POSType NVARCHAR(50) = NULL,
    @ParentStoreId INT = NULL,
    @BuildingId INT = NULL,
    @FloorId INT = NULL,
    @RoomId INT = NULL,
    @Email NVARCHAR(200) = NULL,
    @CellNumber NVARCHAR(50) = NULL,
    @QueuePatientCallStatusValue NVARCHAR(100) = NULL,
    @MarkTokenAsAutoCollectedOnDispense BIT = NULL,
    @DisplayRequestsWithoutTokenIssued BIT = NULL,
    @EnglishNote NVARCHAR(MAX) = NULL,
    @UrduNote NVARCHAR(MAX) = NULL,
    @ServiceCharges BIT = NULL,
    @GST BIT = NULL,
    @PricingType NVARCHAR(50) = NULL,
    @DisableRetailSale BIT = NULL,
    @GSTN NVARCHAR(50) = NULL,
    @NTN NVARCHAR(50) = NULL,
    @DayClosing NVARCHAR(50) = NULL,
    @ClosingCashAccountId INT = NULL,
    @ClosingRevenueAccountId INT = NULL,
    @ClosingInventoryAccountId INT = NULL,
    @ClosingInventoryExpenseAccountId INT = NULL,
    @ClosingTaxExpenseAccountId INT = NULL,
    @PayableAccountId INT = NULL,
    @AdvanceTaxPercentageAccountId INT = NULL,
    @RevenueDiscountAccountId INT = NULL,
    @Address NVARCHAR(500) = NULL,
    @Latitude NVARCHAR(50) = NULL,
    @Longitude NVARCHAR(50) = NULL,
    @Country NVARCHAR(100) = NULL,
    @StateOrProvince NVARCHAR(100) = NULL,
    @City NVARCHAR(100) = NULL,
    @StoreImage NVARCHAR(500) = NULL,
    @BranchId INT,
    @IsActive BIT = 1,
    @CreatedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Inv.PharmacyStores (
        StoreName, StoreCode, Description, StoreType, ReceiptType, POSType,
        ParentStoreId, BuildingId, FloorId, RoomId, Email, CellNumber,
        QueuePatientCallStatusValue, MarkTokenAsAutoCollectedOnDispense,
        DisplayRequestsWithoutTokenIssued, EnglishNote, UrduNote,
        ServiceCharges, GST, PricingType, DisableRetailSale, GSTN, NTN,
        DayClosing, ClosingCashAccountId, ClosingRevenueAccountId,
        ClosingInventoryAccountId, ClosingInventoryExpenseAccountId,
        ClosingTaxExpenseAccountId, PayableAccountId, AdvanceTaxPercentageAccountId,
        RevenueDiscountAccountId, Address, Latitude, Longitude, Country,
        StateOrProvince, City, StoreImage, BranchId, IsActive, CreatedById, CreatedOn
    )
    VALUES (
        @StoreName, @StoreCode, @Description, @StoreType, @ReceiptType, @POSType,
        @ParentStoreId, @BuildingId, @FloorId, @RoomId, @Email, @CellNumber,
        @QueuePatientCallStatusValue, @MarkTokenAsAutoCollectedOnDispense,
        @DisplayRequestsWithoutTokenIssued, @EnglishNote, @UrduNote,
        @ServiceCharges, @GST, @PricingType, @DisableRetailSale, @GSTN, @NTN,
        @DayClosing, @ClosingCashAccountId, @ClosingRevenueAccountId,
        @ClosingInventoryAccountId, @ClosingInventoryExpenseAccountId,
        @ClosingTaxExpenseAccountId, @PayableAccountId, @AdvanceTaxPercentageAccountId,
        @RevenueDiscountAccountId, @Address, @Latitude, @Longitude, @Country,
        @StateOrProvince, @City, @StoreImage, @BranchId, @IsActive, @CreatedById, GETDATE()
    );

    SELECT SCOPE_IDENTITY() AS StoreId;
END
GO

CREATE OR ALTER PROCEDURE dbo.Store_Update
    @StoreId INT,
    @StoreName NVARCHAR(200),
    @StoreCode NVARCHAR(50) = NULL,
    @Description NVARCHAR(500) = NULL,
    @StoreType NVARCHAR(50) = NULL,
    @ReceiptType NVARCHAR(50) = NULL,
    @POSType NVARCHAR(50) = NULL,
    @ParentStoreId INT = NULL,
    @BuildingId INT = NULL,
    @FloorId INT = NULL,
    @RoomId INT = NULL,
    @Email NVARCHAR(200) = NULL,
    @CellNumber NVARCHAR(50) = NULL,
    @QueuePatientCallStatusValue NVARCHAR(100) = NULL,
    @MarkTokenAsAutoCollectedOnDispense BIT = NULL,
    @DisplayRequestsWithoutTokenIssued BIT = NULL,
    @EnglishNote NVARCHAR(MAX) = NULL,
    @UrduNote NVARCHAR(MAX) = NULL,
    @ServiceCharges BIT = NULL,
    @GST BIT = NULL,
    @PricingType NVARCHAR(50) = NULL,
    @DisableRetailSale BIT = NULL,
    @GSTN NVARCHAR(50) = NULL,
    @NTN NVARCHAR(50) = NULL,
    @DayClosing NVARCHAR(50) = NULL,
    @ClosingCashAccountId INT = NULL,
    @ClosingRevenueAccountId INT = NULL,
    @ClosingInventoryAccountId INT = NULL,
    @ClosingInventoryExpenseAccountId INT = NULL,
    @ClosingTaxExpenseAccountId INT = NULL,
    @PayableAccountId INT = NULL,
    @AdvanceTaxPercentageAccountId INT = NULL,
    @RevenueDiscountAccountId INT = NULL,
    @Address NVARCHAR(500) = NULL,
    @Latitude NVARCHAR(50) = NULL,
    @Longitude NVARCHAR(50) = NULL,
    @Country NVARCHAR(100) = NULL,
    @StateOrProvince NVARCHAR(100) = NULL,
    @City NVARCHAR(100) = NULL,
    @StoreImage NVARCHAR(500) = NULL,
    @BranchId INT,
    @IsActive BIT,
    @ModifiedById INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.PharmacyStores
    SET
        StoreName = @StoreName,
        StoreCode = @StoreCode,
        Description = @Description,
        StoreType = @StoreType,
        ReceiptType = @ReceiptType,
        POSType = @POSType,
        ParentStoreId = @ParentStoreId,
        BuildingId = @BuildingId,
        FloorId = @FloorId,
        RoomId = @RoomId,
        Email = @Email,
        CellNumber = @CellNumber,
        QueuePatientCallStatusValue = @QueuePatientCallStatusValue,
        MarkTokenAsAutoCollectedOnDispense = @MarkTokenAsAutoCollectedOnDispense,
        DisplayRequestsWithoutTokenIssued = @DisplayRequestsWithoutTokenIssued,
        EnglishNote = @EnglishNote,
        UrduNote = @UrduNote,
        ServiceCharges = @ServiceCharges,
        GST = @GST,
        PricingType = @PricingType,
        DisableRetailSale = @DisableRetailSale,
        GSTN = @GSTN,
        NTN = @NTN,
        DayClosing = @DayClosing,
        ClosingCashAccountId = @ClosingCashAccountId,
        ClosingRevenueAccountId = @ClosingRevenueAccountId,
        ClosingInventoryAccountId = @ClosingInventoryAccountId,
        ClosingInventoryExpenseAccountId = @ClosingInventoryExpenseAccountId,
        ClosingTaxExpenseAccountId = @ClosingTaxExpenseAccountId,
        PayableAccountId = @PayableAccountId,
        AdvanceTaxPercentageAccountId = @AdvanceTaxPercentageAccountId,
        RevenueDiscountAccountId = @RevenueDiscountAccountId,
        Address = @Address,
        Latitude = @Latitude,
        Longitude = @Longitude,
        Country = @Country,
        StateOrProvince = @StateOrProvince,
        City = @City,
        StoreImage = @StoreImage,
        BranchId = @BranchId,
        IsActive = @IsActive,
        ModifiedById = @ModifiedById,
        ModifiedOn = GETDATE()
    WHERE StoreId = @StoreId;
END
GO

PRINT 'Store_GetAll / Store_GetById / Store_Insert / Store_Update now handle BranchId';
GO
