using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public class StockService : IStockService
    {
        private readonly string _connectionString;
        private readonly ILogger<StockService> _logger;

        public StockService(IConfiguration configuration, ILogger<StockService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string not found");
            _logger = logger;
        }

        // Used by the Place Demand item picker so it can show a live quantity next to every
        // item for the currently selected Requested Store - LEFT JOIN so items with no
        // Pharmacy.PharmacyMedicinesStocks row at that store still appear, at 0, instead of
        // vanishing. Reads the live stock ledger (see Stock_Procedures.sql header for why
        // this isn't Inv.Stocks) - no IsActive column exists there, so none is filtered.
        public async Task<Dictionary<int, int>> GetQuantitiesByStoreAsync(int storeId)
        {
            var quantities = new Dictionary<int, int>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(@"
SELECT i.Id AS ItemId, ISNULL(p.TotalItemsInStock, 0) AS Quantity
FROM Inv.Items i
LEFT JOIN Pharmacy.PharmacyMedicinesStocks p ON p.ItemId = i.Id AND p.StoreId = @StoreId
WHERE i.IsActive = 1;", connection);
                command.Parameters.Add("@StoreId", SqlDbType.Int).Value = storeId;

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    quantities[reader.GetInt32(0)] = Convert.ToInt32(reader.GetDecimal(1));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock quantities for store {StoreId}", storeId);
                throw;
            }

            return quantities;
        }

        // Updates the reorder/panic-level threshold for a single stock row - the one field
        // on this screen the old system's "Update" action actually edits (item name, store,
        // on-hand quantity are all derived/transactional, not directly editable from the
        // Stock list). No IsActive column on Pharmacy.PharmacyMedicinesStocks to filter by.
        public async Task<bool> UpdateMinimumPanicLevelAsync(int stockId, int minimumPanicLevel)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(
                "UPDATE Pharmacy.PharmacyMedicinesStocks SET MinimumPanicLevel = @MinimumPanicLevel, ModifiedOn = GETDATE() WHERE ID = @Id;",
                connection);
            command.Parameters.Add("@Id", SqlDbType.Int).Value = stockId;
            command.Parameters.Add("@MinimumPanicLevel", SqlDbType.Int).Value = minimumPanicLevel;

            await connection.OpenAsync();
            var rowsAffected = await command.ExecuteNonQueryAsync();
            return rowsAffected > 0;
        }

        public async Task<PagedResult<Stock>> SearchStocksAsync(StockSearchRequest request)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(request.PageNumber, request.PageSize);
            var result = new PagedResult<Stock> { PageNumber = pageNumber, PageSize = pageSize };
            var stocks = new List<Stock>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var command = await CreateSearchCommandAsync(connection, request, pageNumber, pageSize);
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    if (result.TotalCount == 0)
                    {
                        result.TotalCount = PaginationHelper.ReadTotalCount(reader);
                    }

                    stocks.Add(MapStockFromReader(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching stocks");
                throw;
            }

            result.Items = stocks;
            return result;
        }

        private async Task<SqlCommand> CreateSearchCommandAsync(SqlConnection connection, StockSearchRequest request, int pageNumber, int pageSize)
        {
            if (await StoredProcedureExistsAsync(connection, "Stock_Search"))
            {
                var procedureCommand = new SqlCommand("Stock_Search", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                procedureCommand.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                procedureCommand.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
                procedureCommand.Parameters.AddWithValue("@ItemTypeId", (object?)request.ItemTypeId ?? DBNull.Value);
                procedureCommand.Parameters.AddWithValue("@ItemId", (object?)request.ItemId ?? DBNull.Value);
                procedureCommand.Parameters.AddWithValue("@CategoryIds", (object?)request.CategoryIds ?? DBNull.Value);
                procedureCommand.Parameters.AddWithValue("@StockTypeId", (object?)request.StockTypeId ?? DBNull.Value);
                procedureCommand.Parameters.AddWithValue("@GeneralType", (object?)request.GeneralType ?? DBNull.Value);
                procedureCommand.Parameters.AddWithValue("@MedicineTypeId", (object?)request.MedicineTypeId ?? DBNull.Value);
                procedureCommand.Parameters.AddWithValue("@StockAvailability", (object?)request.StockAvailability ?? DBNull.Value);
                procedureCommand.Parameters.AddWithValue("@IsVaccine", (object?)request.IsVaccine ?? DBNull.Value);
                procedureCommand.Parameters.AddWithValue("@MinimumPanicLevelOnly", request.MinimumPanicLevelOnly);
                PaginationHelper.AddPagingParameters(procedureCommand, pageNumber, pageSize);

                return procedureCommand;
            }

            return CreateFallbackSearchCommand(connection, request, pageNumber, pageSize);
        }

        private static SqlCommand CreateFallbackSearchCommand(SqlConnection connection, StockSearchRequest request, int pageNumber, int pageSize)
        {
            var command = new SqlCommand(
                @"
DECLARE @CategoryIdTable TABLE (CategoryId INT);
DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

IF @CategoryIds IS NOT NULL AND LTRIM(RTRIM(@CategoryIds)) <> ''
BEGIN
    INSERT INTO @CategoryIdTable (CategoryId)
    SELECT TRY_CAST(value AS INT)
    FROM STRING_SPLIT(@CategoryIds, ',')
    WHERE TRY_CAST(value AS INT) IS NOT NULL;
END

;WITH FilteredStock AS (
    SELECT
        p.ID AS Id,
        p.ItemId,
        p.SysBatchNo,
        p.BatchNo,
        COALESCE(i.Name, bm.MedicineName, bf.Name) AS ResolvedName,
        COALESCE(st.Name, 'Regular') AS StockType,
        p.TotalItemsInStock AS TotalItems,
        COALESCE(p.MinimumPanicLevel, i.MinimumPanicLevel, 0) AS MinimumPanicLevel,
        p.StoreId,
        ps.BranchId,
        p.ModifiedOn,
        i.ItemTypeId,
        COALESCE(it.Name, CASE WHEN p.TypeBit = 4 THEN 'Medicine' WHEN p.TypeBit = 5 THEN 'Fee' ELSE NULL END) AS ItemTypeName,
        c.Name AS CategoryName,
        i.IsFridgeItem,
        i.IsConsumptionItem
    FROM Pharmacy.PharmacyMedicinesStocks p
    LEFT JOIN Inv.PharmacyStores ps ON ps.StoreId = p.StoreId
    LEFT JOIN Inv.Items i ON p.ItemId = i.Id
    LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
    LEFT JOIN Inv.Categories c ON i.CategoryId = c.Id
    LEFT JOIN Inv.StockTypes st ON p.StockTypeId = st.Id
    LEFT JOIN Pharmacy.BranchMedicines bm ON bm.Id = p.BranchMedicineId
    LEFT JOIN Data.BranchFees bf ON bf.Id = p.BranchSubServiceId
    WHERE (@BranchId IS NULL OR ps.BranchId = @BranchId)
      AND (@StoreId IS NULL OR p.StoreId = @StoreId)
      AND (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
      AND (@ItemId IS NULL OR p.ItemId = @ItemId)
      AND (@StockTypeId IS NULL OR p.StockTypeId = @StockTypeId)
      AND (
            @CategoryIds IS NULL
            OR LTRIM(RTRIM(@CategoryIds)) = ''
            OR i.CategoryId IN (SELECT CategoryId FROM @CategoryIdTable)
          )
      AND (
            @StockAvailability IS NULL
            OR @StockAvailability = 'All'
            OR (@StockAvailability = 'InStock' AND p.TotalItemsInStock > 0)
            OR (@StockAvailability = 'OutOfStock' AND COALESCE(p.TotalItemsInStock, 0) <= 0)
          )
      AND (
            @MinimumPanicLevelOnly = 0
            OR COALESCE(p.TotalItemsInStock, 0) <= COALESCE(p.MinimumPanicLevel, i.MinimumPanicLevel, 0)
          )
),
Paged AS (
    SELECT *, COUNT(*) OVER() AS TotalCount
    FROM FilteredStock
    ORDER BY ResolvedName ASC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY
)
SELECT
    Paged.Id,
    Paged.ItemId,
    COALESCE(Paged.ResolvedName, grnItem.DenormalizedItemName, '(item not found)') AS ItemName,
    Paged.StockType,
    Paged.TotalItems,
    Paged.MinimumPanicLevel,
    Paged.StoreId,
    Paged.BranchId,
    CAST(1 AS BIT) AS IsActive,
    Paged.ModifiedOn,
    Paged.ItemTypeId,
    Paged.ItemTypeName,
    Paged.CategoryName,
    Paged.IsFridgeItem,
    Paged.IsConsumptionItem,
    CAST(NULL AS NVARCHAR(200)) AS Location,
    Paged.TotalCount
FROM Paged
OUTER APPLY
(
    SELECT TOP 1 gi.DenormalizedItemName
    FROM Inv.GoodsReceivingNotes g
    INNER JOIN Inv.GRNItems gi ON gi.GRNId = g.Id
    WHERE Paged.ResolvedName IS NULL
      AND g.InvoiceNo = Paged.SysBatchNo
      AND gi.BatchNo = Paged.BatchNo
    ORDER BY gi.Id DESC
) grnItem
ORDER BY ItemName ASC;",
                connection)
            {
                CommandType = CommandType.Text
            };

            command.Parameters.Add("@PageNumber", SqlDbType.Int).Value = pageNumber;
            command.Parameters.Add("@PageSize", SqlDbType.Int).Value = pageSize;
            command.Parameters.Add("@BranchId", SqlDbType.Int).Value = (object?)request.BranchId ?? DBNull.Value;
            command.Parameters.Add("@StoreId", SqlDbType.Int).Value = (object?)request.StoreId ?? DBNull.Value;
            command.Parameters.Add("@ItemTypeId", SqlDbType.Int).Value = (object?)request.ItemTypeId ?? DBNull.Value;
            command.Parameters.Add("@ItemId", SqlDbType.Int).Value = (object?)request.ItemId ?? DBNull.Value;
            command.Parameters.Add("@CategoryIds", SqlDbType.NVarChar, -1).Value = string.IsNullOrWhiteSpace(request.CategoryIds) ? DBNull.Value : request.CategoryIds;
            command.Parameters.Add("@StockTypeId", SqlDbType.Int).Value = (object?)request.StockTypeId ?? DBNull.Value;
            command.Parameters.Add("@StockAvailability", SqlDbType.NVarChar, 20).Value = string.IsNullOrWhiteSpace(request.StockAvailability) ? DBNull.Value : request.StockAvailability;
            command.Parameters.Add("@MinimumPanicLevelOnly", SqlDbType.Bit).Value = request.MinimumPanicLevelOnly;

            return command;
        }

        private static async Task<bool> StoredProcedureExistsAsync(SqlConnection connection, string procedureName)
        {
            using var command = new SqlCommand(
                "SELECT COUNT(1) FROM sys.procedures WHERE name = @ProcedureName",
                connection);

            command.Parameters.Add("@ProcedureName", SqlDbType.NVarChar, 128).Value = procedureName;

            return Convert.ToInt32(await command.ExecuteScalarAsync()) > 0;
        }

        private static Stock MapStockFromReader(SqlDataReader reader)
        {
            return new Stock
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                // NULL for Medicine/Fee-sourced rows (TypeBit 4/5) - see Stock_Procedures.sql header.
                ItemId = reader.IsDBNull(reader.GetOrdinal("ItemId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.GetString(reader.GetOrdinal("ItemName")),
                StockType = reader.IsDBNull(reader.GetOrdinal("StockType")) ? null : reader.GetString(reader.GetOrdinal("StockType")),
                TotalItems = reader.IsDBNull(reader.GetOrdinal("TotalItems")) ? null : reader.GetDecimal(reader.GetOrdinal("TotalItems")),
                // COALESCE(p.MinimumPanicLevel [int], i.MinimumPanicLevel [real], 0) gets promoted to
                // real by SQL Server's type precedence rules, so the reader hands back a Single here.
                MinimumPanicLevel = reader.IsDBNull(reader.GetOrdinal("MinimumPanicLevel")) ? null : Convert.ToInt32(reader.GetValue(reader.GetOrdinal("MinimumPanicLevel"))),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                // NULL when the store has no resolvable branch via Pharmacy.PharmacyStores.
                BranchId = reader.IsDBNull(reader.GetOrdinal("BranchId")) ? null : reader.GetInt32(reader.GetOrdinal("BranchId")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                ItemTypeId = reader.IsDBNull(reader.GetOrdinal("ItemTypeId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemTypeId")),
                ItemTypeName = reader.IsDBNull(reader.GetOrdinal("ItemTypeName")) ? null : reader.GetString(reader.GetOrdinal("ItemTypeName")),
                CategoryName = reader.IsDBNull(reader.GetOrdinal("CategoryName")) ? null : reader.GetString(reader.GetOrdinal("CategoryName")),
                IsFridgeItem = reader.IsDBNull(reader.GetOrdinal("IsFridgeItem")) ? null : reader.GetBoolean(reader.GetOrdinal("IsFridgeItem")),
                IsConsumptionItem = reader.IsDBNull(reader.GetOrdinal("IsConsumptionItem")) ? null : reader.GetBoolean(reader.GetOrdinal("IsConsumptionItem")),
                Location = reader.IsDBNull(reader.GetOrdinal("Location")) ? null : reader.GetString(reader.GetOrdinal("Location"))
            };
        }
    }
}
