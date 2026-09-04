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

        public async Task<PagedResult<SaleSummaryItemDiscount>> GetSaleSummaryItemDiscountAsync(SaleSummaryItemDiscountRequest request)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(request.PageNumber, request.PageSize);
            return await ExecuteAsync(request, pageNumber, pageSize);
        }

        // The totals row must reflect every matching item, not just the page currently on
        // screen - so it re-runs the same query unpaginated (PageSize = int.MaxValue,
        // bypassing PaginationHelper.Normalize's 200-row cap) rather than summing only the
        // page GetSaleSummaryItemDiscountAsync returns. This proc's result is grouped down
        // to one row per distinct item name, so an unpaginated pass here stays cheap.
        public async Task<SaleSummaryItemDiscountTotals> GetSaleSummaryItemDiscountTotalsAsync(SaleSummaryItemDiscountRequest request)
        {
            var all = await ExecuteAsync(request, 1, int.MaxValue);

            return new SaleSummaryItemDiscountTotals
            {
                UnitPurchaseRate = all.Items.Sum(s => s.UnitPurchaseRate),
                UnitSaleRate = all.Items.Sum(s => s.UnitSaleRate),
                Quantity = all.Items.Sum(s => s.Quantity),
                Sale = all.Items.Sum(s => s.Sale),
                DiscountAmount = all.Items.Sum(s => s.DiscountAmount),
                PurchaseRate = all.Items.Sum(s => s.TotalPurchaseRate),
                Profit = all.Items.Sum(s => s.Profit)
            };
        }

        private async Task<PagedResult<SaleSummaryItemDiscount>> ExecuteAsync(SaleSummaryItemDiscountRequest request, int pageNumber, int pageSize)
        {
            var result = new PagedResult<SaleSummaryItemDiscount> { PageNumber = pageNumber, PageSize = pageSize };
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
                PaginationHelper.AddPagingParameters(command, pageNumber, pageSize);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    if (result.TotalCount == 0)
                    {
                        result.TotalCount = PaginationHelper.ReadTotalCount(reader);
                    }

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

            result.Items = summaries;
            return result;
        }
    }
}
