using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class StockBalanceReportService : IStockBalanceReportService
    {
        private readonly string _connectionString;
        private readonly ILogger<StockBalanceReportService> _logger;

        public StockBalanceReportService(IConfiguration configuration, ILogger<StockBalanceReportService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<StockBalanceReport> GetStockBalanceReportAsync(StockBalanceSearchRequest request)
        {
            var report = new StockBalanceReport
            {
                User = "Mr. Branch Administrator",
                FromDate = request.StartDate ?? DateTime.Now,
                ToDate = request.EndDate ?? DateTime.Now,
                StoreName = request.Store ?? "All Stores",
                Summary = new StockSummary()
            };

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockBalance_GetReport", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@StartDate", request.StartDate.HasValue ? (object)request.StartDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", request.EndDate.HasValue ? (object)request.EndDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@Store", string.IsNullOrEmpty(request.Store) ? (object)DBNull.Value : request.Store);
                command.Parameters.AddWithValue("@Branch", string.IsNullOrEmpty(request.Branch) ? (object)DBNull.Value : request.Branch);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    report.Summary = new StockSummary
                    {
                        // Stock In
                        OpeningStockPurchase = reader.GetDecimal(reader.GetOrdinal("OpeningStockPurchase")),
                        OpeningStockSale = reader.GetDecimal(reader.GetOrdinal("OpeningStockSale")),
                        PurchaseStockPurchase = reader.GetDecimal(reader.GetOrdinal("PurchaseStockPurchase")),
                        PurchaseStockSale = reader.GetDecimal(reader.GetOrdinal("PurchaseStockSale")),
                        
                        // Stock Out
                        SaleStockPurchase = reader.GetDecimal(reader.GetOrdinal("SaleStockPurchase")),
                        SaleStockSale = reader.GetDecimal(reader.GetOrdinal("SaleStockSale")),
                        ClosingStockPurchase = reader.GetDecimal(reader.GetOrdinal("ClosingStockPurchase")),
                        ClosingStockSale = reader.GetDecimal(reader.GetOrdinal("ClosingStockSale"))
                    };
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock balance report");
                throw;
            }

            return report;
        }
    }
}
