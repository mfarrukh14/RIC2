-- =============================================
-- Expired Stock Report Stored Procedure
-- =============================================

USE InventoryManagementDB_SP;
GO

CREATE OR ALTER PROCEDURE ExpiredStock_GetReport
    @StoreName NVARCHAR(255) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL,
    @Item NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Get items that have already expired (ExpDate < GETDATE())
    SELECT 
        i.Name,
        st.StockTypeName AS StockType,
        grni.BatchNo,
        grni.MfgDate,
        grni.ExpiryDate AS ExpDate,
        grni.RemainingQuantity AS TotalItems
    FROM dbo.GRNItems grni
    INNER JOIN dbo.GoodsReceivingNotes grn ON grni.GRNId = grn.Id
    INNER JOIN dbo.Items i ON grni.ItemId = i.Id
    LEFT JOIN dbo.StockTypes st ON grn.StockTypeId = st.StockTypeId
    WHERE grni.ExpiryDate < GETDATE()
        AND grni.RemainingQuantity > 0
        AND (@StartDate IS NULL OR grni.ExpiryDate >= @StartDate)
        AND (@EndDate IS NULL OR grni.ExpiryDate <= @EndDate)
        AND (@Item IS NULL OR i.Name LIKE '%' + @Item + '%')
    ORDER BY grni.ExpiryDate ASC;
END
GO

PRINT 'Expired Stock stored procedure created successfully.';
GO
