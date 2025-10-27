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
                using var command = new SqlCommand("Stock_Search", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                // Add parameters
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemTypeId", (object?)request.ItemTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemId", (object?)request.ItemId ?? DBNull.Value);
                command.Parameters.AddWithValue("@CategoryIds", (object?)request.CategoryIds ?? DBNull.Value);
                command.Parameters.AddWithValue("@StockTypeId", (object?)request.StockTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@GeneralType", (object?)request.GeneralType ?? DBNull.Value);
                command.Parameters.AddWithValue("@MedicineTypeId", (object?)request.MedicineTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StockAvailability", (object?)request.StockAvailability ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsVaccine", (object?)request.IsVaccine ?? DBNull.Value);
                command.Parameters.AddWithValue("@MinimumPanicLevelOnly", request.MinimumPanicLevelOnly);

                await connection.OpenAsync();
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

        private static Stock MapStockFromReader(SqlDataReader reader)
        {
            return new Stock
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.GetString(reader.GetOrdinal("ItemName")),
                StockType = reader.IsDBNull(reader.GetOrdinal("StockType")) ? null : reader.GetString(reader.GetOrdinal("StockType")),
                TotalItems = reader.IsDBNull(reader.GetOrdinal("TotalItems")) ? null : reader.GetInt32(reader.GetOrdinal("TotalItems")),
                MinimumPanicLevel = reader.IsDBNull(reader.GetOrdinal("MinimumPanicLevel")) ? null : reader.GetInt32(reader.GetOrdinal("MinimumPanicLevel")),
                StoreId = reader.GetGuid(reader.GetOrdinal("StoreId")),
                BranchId = reader.GetGuid(reader.GetOrdinal("BranchId")),
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
