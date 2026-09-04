using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class SaleSummaryDailyService : ISaleSummaryDailyService
    {
        private readonly string _connectionString;
        private readonly ILogger<SaleSummaryDailyService> _logger;

        public SaleSummaryDailyService(IConfiguration configuration, ILogger<SaleSummaryDailyService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        // Shared reader for SaleSummaryDaily_GetReport - pageNumber/pageSize are left at
        // the proc's defaults (1 / int.MaxValue, i.e. unpaged) by GetSaleSummarySummaryAsync
        // below, since the grand totals must reflect every bucket in the filtered range,
        // not just the page currently on screen.
        private async Task<(List<SaleSummaryDaily> Items, int TotalCount)> FetchAsync(SaleSummarySearchRequest request, int? pageNumber, int? pageSize)
        {
            var summaries = new List<SaleSummaryDaily>();
            var totalCount = 0;

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SaleSummaryDaily_GetReport", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Store", string.IsNullOrEmpty(request.Store) ? (object)DBNull.Value : request.Store);
                command.Parameters.AddWithValue("@StartDate", request.StartDate.HasValue ? (object)request.StartDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", request.EndDate.HasValue ? (object)request.EndDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@Type", string.IsNullOrEmpty(request.Type) ? "Daily" : request.Type);
                if (pageNumber.HasValue) command.Parameters.AddWithValue("@PageNumber", pageNumber.Value);
                if (pageSize.HasValue) command.Parameters.AddWithValue("@PageSize", pageSize.Value);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    if (totalCount == 0)
                    {
                        totalCount = PaginationHelper.ReadTotalCount(reader);
                    }

                    var grossSales = reader.GetDecimal(reader.GetOrdinal("GrossSales"));
                    var discounts = reader.GetDecimal(reader.GetOrdinal("Discounts"));
                    var totalSReturn = reader.GetDecimal(reader.GetOrdinal("TotalSReturn"));
                    var costOfSales = reader.IsDBNull(reader.GetOrdinal("CostOfSales")) ? 0 : reader.GetDecimal(reader.GetOrdinal("CostOfSales"));
                    var totalSales = grossSales - discounts;
                    var netSale = totalSales - totalSReturn;
                    var gpAmount = netSale - costOfSales;
                    var gpPercentage = netSale > 0 ? (gpAmount / netSale) * 100 : 0;

                    summaries.Add(new SaleSummaryDaily
                    {
                        Date = reader.GetDateTime(reader.GetOrdinal("Date")),
                        Count = reader.GetInt32(reader.GetOrdinal("Count")),
                        GrossSales = grossSales,
                        Discounts = discounts,
                        TotalSales = totalSales,
                        TotalSReturn = totalSReturn,
                        NetSale = netSale,
                        CostOfSales = costOfSales,
                        GPAmount = gpAmount,
                        GPPercentage = gpPercentage
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sale summary");
                throw;
            }

            return (summaries, totalCount);
        }

        public async Task<PagedResult<SaleSummaryDaily>> GetSaleSummaryAsync(SaleSummarySearchRequest request)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(request.PageNumber, request.PageSize);
            var (items, totalCount) = await FetchAsync(request, pageNumber, pageSize);

            return new PagedResult<SaleSummaryDaily>
            {
                Items = items,
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        public async Task<SaleSummarySummary> GetSaleSummarySummaryAsync(SaleSummarySearchRequest request)
        {
            // Unpaged - the proc defaults @PageNumber/@PageSize to return every bucket in
            // the filtered range so these totals aren't scoped to whatever page the list
            // view happens to be showing.
            var (summaries, _) = await FetchAsync(request, null, null);

            var totalCount = summaries.Sum(s => s.Count);
            var grossSales = summaries.Sum(s => s.GrossSales);
            var discounts = summaries.Sum(s => s.Discounts);
            var totalSales = summaries.Sum(s => s.TotalSales);
            var totalSReturn = summaries.Sum(s => s.TotalSReturn);
            var netSale = summaries.Sum(s => s.NetSale);
            var costOfSales = summaries.Sum(s => s.CostOfSales);
            var gpAmount = summaries.Sum(s => s.GPAmount);
            var gpPercentage = netSale > 0 ? (gpAmount / netSale) * 100 : 0;

            return new SaleSummarySummary
            {
                TotalCount = totalCount,
                GrossSales = grossSales,
                Discounts = discounts,
                TotalSales = totalSales,
                TotalSReturn = totalSReturn,
                NetSale = netSale,
                CostOfSales = costOfSales,
                GPAmount = gpAmount,
                GPPercentage = gpPercentage
            };
        }
    }
}
