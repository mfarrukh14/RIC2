-- Stored procedure to get pharmacy stock detail records
--
-- Rewritten again to read from Inv.StockTransactions, the real ledger every stock
-- movement now writes to via Pharmacy.TR_PharmacyMedicinesStocks_LogTransactions (see
-- that trigger's header for the full story). The previous version reconstructed
-- Received/Issued by UNIONing 4 of the 9 real stock-mutation paths (Transfer, Stock
-- Adjustment, GRN, Add Inventory) - it could never see pharmacy retail dispensing or
-- demand-request movements, which silently drained stock the report had no record of
-- "leaving", producing negative Opening balances (e.g. an item with 1218 units added via
-- one tracked path, 0 tracked Issued, but a real current balance of 0).
--
-- Opening is anchored off the CURRENT balance (Pharmacy.PharmacyMedicinesStocks, always
-- "now") minus every ledgered movement from @StartDate to now - not off a snapshot at
-- @StartDate, because none exists. Received/Issued for display are still windowed to
-- [@StartDate, @EndDate] as before. The ledger only started being populated when the
-- trigger was created, so windows starting well before that still degrade gracefully
-- (Opening ~= current balance, since no historical movement rows exist to subtract) -
-- there is no way to backfill a "before" state for movements nobody ever recorded, but
-- accuracy will now be exact for any window entirely after the trigger existed.
--
-- Extended to also cover medicines and disposables (previously Inv.Items only, so the
-- report silently dropped every Pharmacy.BranchMedicines/Data.BranchFees-backed stock
-- row - same three product kinds Stock_Search already unions for the Stock (MPL) page).
-- Every CTE now carries a discriminated (ProductType, ProductId) key instead of a bare
-- ItemId. Medicine/disposable Received/Issued/Balance come from the exact same
-- Inv.StockTransactions/Pharmacy.PharmacyMedicinesStocks ledger as Items - those
-- movements were always being recorded, just never read by this report. Medicine
-- BuyingPrice/SellingPrice will show 0.00: confirmed Pharmacy.Medicines has zero rows
-- anywhere with a nonzero CostPrice/MRP/PricePerUnit, and BranchMedicines.PriceId
-- resolves to equally-empty Data.Prices rows - a data gap in this deployment, not
-- something this query can source around. Disposable pricing works normally (from
-- Data.Prices via Data.BranchFees.PriceId).
CREATE OR ALTER PROCEDURE StockDetailRecord_GetReport
    @Branch NVARCHAR(255) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Store NVARCHAR(255) = NULL,
    @Vendor NVARCHAR(255) = NULL,
    @StockType NVARCHAR(255) = NULL,
    @Item NVARCHAR(255) = NULL,
    @ItemType NVARCHAR(255) = NULL,
    @SaleType NVARCHAR(255) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StoreId INT = (SELECT StoreId FROM Inv.PharmacyStores WHERE StoreName = @Store);
    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;

    ;WITH
    -- Pharmacy.PharmacyMedicinesStocks carries exactly one of ItemId/BranchMedicineId/
    -- BranchSubServiceId per row (Inv.Items / Pharmacy.BranchMedicines / Data.BranchFees -
    -- same three product kinds Stock_Search already unions for the Stock (MPL) page).
    -- ProductType/ProductId here is that same discriminated key.
    StockBalance AS (
        SELECT 'Item' AS ProductType, ItemId AS ProductId, SUM(TotalItemsInStock) AS TotalItems
        FROM Pharmacy.PharmacyMedicinesStocks
        WHERE (@StoreId IS NULL OR StoreId = @StoreId) AND ItemId IS NOT NULL
        GROUP BY ItemId
        UNION ALL
        SELECT 'Medicine', BranchMedicineId, SUM(TotalItemsInStock)
        FROM Pharmacy.PharmacyMedicinesStocks
        WHERE (@StoreId IS NULL OR StoreId = @StoreId) AND BranchMedicineId IS NOT NULL
        GROUP BY BranchMedicineId
        UNION ALL
        SELECT 'Fee', BranchSubServiceId, SUM(TotalItemsInStock)
        FROM Pharmacy.PharmacyMedicinesStocks
        WHERE (@StoreId IS NULL OR StoreId = @StoreId) AND BranchSubServiceId IS NOT NULL
        GROUP BY BranchSubServiceId
    ),
    -- Same single-pass conditional-SUM technique as before, now unioned across all three
    -- product kinds - Inv.StockTransactions already carries ItemId/BranchMedicineId/
    -- BranchSubServiceId on every ledger row, so medicine and disposable movements were
    -- always being recorded, just never read by this report. Also carries each branch's
    -- latest ledger StockTypeId (via a ROW_NUMBER/MAX(CASE...) in the same pass) for the
    -- Medicine/Fee StockType lookup below - originally a separate CTE re-scanning the
    -- Medicine/Fee rows a second time, which combined with an earlier missing @StoreId
    -- filter turned a 60+-second no-filter request into effectively a hang. Folding it in
    -- here keeps this at 3 ledger scans total (one per product kind) instead of 5.
    Movement AS (
        SELECT ProductType, ProductId,
            SUM(ReceivedQty) AS ReceivedQty,
            SUM(IssuedQty) AS IssuedQty,
            SUM(ReceivedAll) - SUM(IssuedAll) AS NetQty,
            SUM(InWindowFlag) AS InWindowRowCount,
            MAX(CASE WHEN rn = 1 THEN StockTypeId END) AS LatestStockTypeId
        FROM (
            SELECT
                'Item' AS ProductType, st.ItemId AS ProductId,
                CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN st.ReceivedQty ELSE 0 END AS ReceivedQty,
                CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN st.IssuedQty ELSE 0 END AS IssuedQty,
                st.ReceivedQty AS ReceivedAll, st.IssuedQty AS IssuedAll,
                CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN 1 ELSE 0 END AS InWindowFlag,
                -- Items resolve StockType via Inv.Inventories instead (LatestInventoryDetail
                -- below) - no need to rank ledger rows for them, so rn is a constant.
                CAST(NULL AS INT) AS StockTypeId, CAST(1 AS BIGINT) AS rn
            FROM Inv.StockTransactions st
            WHERE st.ItemId IS NOT NULL
              AND (@StoreId IS NULL OR st.StoreId = @StoreId)
              AND (@StartDate IS NULL OR st.CreatedOn >= @StartDate)
            UNION ALL
            SELECT
                'Medicine', st.BranchMedicineId,
                CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN st.ReceivedQty ELSE 0 END,
                CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN st.IssuedQty ELSE 0 END,
                st.ReceivedQty, st.IssuedQty,
                CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN 1 ELSE 0 END,
                st.StockTypeId,
                ROW_NUMBER() OVER (PARTITION BY st.BranchMedicineId ORDER BY st.CreatedOn DESC, st.Id DESC)
            FROM Inv.StockTransactions st
            WHERE st.BranchMedicineId IS NOT NULL
              AND (@StoreId IS NULL OR st.StoreId = @StoreId)
              AND (@StartDate IS NULL OR st.CreatedOn >= @StartDate)
            UNION ALL
            SELECT
                'Fee', st.BranchSubServiceId,
                CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN st.ReceivedQty ELSE 0 END,
                CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN st.IssuedQty ELSE 0 END,
                st.ReceivedQty, st.IssuedQty,
                CASE WHEN @EndDate IS NULL OR st.CreatedOn < DATEADD(DAY, 1, @EndDate) THEN 1 ELSE 0 END,
                st.StockTypeId,
                ROW_NUMBER() OVER (PARTITION BY st.BranchSubServiceId ORDER BY st.CreatedOn DESC, st.Id DESC)
            FROM Inv.StockTransactions st
            WHERE st.BranchSubServiceId IS NOT NULL
              AND (@StoreId IS NULL OR st.StoreId = @StoreId)
              AND (@StartDate IS NULL OR st.CreatedOn >= @StartDate)
        ) raw
        GROUP BY ProductType, ProductId
    ),
    MovedItems AS (
        SELECT ProductType, ProductId FROM Movement WHERE InWindowRowCount > 0
        UNION
        -- Products with no ledger movement in the window but that DO have a current
        -- balance still belong in the report (Opening = Balance in that case).
        SELECT ProductType, ProductId FROM StockBalance WHERE TotalItems <> 0
    ),
    -- Items only: GRN receipt price/vendor, scoped to MovedItems - a LEFT JOIN below only
    -- ever matches rows already restricted to MovedItems, so this changes nothing about
    -- the result, only how much of Inv.GRNItems needs to be windowed per request.
    LatestGrn AS (
        SELECT
            gi.ItemId AS ProductId, gi.UnitBuyingPrice, gi.UnitSellingPrice, v.Name AS VendorName,
            ROW_NUMBER() OVER (PARTITION BY gi.ItemId ORDER BY grn.DateAndTime DESC, gi.Id DESC) AS rn
        FROM Inv.GRNItems gi
        INNER JOIN MovedItems mi ON mi.ProductType = 'Item' AND mi.ProductId = gi.ItemId
        INNER JOIN Inv.GoodsReceivingNotes grn ON grn.Id = gi.GRNId
        LEFT JOIN Inv.Vendors v ON grn.VendorId = v.Id
        WHERE grn.IsActive = 1
    ),
    -- Items only: latest Add-Inventory price/stock-type, scoped to MovedItems, computing
    -- both the fallback buying/selling price (ordered by receipt date, rnPrice) and the
    -- current stock type (ordered by COALESCE(ModifiedOn, CreatedOn), rnStockType) off
    -- one shared scan - previously a separate windowed CTE for price PLUS a per-row
    -- correlated OUTER APPLY (one execution per matched item) for stock type;
    -- Inv.InventoryDetails has no index on ItemId, so that per-row re-scan was the
    -- single biggest cost in this report before this fix.
    LatestInventoryDetail AS (
        SELECT
            d.ItemId AS ProductId, d.UnitBuyingPrice, d.UnitSellingPrice, inv.StockTypeId,
            ROW_NUMBER() OVER (PARTITION BY d.ItemId ORDER BY inv.CreatedOn DESC, d.Id DESC) AS rnPrice,
            ROW_NUMBER() OVER (PARTITION BY d.ItemId ORDER BY COALESCE(inv.ModifiedOn, inv.CreatedOn) DESC, inv.Id DESC) AS rnStockType
        FROM Inv.InventoryDetails d
        INNER JOIN MovedItems mi ON mi.ProductType = 'Item' AND mi.ProductId = d.ItemId
        INNER JOIN Inv.Inventories inv ON inv.Id = d.InventoryId
        WHERE inv.IsActive = 1
    ),
    -- Display name + the columns needed for filtering, one row per moved product across
    -- all three kinds. bm.MedicineFullName is the same "Type Name (Generic) Strength"
    -- composed field used for the Stock (MPL) page's medicine rows.
    Products AS (
        SELECT 'Item' AS ProductType, i.Id AS ProductId, i.Name, i.ItemTypeId
        FROM Inv.Items i
        INNER JOIN MovedItems mi ON mi.ProductType = 'Item' AND mi.ProductId = i.Id
        WHERE i.IsActive = 1
        UNION ALL
        SELECT 'Medicine', bm.Id, bm.MedicineFullName, NULL
        FROM Pharmacy.BranchMedicines bm
        INNER JOIN MovedItems mi ON mi.ProductType = 'Medicine' AND mi.ProductId = bm.Id
        UNION ALL
        SELECT 'Fee', bf.Id, bf.Name, NULL
        FROM Data.BranchFees bf
        INNER JOIN MovedItems mi ON mi.ProductType = 'Fee' AND mi.ProductId = bf.Id
    )
    SELECT
        -- ROW_NUMBER() is BIGINT by default - cast down since StockDetailRecord.Sr is int
        -- and the C# reader uses GetInt32.
        CAST(ROW_NUMBER() OVER (ORDER BY p.Name) AS INT) AS Sr,
        p.Name,
        COALESCE(st.Name, 'Regular') AS StockType,
        -- GRNItems' price columns are DECIMAL but InventoryDetails' are REAL - cast every
        -- branch so the expression's static type stays DECIMAL(18,2) throughout (SQL
        -- Server would otherwise promote the whole CASE to FLOAT, which the C# side's
        -- reader.GetDecimal(...) can't read back without throwing).
        -- Medicine buying/selling price is read off the catalog (Pharmacy.Medicines
        -- CostPrice/MRP/PricePerUnit) - confirmed this database has zero rows anywhere
        -- with a nonzero value in any of those three columns, and BranchMedicines.PriceId
        -- resolves to equally-empty Data.Prices rows, so medicine rows will show 0.00
        -- here until this hospital's Pharmacy data actually records per-medicine cost -
        -- that's a data gap, not something this query can source around.
        CASE p.ProductType
            WHEN 'Item' THEN ISNULL(lg.UnitBuyingPrice, CAST(ISNULL(lidPrice.UnitBuyingPrice, 0) AS DECIMAL(18,2)))
            WHEN 'Medicine' THEN CAST(ISNULL(med.CostPrice, 0) AS DECIMAL(18,2))
            ELSE CAST(0 AS DECIMAL(18,2))
        END AS BuyingPrice,
        CASE p.ProductType
            WHEN 'Item' THEN ISNULL(lg.UnitSellingPrice, CAST(ISNULL(lidPrice.UnitSellingPrice, 0) AS DECIMAL(18,2)))
            WHEN 'Medicine' THEN CAST(ISNULL(ISNULL(med.MRP, med.PricePerUnit), 0) AS DECIMAL(18,2))
            WHEN 'Fee' THEN CAST(ISNULL(feePrice.Total, 0) AS DECIMAL(18,2))
            ELSE CAST(0 AS DECIMAL(18,2))
        END AS SellingPrice,
        CAST(ISNULL(sb.TotalItems, 0) - ISNULL(mv.NetQty, 0) AS INT) AS Opening,
        CAST(ISNULL(mv.ReceivedQty, 0) AS INT) AS Received,
        CAST(ISNULL(mv.IssuedQty, 0) AS INT) AS Issued,
        CAST(ISNULL(sb.TotalItems, 0) AS INT) AS Balance,
        COUNT(*) OVER() AS TotalCount
    FROM Products p
    LEFT JOIN StockBalance sb ON sb.ProductType = p.ProductType AND sb.ProductId = p.ProductId
    LEFT JOIN Movement mv ON mv.ProductType = p.ProductType AND mv.ProductId = p.ProductId
    LEFT JOIN LatestGrn lg ON p.ProductType = 'Item' AND lg.ProductId = p.ProductId AND lg.rn = 1
    LEFT JOIN LatestInventoryDetail lidPrice ON p.ProductType = 'Item' AND lidPrice.ProductId = p.ProductId AND lidPrice.rnPrice = 1
    LEFT JOIN LatestInventoryDetail lidType ON p.ProductType = 'Item' AND lidType.ProductId = p.ProductId AND lidType.rnStockType = 1
    -- mv.LatestStockTypeId only sees ledger rows on/after @StartDate (it's computed inside
    -- Movement, which is windowed) - a Medicine/Fee product present only because of a
    -- nonzero current balance, with no ledger activity in that window, falls back to
    -- 'Regular' below rather than its true last-known type. Acceptable: this is new
    -- coverage for a product kind the report previously excluded outright.
    LEFT JOIN Inv.StockTypes st ON st.Id = COALESCE(lidType.StockTypeId, mv.LatestStockTypeId)
    LEFT JOIN Inv.ItemTypes it ON p.ProductType = 'Item' AND it.Id = p.ItemTypeId
    LEFT JOIN Pharmacy.BranchMedicines bm2 ON p.ProductType = 'Medicine' AND bm2.Id = p.ProductId
    LEFT JOIN Pharmacy.Medicines med ON med.MedicineId = bm2.MedicineId
    LEFT JOIN Data.BranchFees bf2 ON p.ProductType = 'Fee' AND bf2.Id = p.ProductId
    LEFT JOIN Data.Prices feePrice ON feePrice.PriceId = bf2.PriceId
    WHERE
        (@Vendor IS NULL OR lg.VendorName = @Vendor)
        AND (@StockType IS NULL OR st.Name = @StockType)
        AND (@Item IS NULL OR p.Name LIKE '%' + @Item + '%')
        AND (
            @ItemType IS NULL
            OR (p.ProductType = 'Item' AND it.Name = @ItemType)
            OR (p.ProductType = 'Medicine' AND @ItemType = 'Medicine')
            OR (p.ProductType = 'Fee' AND @ItemType = 'Fee')
        )
    ORDER BY p.Name
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
GO
