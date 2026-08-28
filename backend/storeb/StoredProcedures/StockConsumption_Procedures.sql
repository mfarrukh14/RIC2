-- =============================================
-- Stock Consumption Stored Procedures
-- =============================================

-- Get All Stock Consumptions
CREATE OR ALTER PROCEDURE StockConsumption_GetAll
    @BranchId INT = NULL,
    @StoreId INT = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @SearchTerm NVARCHAR(200) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    SELECT
        scd.StockConsumptionId AS Id,
        s.StoreName,
        COALESCE(i.Name, m.MedicineFullName, f.Name) AS ItemName,
        CAST(scd.Type AS NVARCHAR(50)) AS Type,
        st.Name AS StockType,
        scd.Quantity,
        ISNULL(e.FullName, '') AS CreatedBy,
        sc.CreatedOn,
        COUNT(*) OVER() AS TotalCount
    FROM Inv.StockConsumptionDetails scd
    INNER JOIN Inv.StockConsumptions sc ON scd.StockConsumptionId = sc.Id
    LEFT JOIN Inv.PharmacyStores s ON sc.StoreId = s.StoreId
    LEFT JOIN Inv.Items i ON scd.ItemId = i.Id
    LEFT JOIN Pharmacy.Medicines m ON scd.MedicineId = m.MedicineId
    LEFT JOIN Account.Fees f ON scd.SubServiceId = f.Id
    LEFT JOIN Inv.StockTypes st ON scd.StockTypeId = st.Id
    LEFT JOIN dbo.Users u ON sc.CreatedById = u.UserID
    LEFT JOIN dbo.Employee e ON u.EmpID = e.EmpID
    WHERE sc.IsDeleted = 0
        AND scd.IsDeleted = 0
        AND (@BranchId IS NULL OR sc.BranchId = @BranchId)
        AND (@StoreId IS NULL OR sc.StoreId = @StoreId)
        AND (@StartDate IS NULL OR sc.CreatedOn >= @StartDate)
        AND (@EndDate IS NULL OR sc.CreatedOn <= @EndDate)
        AND (
            @SearchTerm IS NULL OR @SearchTerm = ''
            OR s.StoreName LIKE '%' + @SearchTerm + '%'
            OR i.Name LIKE '%' + @SearchTerm + '%'
            OR m.MedicineFullName LIKE '%' + @SearchTerm + '%'
            OR f.Name LIKE '%' + @SearchTerm + '%'
        )
    ORDER BY sc.CreatedOn DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
GO

-- Get Stock Consumption By ID
CREATE OR ALTER PROCEDURE StockConsumption_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get main stock consumption
    SELECT
        sc.Id,
        sc.StoreId,
        s.StoreName,
        sc.Type,
        sc.BranchId,
        b.BranchName AS BranchName,
        sc.VoucherId,
        sc.IsActive,
        sc.CreatedById,
        ISNULL(e.FullName, '') AS CreatedByName,
        sc.CreatedOn,
        sc.ModifiedById,
        sc.ModifiedOn,
        sc.IsDeleted,
        sc.Remarks
    FROM Inv.StockConsumptions sc
    LEFT JOIN Inv.PharmacyStores s ON sc.StoreId = s.StoreId
    LEFT JOIN dbo.Branch b ON sc.BranchId = b.BranchId
    LEFT JOIN dbo.Users cu ON sc.CreatedById = cu.UserID
    LEFT JOIN dbo.Employee e ON cu.EmpID = e.EmpID
    WHERE sc.Id = @Id AND sc.IsDeleted = 0;

    -- Get details
    SELECT
        scd.Id,
        scd.StockConsumptionId,
        scd.StoreId,
        s.StoreName,
        scd.ItemId,
        i.Name AS ItemName,
        scd.MedicineId,
        m.MedicineFullName AS MedicineName,
        scd.SubServiceId,
        f.Name AS SubServiceName,
        scd.Type,
        scd.StockTypeId,
        st.Name AS StockTypeName,
        scd.Quantity,
        scd.BranchId,
        scd.InventoryItemId,
        scd.SysBatchNo,
        scd.BatchNo,
        scd.IsActive,
        scd.CreatedById,
        scd.CreatedOn,
        scd.ModifiedById,
        scd.ModifiedOn,
        scd.IsDeleted
    FROM Inv.StockConsumptionDetails scd
    LEFT JOIN Inv.PharmacyStores s ON scd.StoreId = s.StoreId
    LEFT JOIN Inv.Items i ON scd.ItemId = i.Id
    LEFT JOIN Pharmacy.Medicines m ON scd.MedicineId = m.MedicineId
    LEFT JOIN Account.Fees f ON scd.SubServiceId = f.Id
    LEFT JOIN Inv.StockTypes st ON scd.StockTypeId = st.Id
    WHERE scd.StockConsumptionId = @Id AND scd.IsDeleted = 0;
END
GO

