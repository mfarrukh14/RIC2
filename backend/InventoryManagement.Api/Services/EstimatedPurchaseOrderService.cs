using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class EstimatedPurchaseOrderService : IEstimatedPurchaseOrderService
    {
        private readonly string _connectionString;
        private readonly ILogger<EstimatedPurchaseOrderService> _logger;

        public EstimatedPurchaseOrderService(IConfiguration configuration, ILogger<EstimatedPurchaseOrderService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<EstimatedPurchaseOrderItem>> GetEstimatedPurchaseOrdersAsync(EstimatedPurchaseOrderSearchRequest request)
        {
            var items = new List<EstimatedPurchaseOrderItem>();
            var effectiveEndDate = request.EndDate?.Date.AddDays(1).AddTicks(-1) ?? DateTime.UtcNow;
            var effectiveStartDate = request.StartDate?.Date ?? effectiveEndDate.Date.AddDays(-30);
            var reportDays = Math.Max(1, (effectiveEndDate.Date - effectiveStartDate.Date).Days + 1);
            var deliveryLeadTimeDays = request.DeliveryLeadTimeDays <= 0 ? 7 : request.DeliveryLeadTimeDays;
            var safetyStock = request.SafetyStock < 0 ? 0 : request.SafetyStock;

            const string query = @"
WITH ReceiptTotals AS (
    SELECT
        inv.StoreId,
        det.ItemId,
        SUM(CAST(ISNULL(det.TotalItems, 0) AS DECIMAL(18, 2))) AS ReceivedQuantity,
        MAX(inv.CreatedOn) AS LastReceiptDate
    FROM dbo.Inventories inv
    INNER JOIN dbo.InventoryDetails det ON det.InventoryId = inv.Id
    WHERE inv.IsActive = 1
      AND (@EndDate IS NULL OR inv.CreatedOn <= @EndDate)
    GROUP BY inv.StoreId, det.ItemId
),
LatestReceipt AS (
    SELECT
        inv.StoreId,
        det.ItemId,
        inv.VendorId,
        det.ManufacturerId,
        CAST(ISNULL(det.UnitBuyingPrice, 0) AS DECIMAL(18, 2)) AS UnitBuyingPrice,
        ROW_NUMBER() OVER (
            PARTITION BY inv.StoreId, det.ItemId
            ORDER BY inv.CreatedOn DESC, inv.Id DESC, det.Id DESC
        ) AS RowNum
    FROM dbo.Inventories inv
    INNER JOIN dbo.InventoryDetails det ON det.InventoryId = inv.Id
    WHERE inv.IsActive = 1
      AND (@EndDate IS NULL OR inv.CreatedOn <= @EndDate)
),
ConsumptionTotals AS (
    SELECT
        TRY_CONVERT(INT, RIGHT(CONVERT(VARCHAR(36), sc.StoreId), 12)) AS StoreId,
        scd.ItemId,
        SUM(CASE
            WHEN sc.CreatedOn >= @StartDate AND sc.CreatedOn <= @EndDate THEN CAST(ISNULL(scd.Quantity, 0) AS DECIMAL(18, 2))
            ELSE 0
        END) AS ConsumedQuantity,
        SUM(CASE
            WHEN sc.CreatedOn <= @EndDate THEN CAST(ISNULL(scd.Quantity, 0) AS DECIMAL(18, 2))
            ELSE 0
        END) AS TotalConsumedToDate
    FROM dbo.StockConsumptions sc
    INNER JOIN dbo.StockConsumptionDetails scd ON scd.StockConsumptionId = sc.Id
    WHERE sc.IsDeleted = 0
      AND scd.IsDeleted = 0
      AND (@EndDate IS NULL OR sc.CreatedOn <= @EndDate)
    GROUP BY TRY_CONVERT(INT, RIGHT(CONVERT(VARCHAR(36), sc.StoreId), 12)), scd.ItemId
)
SELECT
    itm.Id AS ItemId,
    itm.Name AS ItemName,
    it.Name AS ItemTypeName,
    st.StoreId,
    st.StoreName,
    lr.VendorId,
    v.Name AS VendorName,
    lr.ManufacturerId,
    m.Name AS ManufacturerName,
    rt.ReceivedQuantity,
    ISNULL(ct.ConsumedQuantity, 0) AS ConsumedQuantity,
    CASE
        WHEN rt.ReceivedQuantity - ISNULL(ct.TotalConsumedToDate, 0) > 0 THEN rt.ReceivedQuantity - ISNULL(ct.TotalConsumedToDate, 0)
        ELSE 0
    END AS CurrentStock,
    CAST(ISNULL(ct.ConsumedQuantity, 0) / @ReportDays AS DECIMAL(18, 2)) AS AverageDailyConsumption,
    @DeliveryLeadTimeDays AS DeliveryLeadTimeDays,
    @SafetyStock AS SafetyStock,
    CEILING(CASE
        WHEN ((ISNULL(ct.ConsumedQuantity, 0) / @ReportDays) * @DeliveryLeadTimeDays) + @SafetyStock
             - CASE WHEN rt.ReceivedQuantity - ISNULL(ct.TotalConsumedToDate, 0) > 0 THEN rt.ReceivedQuantity - ISNULL(ct.TotalConsumedToDate, 0) ELSE 0 END > 0
            THEN ((ISNULL(ct.ConsumedQuantity, 0) / @ReportDays) * @DeliveryLeadTimeDays) + @SafetyStock
                 - CASE WHEN rt.ReceivedQuantity - ISNULL(ct.TotalConsumedToDate, 0) > 0 THEN rt.ReceivedQuantity - ISNULL(ct.TotalConsumedToDate, 0) ELSE 0 END
        ELSE 0
    END) AS RecommendedOrderQuantity,
    CASE
        WHEN ISNULL(ct.ConsumedQuantity, 0) >= COALESCE(NULLIF(levels.FastRunningLevel, 0), 40) THEN 'Fast Running Items'
        WHEN ISNULL(ct.ConsumedQuantity, 0) <= COALESCE(levels.DeadLevel, 0) THEN 'Dead Items'
        ELSE 'Slow Moving Items'
    END AS RunningCategory,
    lr.UnitBuyingPrice,
    rt.LastReceiptDate
FROM ReceiptTotals rt
INNER JOIN dbo.Items itm ON itm.Id = rt.ItemId
INNER JOIN dbo.Stores st ON st.StoreId = rt.StoreId
LEFT JOIN dbo.ItemTypes it ON it.Id = itm.ItemTypeId
LEFT JOIN LatestReceipt lr ON lr.StoreId = rt.StoreId AND lr.ItemId = rt.ItemId AND lr.RowNum = 1
LEFT JOIN dbo.Vendors v ON v.Id = lr.VendorId
LEFT JOIN dbo.Manufacturers m ON m.Id = lr.ManufacturerId
LEFT JOIN ConsumptionTotals ct ON ct.StoreId = rt.StoreId AND ct.ItemId = rt.ItemId
LEFT JOIN dbo.ItemTypeSaleLevels levels ON levels.ItemTypeId = itm.ItemTypeId AND levels.IsDeleted = 0 AND levels.IsActive = 1
WHERE (@StoreId IS NULL OR rt.StoreId = @StoreId)
  AND (@VendorId IS NULL OR lr.VendorId = @VendorId)
  AND (@ManufacturerId IS NULL OR lr.ManufacturerId = @ManufacturerId)
  AND (rt.ReceivedQuantity > 0 OR ISNULL(ct.TotalConsumedToDate, 0) > 0)
ORDER BY
    RecommendedOrderQuantity DESC,
    ItemName ASC;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(query, connection)
                {
                    CommandType = CommandType.Text
                };

                command.Parameters.AddWithValue("@StoreId", request.StoreId.HasValue ? (object)request.StoreId.Value : DBNull.Value);
                command.Parameters.AddWithValue("@VendorId", request.VendorId.HasValue ? (object)request.VendorId.Value : DBNull.Value);
                command.Parameters.AddWithValue("@ManufacturerId", request.ManufacturerId.HasValue ? (object)request.ManufacturerId.Value : DBNull.Value);
                command.Parameters.AddWithValue("@StartDate", effectiveStartDate);
                command.Parameters.AddWithValue("@EndDate", effectiveEndDate);
                command.Parameters.AddWithValue("@ReportDays", reportDays);
                command.Parameters.AddWithValue("@DeliveryLeadTimeDays", deliveryLeadTimeDays);
                command.Parameters.AddWithValue("@SafetyStock", safetyStock);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    items.Add(new EstimatedPurchaseOrderItem
                    {
                        ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                        ItemName = reader.GetString(reader.GetOrdinal("ItemName")),
                        ItemTypeName = reader.IsDBNull(reader.GetOrdinal("ItemTypeName")) ? null : reader.GetString(reader.GetOrdinal("ItemTypeName")),
                        StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                        StoreName = reader.GetString(reader.GetOrdinal("StoreName")),
                        VendorId = reader.IsDBNull(reader.GetOrdinal("VendorId")) ? null : reader.GetInt32(reader.GetOrdinal("VendorId")),
                        VendorName = reader.IsDBNull(reader.GetOrdinal("VendorName")) ? null : reader.GetString(reader.GetOrdinal("VendorName")),
                        ManufacturerId = reader.IsDBNull(reader.GetOrdinal("ManufacturerId")) ? null : reader.GetInt32(reader.GetOrdinal("ManufacturerId")),
                        ManufacturerName = reader.IsDBNull(reader.GetOrdinal("ManufacturerName")) ? null : reader.GetString(reader.GetOrdinal("ManufacturerName")),
                        ReceivedQuantity = reader.GetDecimal(reader.GetOrdinal("ReceivedQuantity")),
                        ConsumedQuantity = reader.GetDecimal(reader.GetOrdinal("ConsumedQuantity")),
                        CurrentStock = reader.GetDecimal(reader.GetOrdinal("CurrentStock")),
                        AverageDailyConsumption = reader.GetDecimal(reader.GetOrdinal("AverageDailyConsumption")),
                        DeliveryLeadTimeDays = reader.GetInt32(reader.GetOrdinal("DeliveryLeadTimeDays")),
                        SafetyStock = reader.GetDecimal(reader.GetOrdinal("SafetyStock")),
                        RecommendedOrderQuantity = reader.GetDecimal(reader.GetOrdinal("RecommendedOrderQuantity")),
                        RunningCategory = reader.GetString(reader.GetOrdinal("RunningCategory")),
                        UnitBuyingPrice = reader.GetDecimal(reader.GetOrdinal("UnitBuyingPrice")),
                        LastReceiptDate = reader.IsDBNull(reader.GetOrdinal("LastReceiptDate")) ? null : reader.GetDateTime(reader.GetOrdinal("LastReceiptDate"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving estimated purchase order data");
                throw;
            }

            return items;
        }
    }
}