using System.Data;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    public class DemandWiseValueService : IDemandWiseValueService
    {
        private readonly string _connectionString;
        private readonly ILogger<DemandWiseValueService> _logger;
        private readonly string _schemaPrefix;
        private readonly string _storesTable;

        public DemandWiseValueService(IConfiguration configuration, ILogger<DemandWiseValueService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
            var builder = new SqlConnectionStringBuilder(_connectionString);
            _schemaPrefix = builder.InitialCatalog.StartsWith("HMS", StringComparison.OrdinalIgnoreCase) ? "Inv" : "dbo";
            // DemandRequests.RequestedToStoreId is keyed into Inv.PharmacyStores, not the
            // near-empty legacy Inv.Stores table (Main Warehouse/OT Store/ER Store) whose ids
            // happen to overlap - same fix/reasoning as DemandRequestService's `_storesTable`
            // and the comment in StockFlow_GetReport.sql. Joining Inv.Stores here made every
            // row's StoreName miss (or, worse, match the wrong store where ids collide).
            _storesTable = _schemaPrefix == "Inv" ? "Inv.PharmacyStores" : "dbo.Stores";
        }

        private string NormalizeSql(string sql) => sql.Replace("dbo.", $"{_schemaPrefix}.");

        public async Task<DemandWiseValueResponse> GetAsync(DemandWiseValueFilter filter)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(filter.PageNumber, filter.PageSize);
            var response = new DemandWiseValueResponse { PageNumber = pageNumber, PageSize = pageSize };

            string sql = $@"
WITH IssuedEntries AS (
    SELECT
        dr.Id AS DemandRequestId,
        dr.DemandRequestNumber AS DRNo,
        COALESCE(drs.Name, 'Unknown') AS Status,
        dr.BranchId,
        b.Name AS BranchName,
        dr.RequestedToStoreId AS StoreId,
        s.StoreName,
        dri.ItemId,
        COALESCE(i.Name, 'Unassigned Item') AS ItemName,
        CAST(COALESCE(NULLIF(dri.IssuedQuantity, 0), NULLIF(dri.ApprovedQuantity, 0), dri.RequestedQuantity, 0) AS INT) AS IssuedQty,
        COALESCE(dr.IssuedDate, dr.ModifiedOn, dr.CreatedOn) AS IssuedDate,
        CASE
            WHEN COALESCE(it.Name, '') LIKE '%medicine%' OR i.Name LIKE 'Solution %' THEN 'Medicine(s)'
            WHEN i.Name LIKE '%Syringe%' OR i.Name LIKE '%Cannula%' OR i.Name LIKE '%Electrode%' OR i.Name LIKE '%Mask%' OR i.Name LIKE '%Gloves%' OR i.Name LIKE '%Gauze%' OR i.Name LIKE '%Pads%' OR i.Name LIKE '%Kit%' THEN 'Disposable(s)'
            ELSE 'Item(s)'
        END AS ItemType
    FROM dbo.DemandRequests dr
    INNER JOIN dbo.DemandRequestItems dri ON dri.DemandRequestId = dr.Id AND dri.IsActive = 1
    INNER JOIN dbo.Branches b ON b.Id = dr.BranchId
    INNER JOIN {_storesTable} s ON s.StoreId = dr.RequestedToStoreId
    LEFT JOIN dbo.Items i ON i.Id = dri.ItemId
    LEFT JOIN dbo.ItemTypes it ON it.Id = i.ItemTypeId
    LEFT JOIN dbo.DemandRequestStatuses drs ON drs.Id = dr.DemandRequestStatusId
    WHERE dr.IsActive = 1
      AND drs.Name IN ('Issued', 'Received', 'Approved')
),
LatestValue AS (
    SELECT
        inv.StoreId,
        det.ItemId,
        CAST(NULL AS NVARCHAR(100)) AS BatchNo,
        CAST(ISNULL(det.UnitBuyingPrice, 0) AS DECIMAL(18, 2)) AS UnitBuyingPrice,
        CAST(ISNULL(det.TotalBuyingPrice, 0) AS DECIMAL(18, 2)) AS PurchaseTotal,
        ROW_NUMBER() OVER (PARTITION BY inv.StoreId, det.ItemId ORDER BY inv.CreatedOn DESC, inv.Id DESC, det.Id DESC) AS RowNum
    FROM dbo.Inventories inv
    INNER JOIN dbo.InventoryDetails det ON det.InventoryId = inv.Id
    WHERE inv.IsActive = 1
),
Filtered AS (
    SELECT
        ie.ItemName,
        ie.DRNo,
        lv.BatchNo,
        ie.IssuedDate,
        ie.IssuedQty,
        ie.Status,
        COALESCE(lv.UnitBuyingPrice, 0) AS UnitBuyingPrice,
        CAST(ie.IssuedQty * COALESCE(lv.UnitBuyingPrice, 0) AS DECIMAL(18, 2)) AS TotalBuyingPrice,
        ie.ItemType,
        ie.BranchId,
        ie.BranchName,
        ie.StoreId,
        ie.StoreName,
        ie.ItemId
    FROM IssuedEntries ie
    LEFT JOIN LatestValue lv ON lv.StoreId = ie.StoreId AND lv.ItemId = ie.ItemId AND lv.RowNum = 1
    WHERE ie.IssuedQty > 0
      AND (@BranchId IS NULL OR ie.BranchId = @BranchId)
      AND (@StoreId IS NULL OR ie.StoreId = @StoreId)
      AND (@ItemId IS NULL OR ie.ItemId = @ItemId)
      AND (@StartDate IS NULL OR ie.IssuedDate >= @StartDate)
      AND (@EndDate IS NULL OR ie.IssuedDate <= @EndDate)
      AND (@ItemType IS NULL OR @ItemType = '' OR @ItemType = 'All' OR ie.ItemType = @ItemType)
      AND (
            @Search IS NULL
            OR ie.ItemName LIKE '%' + @Search + '%'
            OR ie.DRNo LIKE '%' + @Search + '%'
            OR ie.Status LIKE '%' + @Search + '%'
            OR ie.StoreName LIKE '%' + @Search + '%'
            OR ISNULL(lv.BatchNo, '') LIKE '%' + @Search + '%'
          )
)
-- Window aggregates below are computed over the whole filtered set (before
-- OFFSET/FETCH trims it), same trick as COUNT(*) OVER() AS TotalCount - so
-- Totals stay correct for the full result even though Items is just one page.
SELECT
    ItemName, DRNo, BatchNo, IssuedDate, IssuedQty, Status, UnitBuyingPrice, TotalBuyingPrice,
    ItemType, BranchId, BranchName, StoreId, StoreName, ItemId,
    COUNT(*) OVER() AS TotalCount,
    SUM(IssuedQty) OVER() AS TotalIssuedQtyAll,
    SUM(UnitBuyingPrice) OVER() AS TotalUnitBuyingPriceAll,
    SUM(TotalBuyingPrice) OVER() AS TotalBuyingPriceAll
FROM Filtered
ORDER BY IssuedDate DESC, DRNo DESC
OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection)
                {
                    CommandType = CommandType.Text
                };

                command.Parameters.AddWithValue("@BranchId", (object?)filter.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", (object?)filter.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemId", (object?)filter.ItemId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StartDate", (object?)filter.StartDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", (object?)filter.EndDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemType", string.IsNullOrWhiteSpace(filter.ItemType) ? DBNull.Value : filter.ItemType.Trim());
                command.Parameters.AddWithValue("@Search", string.IsNullOrWhiteSpace(filter.Search) ? DBNull.Value : filter.Search.Trim());
                command.Parameters.AddWithValue("@Offset", (pageNumber - 1) * pageSize);
                command.Parameters.AddWithValue("@PageSize", pageSize);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                var records = new List<DemandWiseValueRow>();
                var totals = new DemandWiseValueTotals();
                var sr = (pageNumber - 1) * pageSize + 1;
                while (await reader.ReadAsync())
                {
                    if (response.TotalCount == 0)
                    {
                        response.TotalCount = reader.GetInt32(reader.GetOrdinal("TotalCount"));
                        totals = new DemandWiseValueTotals
                        {
                            TotalIssuedQty = reader.GetInt32(reader.GetOrdinal("TotalIssuedQtyAll")),
                            TotalUnitBuyingPrice = reader.GetDecimal(reader.GetOrdinal("TotalUnitBuyingPriceAll")),
                            TotalBuyingPrice = reader.GetDecimal(reader.GetOrdinal("TotalBuyingPriceAll"))
                        };
                    }

                    var row = new DemandWiseValueRow
                    {
                        Sr = sr++,
                        ItemName = reader.GetString(reader.GetOrdinal("ItemName")),
                        DRNo = reader.GetString(reader.GetOrdinal("DRNo")),
                        BatchNo = reader.IsDBNull(reader.GetOrdinal("BatchNo")) ? null : reader.GetString(reader.GetOrdinal("BatchNo")),
                        IssuedDate = reader.GetDateTime(reader.GetOrdinal("IssuedDate")),
                        IssuedQty = reader.GetInt32(reader.GetOrdinal("IssuedQty")),
                        Status = reader.GetString(reader.GetOrdinal("Status")),
                        UnitBuyingPrice = reader.GetDecimal(reader.GetOrdinal("UnitBuyingPrice")),
                        TotalBuyingPrice = reader.GetDecimal(reader.GetOrdinal("TotalBuyingPrice")),
                        ItemType = reader.GetString(reader.GetOrdinal("ItemType")),
                        BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                        BranchName = reader.GetString(reader.GetOrdinal("BranchName")),
                        StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                        StoreName = reader.GetString(reader.GetOrdinal("StoreName")),
                        ItemId = reader.IsDBNull(reader.GetOrdinal("ItemId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemId"))
                    };

                    records.Add(row);
                }

                response.Items = records;
                response.Totals = totals;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand wise value report");
                throw;
            }

            return response;
        }
    }
}