-- Insert Stock Consumption
CREATE OR ALTER PROCEDURE StockConsumption_Insert
    @StoreId INT,
    @BranchId INT,
    @Type INT,
    @CreatedById INT = NULL,
    @CreatedOn DATETIME,
    @Remarks NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Inv.StockConsumptions (
        StoreId, Type, BranchId, CreatedById, CreatedOn, IsActive, IsDeleted, Remarks
    )
    VALUES (
        @StoreId, @Type, @BranchId, @CreatedById, @CreatedOn, 1, 0, @Remarks
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- Update Stock Consumption
CREATE OR ALTER PROCEDURE StockConsumption_Update
    @Id INT,
    @StoreId INT,
    @BranchId INT,
    @Type INT,
    @ModifiedById INT = NULL,
    @ModifiedOn DATETIME,
    @Remarks NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inv.StockConsumptions
    SET
        StoreId = @StoreId,
        Type = @Type,
        BranchId = @BranchId,
        ModifiedById = @ModifiedById,
        ModifiedOn = @ModifiedOn,
        Remarks = @Remarks
    WHERE Id = @Id;
END
GO

-- Delete Stock Consumption (soft delete)
-- Restores the stock consumed by this record's details before removing it, so
-- deleting a consumption gives the quantity back to the store it was taken from.
CREATE OR ALTER PROCEDURE StockConsumption_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE s
    SET s.TotalItemsInStock = s.TotalItemsInStock + d.Quantity
    FROM Pharmacy.PharmacyMedicinesStocks s
    INNER JOIN Inv.StockConsumptionDetails d
        ON d.StoreId = s.StoreId
        AND ((d.ItemId IS NOT NULL AND d.ItemId = s.ItemId)
          OR (d.MedicineId IS NOT NULL AND d.MedicineId = s.BranchMedicineId)
          OR (d.SubServiceId IS NOT NULL AND d.SubServiceId = s.BranchSubServiceId))
    WHERE d.StockConsumptionId = @Id AND d.IsDeleted = 0;

    UPDATE Inv.StockConsumptions
    SET IsDeleted = 1
    WHERE Id = @Id;

    UPDATE Inv.StockConsumptionDetails
    SET IsDeleted = 1
    WHERE StockConsumptionId = @Id;
END
GO

-- Insert Stock Consumption Detail
-- A consumption can only draw from stock actually on hand at the specific store it
-- targets - previously this just logged a row with no link at all to a live stock
-- ledger, so any quantity could be "consumed" at any store regardless of what was
-- really available there. Now it validates against that store's on-hand quantity and
-- deducts it. Targets Pharmacy.PharmacyMedicinesStocks (the live ledger, not
-- Inv.Stocks - see Stock_Procedures.sql header for why).
CREATE OR ALTER PROCEDURE StockConsumptionDetail_Insert
    @StockConsumptionId INT,
    @StoreId INT,
    @ItemId INT = NULL,
    @MedicineId INT = NULL,
    @SubServiceId INT = NULL,
    @Type INT,
    @StockTypeId INT,
    @Quantity DECIMAL(18,2),
    @BranchId INT,
    @CreatedById INT = NULL,
    @CreatedOn DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- Exactly one of @ItemId/@MedicineId/@SubServiceId identifies the product
    -- being consumed - Items, Medicines, and Disposables are separate tables
    -- (see Item_GetAllWithMedicines) but share one stock balance keyed the
    -- same way in Pharmacy.PharmacyMedicinesStocks (as ItemId/BranchMedicineId/
    -- BranchSubServiceId there).
    DECLARE @Available DECIMAL(18,2);

    SELECT @Available = TotalItemsInStock
    FROM Pharmacy.PharmacyMedicinesStocks
    WHERE StoreId = @StoreId
        AND ((@ItemId IS NOT NULL AND ItemId = @ItemId)
          OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId)
          OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId));

    IF @Available IS NULL OR @Available < @Quantity
    BEGIN
        DECLARE @Msg NVARCHAR(400) = CONCAT(
            N'Insufficient stock at the selected store: only ',
            ISNULL(CAST(@Available AS NVARCHAR(20)), N'0'),
            N' available, requested ', CAST(@Quantity AS NVARCHAR(20)), N'.');
        THROW 50001, @Msg, 1;
    END

    UPDATE Pharmacy.PharmacyMedicinesStocks
    SET TotalItemsInStock = TotalItemsInStock - @Quantity
    WHERE StoreId = @StoreId
        AND ((@ItemId IS NOT NULL AND ItemId = @ItemId)
          OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId)
          OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId));

    INSERT INTO Inv.StockConsumptionDetails (
        StockConsumptionId, StoreId, ItemId, MedicineId, SubServiceId, Type, StockTypeId, Quantity,
        BranchId, CreatedById, CreatedOn, IsActive, IsDeleted
    )
    VALUES (
        @StockConsumptionId, @StoreId, @ItemId, @MedicineId, @SubServiceId, @Type, @StockTypeId, @Quantity,
        @BranchId, @CreatedById, @CreatedOn, 1, 0
    );

    SELECT SCOPE_IDENTITY() AS Id;
END
GO

-- Delete Stock Consumption Details by Consumption ID
-- Used when editing a consumption (old details are replaced by new ones) - restores
-- the stock these details had consumed before soft-deleting them, so the subsequent
-- re-insert of the edited details validates against accurate on-hand quantities.
CREATE OR ALTER PROCEDURE StockConsumptionDetail_DeleteByConsumptionId
    @StockConsumptionId INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE s
    SET s.TotalItemsInStock = s.TotalItemsInStock + d.Quantity
    FROM Pharmacy.PharmacyMedicinesStocks s
    INNER JOIN Inv.StockConsumptionDetails d
        ON d.StoreId = s.StoreId
        AND ((d.ItemId IS NOT NULL AND d.ItemId = s.ItemId)
          OR (d.MedicineId IS NOT NULL AND d.MedicineId = s.BranchMedicineId)
          OR (d.SubServiceId IS NOT NULL AND d.SubServiceId = s.BranchSubServiceId))
    WHERE d.StockConsumptionId = @StockConsumptionId AND d.IsDeleted = 0;

    UPDATE Inv.StockConsumptionDetails
    SET IsDeleted = 1
    WHERE StockConsumptionId = @StockConsumptionId;
END
GO
