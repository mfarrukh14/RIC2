using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class SaleSummaryItemDiscountService : ISaleSummaryItemDiscountService
    {
        private readonly string _connectionString;
        private readonly ILogger<SaleSummaryItemDiscountService> _logger;

        public SaleSummaryItemDiscountService(IConfiguration configuration, ILogger<SaleSummaryItemDiscountService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<SaleSummaryItemDiscount>> GetSaleSummaryItemDiscountAsync(SaleSummaryItemDiscountRequest request)
        {
            var summaries = new List<SaleSummaryItemDiscount>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SaleSummaryItemDiscount_GetReport", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Store", string.IsNullOrEmpty(request.Store) ? (object)DBNull.Value : request.Store);
                command.Parameters.AddWithValue("@StartDate", request.StartDate.HasValue ? (object)request.StartDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", request.EndDate.HasValue ? (object)request.EndDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@Item", string.IsNullOrEmpty(request.Item) ? (object)DBNull.Value : request.Item);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    var unitPurchaseRate = reader.GetDecimal(reader.GetOrdinal("UnitPurchaseRate"));
                    var unitSaleRate = reader.GetDecimal(reader.GetOrdinal("UnitSaleRate"));
                    var quantity = reader.GetDecimal(reader.GetOrdinal("Quantity"));
                    var discountAmount = reader.GetDecimal(reader.GetOrdinal("DiscountAmount"));
                    var sale = quantity * unitSaleRate;
                    var totalPurchaseRate = quantity * unitPurchaseRate;
                    var profit = sale - discountAmount - totalPurchaseRate;

                    summaries.Add(new SaleSummaryItemDiscount
                    {
                        Name = reader.GetString(reader.GetOrdinal("Name")),
                        UnitPurchaseRate = unitPurchaseRate,
                        UnitSaleRate = unitSaleRate,
                        Quantity = quantity,
                        Sale = sale,
                        DiscountAmount = discountAmount,
                        TotalPurchaseRate = totalPurchaseRate,
                        Profit = profit
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sale summary item discount");
                throw;
            }

            return summaries;
        }

        public async Task<SaleSummaryItemDiscountTotals> GetSaleSummaryItemDiscountTotalsAsync(SaleSummaryItemDiscountRequest request)
        {
            var summaries = await GetSaleSummaryItemDiscountAsync(request);
            
            return new SaleSummaryItemDiscountTotals
            {
                UnitPurchaseRate = summaries.Sum(s => s.UnitPurchaseRate),
                UnitSaleRate = summaries.Sum(s => s.UnitSaleRate),
                Quantity = summaries.Sum(s => s.Quantity),
                Sale = summaries.Sum(s => s.Sale),
                DiscountAmount = summaries.Sum(s => s.DiscountAmount),
                PurchaseRate = summaries.Sum(s => s.TotalPurchaseRate),
                Profit = summaries.Sum(s => s.Profit)
            };
        }
    }
}
