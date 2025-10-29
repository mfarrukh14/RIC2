using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class SaleSummaryStockNoDiscountService : ISaleSummaryStockNoDiscountService
    {
        private readonly string _connectionString;
        private readonly ILogger<SaleSummaryStockNoDiscountService> _logger;

        public SaleSummaryStockNoDiscountService(IConfiguration configuration, ILogger<SaleSummaryStockNoDiscountService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<SaleSummaryStockNoDiscount>> GetSaleSummaryStockNoDiscountAsync(SaleSummaryStockNoDiscountRequest request)
        {
            var summaries = new List<SaleSummaryStockNoDiscount>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SaleSummaryStockNoDiscount_GetReport", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Store", string.IsNullOrEmpty(request.Store) ? (object)DBNull.Value : request.Store);
                command.Parameters.AddWithValue("@StartDate", request.StartDate.HasValue ? (object)request.StartDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", request.EndDate.HasValue ? (object)request.EndDate.Value : DBNull.Value);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    var unitPurchaseRate = reader.GetDecimal(reader.GetOrdinal("UnitPurchaseRate"));
                    var unitSaleRate = reader.GetDecimal(reader.GetOrdinal("UnitSaleRate"));
                    var quantity = reader.GetDecimal(reader.GetOrdinal("Quantity"));
                    var sale = quantity * unitSaleRate;
                    var totalPurchaseRate = quantity * unitPurchaseRate;
                    var profit = sale - totalPurchaseRate;

                    summaries.Add(new SaleSummaryStockNoDiscount
                    {
                        Name = reader.GetString(reader.GetOrdinal("Name")),
                        UnitPurchaseRate = unitPurchaseRate,
                        UnitSaleRate = unitSaleRate,
                        Quantity = quantity,
                        Sale = sale,
                        TotalPurchaseRate = totalPurchaseRate,
                        Profit = profit
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sale summary stock no discount");
                throw;
            }

            return summaries;
        }

        public async Task<SaleSummaryStockNoDiscountTotals> GetSaleSummaryStockNoDiscountTotalsAsync(SaleSummaryStockNoDiscountRequest request)
        {
            var summaries = await GetSaleSummaryStockNoDiscountAsync(request);
            
            return new SaleSummaryStockNoDiscountTotals
            {
                UnitPurchaseRate = summaries.Sum(s => s.UnitPurchaseRate),
                UnitSaleRate = summaries.Sum(s => s.UnitSaleRate),
                Quantity = summaries.Sum(s => s.Quantity),
                Sale = summaries.Sum(s => s.Sale),
                PurchaseRate = summaries.Sum(s => s.TotalPurchaseRate),
                Profit = summaries.Sum(s => s.Profit),
                DiscountAmount = 0 // No discount for this report
            };
        }
    }
}
