-- Adds store-scoped access control to Inventory_GetAll (the "Add Inventory"
-- list) - same pattern as StockSearch_AddStoreScoping.sql, see that file's
-- header for the full rationale.
CREATE OR ALTER PROCEDURE [dbo].[Inventory_GetAll]
    @SearchTerm NVARCHAR(200) = NULL,
    @VendorId INT = NULL,
    @StoreId INT = NULL,
    @DateFrom DATETIME = NULL,
    @DateTo DATETIME = NULL,
    @IsAdmin BIT = 0,
    @AllowedStoreIds NVARCHAR(MAX) = NULL,
    @PageNumber INT = 1,
    @PageSize INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (CASE WHEN @PageNumber < 1 THEN 0 ELSE @PageNumber - 1 END) * (CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END);
    DECLARE @Take INT = CASE WHEN @PageSize < 1 THEN 10 ELSE @PageSize END;
    DECLARE @AllowedStoreIdTable TABLE (StoreId INT);

    IF @IsAdmin = 0 AND @AllowedStoreIds IS NOT NULL AND LTRIM(RTRIM(@AllowedStoreIds)) <> ''
    BEGIN
        INSERT INTO @AllowedStoreIdTable (StoreId)
        SELECT TRY_CAST(value AS INT)
        FROM STRING_SPLIT(@AllowedStoreIds, ',')
        WHERE TRY_CAST(value AS INT) IS NOT NULL;
    END

    SELECT
        i.Id,
        i.PurchaseOrderNumber,
        i.InvoiceNo,
        i.PurchaseOrderId,
        i.VendorId,
        v.Name as VendorName,
        i.StoreId,
        s.StoreName,
        i.BranchId,
        b.Name as BranchName,
        i.IsActive,
        i.CreatedById,
        i.CreatedOn,
        i.ModifiedById,
        i.ModifiedOn,
        i.IsFinalized,
        i.StockTypeId,
        st.Name as StockTypeName,
        i.VendorInvoiceNumber,
        i.VendorInvoiceTimestamp,
        i.Amount,
        i.Discount,
        i.DiscountType,
        i.Total,
        i.PaidAmount,
        i.PaymentStatusId,
        i.TotalPaidAmount,
        i.PayableAccountId,
        i.IsPaymentPending,
        i.VoucherId,
        i.TotalVoucherPaidAmount,
        i.TotalBuyingPrice,
        i.ReceiptPath,
        i.AdvanceTaxPercentage,
        i.AdvanceTaxCalculatedAmount,
        i.RetailCharges,
        i.RetailChargesType,
        i.GSTCharges,
        i.RetailChargesCalculatedAmount,
        i.GSTChargesCalculatedAmount,
        i.ManualPurchaseOrderNumber,
        -- Calculate total quantity from details
        (SELECT ISNULL(SUM(TotalItems), 0) FROM Inv.InventoryDetails WHERE InventoryId = i.Id) as TotalQuantity,
        COUNT(*) OVER() AS TotalCount
    FROM Inv.Inventories i
    LEFT JOIN Inv.Vendors v ON i.VendorId = v.Id
    LEFT JOIN Inv.PharmacyStores s ON i.StoreId = s.StoreId
    LEFT JOIN Inv.Branches b ON i.BranchId = b.Id
    LEFT JOIN Inv.StockTypes st ON i.StockTypeId = st.Id
    WHERE i.IsActive = 1
        AND (@VendorId IS NULL OR i.VendorId = @VendorId)
        AND (@StoreId IS NULL OR i.StoreId = @StoreId)
        AND (@IsAdmin = 1 OR i.StoreId IN (SELECT StoreId FROM @AllowedStoreIdTable))
        AND (@DateFrom IS NULL OR i.CreatedOn >= @DateFrom)
        AND (@DateTo IS NULL OR i.CreatedOn <= @DateTo)
        AND (
            @SearchTerm IS NULL OR @SearchTerm = ''
            OR i.VendorInvoiceNumber LIKE '%' + @SearchTerm + '%'
            OR v.Name LIKE '%' + @SearchTerm + '%'
            OR st.Name LIKE '%' + @SearchTerm + '%'
        )
    ORDER BY i.CreatedOn DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;
END
