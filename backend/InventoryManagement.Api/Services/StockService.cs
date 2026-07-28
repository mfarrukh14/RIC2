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

        public async Task<IEnumerable<Stock>> SearchStocksAsync(StockSearchRequest request)
        {
            var stocks = new List<Stock>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var command = await CreateSearchCommandAsync(connection, request);
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    stocks.Add(MapStockFromReader(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching stocks");
                throw;
            }

            return stocks;
        }

        private async Task<SqlCommand> CreateSearchCommandAsync(SqlConnection connection, StockSearchRequest request)
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

                return procedureCommand;
            }

            return CreateFallbackSearchCommand(connection, request);
        }

        private static SqlCommand CreateFallbackSearchCommand(SqlConnection connection, StockSearchRequest request)
        {
            var command = new SqlCommand(
                @"
DECLARE @CategoryIdTable TABLE (CategoryId INT);

IF @CategoryIds IS NOT NULL AND LTRIM(RTRIM(@CategoryIds)) <> ''
BEGIN
    INSERT INTO @CategoryIdTable (CategoryId)
    SELECT TRY_CAST(value AS INT)
    FROM STRING_SPLIT(@CategoryIds, ',')
    WHERE TRY_CAST(value AS INT) IS NOT NULL;
END

SELECT
    s.Id,
    i.Id AS ItemId,
    i.Name AS ItemName,
    COALESCE(st.Name, 'Regular') AS StockType,
    s.TotalItems,
    COALESCE(s.MinimumPanicLevel, i.MinimumPanicLevel, 0) AS MinimumPanicLevel,
    s.StoreId,
    s.BranchId,
    s.IsActive,
    s.ModifiedOn,
    i.ItemTypeId,
    it.Name AS ItemTypeName,
    c.Name AS CategoryName,
    i.IsFridgeItem,
    i.IsConsumptionItem
FROM Inv.Stocks s
INNER JOIN Inv.Items i ON s.ItemId = i.Id
LEFT JOIN Inv.ItemTypes it ON i.ItemTypeId = it.Id
LEFT JOIN Inv.Categories c ON i.CategoryId = c.Id
OUTER APPLY
(
    SELECT TOP 1 inv.StockTypeId
    FROM Inv.InventoryDetails details
    INNER JOIN Inv.Inventories inv ON details.InventoryId = inv.Id
    WHERE details.ItemId = s.ItemId
      AND inv.StoreId = s.StoreId
      AND inv.IsActive = 1
    ORDER BY COALESCE(inv.ModifiedOn, inv.CreatedOn) DESC, inv.Id DESC
) latestInventory
LEFT JOIN Inv.StockTypes st ON latestInventory.StockTypeId = st.Id
WHERE s.IsActive = 1
  AND (@BranchId IS NULL OR s.BranchId = @BranchId)
  AND (@StoreId IS NULL OR s.StoreId = @StoreId)
  AND (@ItemTypeId IS NULL OR i.ItemTypeId = @ItemTypeId)
  AND (@ItemId IS NULL OR i.Id = @ItemId)
  AND (@StockTypeId IS NULL OR latestInventory.StockTypeId = @StockTypeId)
  AND (
        @CategoryIds IS NULL
        OR LTRIM(RTRIM(@CategoryIds)) = ''
        OR i.CategoryId IN (SELECT CategoryId FROM @CategoryIdTable)
      )
  AND (
        @StockAvailability IS NULL
        OR @StockAvailability = 'All'
        OR (@StockAvailability = 'InStock' AND s.TotalItems > 0)
        OR (@StockAvailability = 'OutOfStock' AND COALESCE(s.TotalItems, 0) <= 0)
      )
  AND (
        @MinimumPanicLevelOnly = 0
        OR COALESCE(s.TotalItems, 0) <= COALESCE(s.MinimumPanicLevel, i.MinimumPanicLevel, 0)
      )
ORDER BY i.Name ASC;",
                connection)
            {
                CommandType = CommandType.Text
            };

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
                ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.GetString(reader.GetOrdinal("ItemName")),
                StockType = reader.IsDBNull(reader.GetOrdinal("StockType")) ? null : reader.GetString(reader.GetOrdinal("StockType")),
                TotalItems = reader.IsDBNull(reader.GetOrdinal("TotalItems")) ? null : reader.GetInt32(reader.GetOrdinal("TotalItems")),
                // COALESCE(s.MinimumPanicLevel [int], i.MinimumPanicLevel [real], 0) gets promoted to
                // real by SQL Server's type precedence rules, so the reader hands back a Single here.
                MinimumPanicLevel = reader.IsDBNull(reader.GetOrdinal("MinimumPanicLevel")) ? null : Convert.ToInt32(reader.GetValue(reader.GetOrdinal("MinimumPanicLevel"))),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                ItemTypeId = reader.IsDBNull(reader.GetOrdinal("ItemTypeId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemTypeId")),
                ItemTypeName = reader.IsDBNull(reader.GetOrdinal("ItemTypeName")) ? null : reader.GetString(reader.GetOrdinal("ItemTypeName")),
                CategoryName = reader.IsDBNull(reader.GetOrdinal("CategoryName")) ? null : reader.GetString(reader.GetOrdinal("CategoryName")),
                IsFridgeItem = reader.IsDBNull(reader.GetOrdinal("IsFridgeItem")) ? null : reader.GetBoolean(reader.GetOrdinal("IsFridgeItem")),
                IsConsumptionItem = reader.IsDBNull(reader.GetOrdinal("IsConsumptionItem")) ? null : reader.GetBoolean(reader.GetOrdinal("IsConsumptionItem"))
            };
        }
    }
}
