using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class StockDetailRecordService : IStockDetailRecordService
    {
        private readonly string _connectionString;
        private readonly ILogger<StockDetailRecordService> _logger;

        public StockDetailRecordService(IConfiguration configuration, ILogger<StockDetailRecordService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<StockDetailRecord>> GetStockDetailRecordsAsync(StockDetailRecordSearchRequest request)
        {
            var records = new List<StockDetailRecord>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockDetailRecord_GetReport", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Branch", string.IsNullOrEmpty(request.Branch) ? (object)DBNull.Value : request.Branch);
                command.Parameters.AddWithValue("@StartDate", request.StartDate.HasValue ? (object)request.StartDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", request.EndDate.HasValue ? (object)request.EndDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@Store", string.IsNullOrEmpty(request.Store) ? (object)DBNull.Value : request.Store);
                command.Parameters.AddWithValue("@Vendor", string.IsNullOrEmpty(request.Vendor) ? (object)DBNull.Value : request.Vendor);
                command.Parameters.AddWithValue("@StockType", string.IsNullOrEmpty(request.StockType) ? (object)DBNull.Value : request.StockType);
                command.Parameters.AddWithValue("@Item", string.IsNullOrEmpty(request.Item) ? (object)DBNull.Value : request.Item);
                command.Parameters.AddWithValue("@ItemType", string.IsNullOrEmpty(request.ItemType) ? (object)DBNull.Value : request.ItemType);
                command.Parameters.AddWithValue("@SaleType", string.IsNullOrEmpty(request.SaleType) ? (object)DBNull.Value : request.SaleType);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                int sr = 1;
                while (await reader.ReadAsync())
                {
                    records.Add(new StockDetailRecord
                    {
                        Sr = sr++,
                        Name = reader.GetString(reader.GetOrdinal("Name")),
                        StockType = reader.GetString(reader.GetOrdinal("StockType")),
                        BuyingPrice = reader.GetDecimal(reader.GetOrdinal("BuyingPrice")),
                        SellingPrice = reader.GetDecimal(reader.GetOrdinal("SellingPrice")),
                        Opening = reader.GetInt32(reader.GetOrdinal("Opening")),
                        Received = reader.GetInt32(reader.GetOrdinal("Received")),
                        Issued = reader.GetInt32(reader.GetOrdinal("Issued")),
                        Balance = reader.GetInt32(reader.GetOrdinal("Balance"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock detail records");
                throw;
            }

            return records;
        }
    }
}
