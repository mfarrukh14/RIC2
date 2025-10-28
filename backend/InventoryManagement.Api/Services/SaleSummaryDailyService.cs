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

        public async Task<IEnumerable<SaleSummaryDaily>> GetSaleSummaryAsync(SaleSummarySearchRequest request)
        {
            var summaries = new List<SaleSummaryDaily>();

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

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    var grossSales = reader.GetDecimal(reader.GetOrdinal("GrossSales"));
                    var discounts = reader.GetDecimal(reader.GetOrdinal("Discounts"));
                    var totalSReturn = reader.GetDecimal(reader.GetOrdinal("TotalSReturn"));
                    var costOfSales = reader.GetDecimal(reader.GetOrdinal("CostOfSales"));
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

            return summaries;
        }

        public async Task<SaleSummarySummary> GetSaleSummarySummaryAsync(SaleSummarySearchRequest request)
        {
            var summaries = await GetSaleSummaryAsync(request);
            
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
