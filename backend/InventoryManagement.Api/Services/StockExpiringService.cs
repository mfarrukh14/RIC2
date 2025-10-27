using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class StockExpiringService : IStockExpiringService
    {
        private readonly string _connectionString;
        private readonly ILogger<StockExpiringService> _logger;

        public StockExpiringService(IConfiguration configuration, ILogger<StockExpiringService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
            _logger = logger;
        }

        public async Task<IEnumerable<StockExpiringItem>> GetExpiringStockAsync(StockExpiringRequest request)
        {
            var items = new List<StockExpiringItem>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockExpiring_GetExpiringStock", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StartDate", (object?)request.StartDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", (object?)request.EndDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemIds", (object?)request.ItemIds ?? DBNull.Value);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    items.Add(new StockExpiringItem
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        ItemName = reader.GetString(reader.GetOrdinal("ItemName")),
                        StockType = reader.IsDBNull(reader.GetOrdinal("StockType"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("StockType")),
                        BatchNo = reader.IsDBNull(reader.GetOrdinal("BatchNo"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("BatchNo")),
                        MfgDate = reader.IsDBNull(reader.GetOrdinal("MfgDate"))
                            ? null
                            : reader.GetDateTime(reader.GetOrdinal("MfgDate")),
                        ExpiryDate = reader.IsDBNull(reader.GetOrdinal("ExpiryDate"))
                            ? null
                            : reader.GetDateTime(reader.GetOrdinal("ExpiryDate")),
                        TotalItems = reader.GetInt32(reader.GetOrdinal("TotalItems")),
                        StoreId = reader.IsDBNull(reader.GetOrdinal("StoreId"))
                            ? null
                            : reader.GetInt32(reader.GetOrdinal("StoreId")),
                        StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("StoreName"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving expiring stock");
                throw;
            }

            return items;
        }
    }
}
