using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class StockFlowService : IStockFlowService
    {
        private readonly string _connectionString;
        private readonly ILogger<StockFlowService> _logger;

        public StockFlowService(IConfiguration configuration, ILogger<StockFlowService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<StockFlow>> GetStockFlowAsync(StockFlowSearchRequest request)
        {
            var stockFlows = new List<StockFlow>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockFlow_GetReport", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                // Add parameters
                command.Parameters.AddWithValue("@StartDate", request.StartDate.HasValue ? (object)request.StartDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", request.EndDate.HasValue ? (object)request.EndDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@Store", string.IsNullOrEmpty(request.Store) ? (object)DBNull.Value : request.Store);
                command.Parameters.AddWithValue("@Item", string.IsNullOrEmpty(request.Item) ? (object)DBNull.Value : request.Item);
                command.Parameters.AddWithValue("@InventoryNo", string.IsNullOrEmpty(request.InventoryNo) ? (object)DBNull.Value : request.InventoryNo);
                command.Parameters.AddWithValue("@ChallanNo", string.IsNullOrEmpty(request.ChallanNo) ? (object)DBNull.Value : request.ChallanNo);
                command.Parameters.AddWithValue("@InvoiceNo", string.IsNullOrEmpty(request.InvoiceNo) ? (object)DBNull.Value : request.InvoiceNo);
                command.Parameters.AddWithValue("@DemandRequestNo", string.IsNullOrEmpty(request.DemandRequestNo) ? (object)DBNull.Value : request.DemandRequestNo);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    stockFlows.Add(new StockFlow
                    {
                        DateTime = reader.GetDateTime(reader.GetOrdinal("DateTime")),
                        TransactionType = reader.GetString(reader.GetOrdinal("TransactionType")),
                        RefNumber = reader.IsDBNull(reader.GetOrdinal("RefNumber")) ? "" : reader.GetString(reader.GetOrdinal("RefNumber")),
                        ItemName = reader.GetString(reader.GetOrdinal("ItemName")),
                        DemandRequestedStore = reader.IsDBNull(reader.GetOrdinal("DemandRequestedStore")) ? "" : reader.GetString(reader.GetOrdinal("DemandRequestedStore")),
                        StockType = reader.GetString(reader.GetOrdinal("StockType")),
                        OpeningQuantity = reader.GetDecimal(reader.GetOrdinal("OpeningQuantity")),
                        ReceivedQuantity = reader.GetDecimal(reader.GetOrdinal("ReceivedQuantity")),
                        IssuedQuantity = reader.GetDecimal(reader.GetOrdinal("IssuedQuantity")),
                        BalanceQuantity = reader.GetDecimal(reader.GetOrdinal("BalanceQuantity")),
                        BatchNo = reader.IsDBNull(reader.GetOrdinal("BatchNo")) ? null : reader.GetString(reader.GetOrdinal("BatchNo")),
                        ActionBy = reader.IsDBNull(reader.GetOrdinal("ActionBy")) ? "" : reader.GetString(reader.GetOrdinal("ActionBy"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock flow");
                throw;
            }

            return stockFlows;
        }
    }
}
