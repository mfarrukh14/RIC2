using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class ExpiredStockService : IExpiredStockService
    {
        private readonly string _connectionString;
        private readonly ILogger<ExpiredStockService> _logger;

        public ExpiredStockService(IConfiguration configuration, ILogger<ExpiredStockService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<PagedResult<ExpiredStock>> GetExpiredStockAsync(ExpiredStockSearchRequest request)
        {
            var expiredStocks = new List<ExpiredStock>();
            var (pageNumber, pageSize) = PaginationHelper.Normalize(request.PageNumber, request.PageSize);
            var totalCount = 0;

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("ExpiredStock_GetReport", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@StoreName", string.IsNullOrEmpty(request.StoreName) ? (object)DBNull.Value : request.StoreName);
                command.Parameters.AddWithValue("@StartDate", request.StartDate.HasValue ? (object)request.StartDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", request.EndDate.HasValue ? (object)request.EndDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@Item", string.IsNullOrEmpty(request.Item) ? (object)DBNull.Value : request.Item);
                command.Parameters.AddWithValue("@SearchTerm", string.IsNullOrEmpty(request.SearchTerm) ? (object)DBNull.Value : request.SearchTerm);
                PaginationHelper.AddPagingParameters(command, pageNumber, pageSize);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    if (totalCount == 0)
                    {
                        totalCount = PaginationHelper.ReadTotalCount(reader);
                    }

                    expiredStocks.Add(new ExpiredStock
                    {
                        Name = reader.GetString(reader.GetOrdinal("Name")),
                        StockType = reader.IsDBNull(reader.GetOrdinal("StockType")) ? string.Empty : reader.GetString(reader.GetOrdinal("StockType")),
                        BatchNo = reader.IsDBNull(reader.GetOrdinal("BatchNo")) ? null : reader.GetString(reader.GetOrdinal("BatchNo")),
                        MfgDate = reader.IsDBNull(reader.GetOrdinal("MfgDate")) ? null : reader.GetDateTime(reader.GetOrdinal("MfgDate")),
                        ExpDate = reader.IsDBNull(reader.GetOrdinal("ExpDate")) ? null : reader.GetDateTime(reader.GetOrdinal("ExpDate")),
                        TotalItems = reader.GetInt32(reader.GetOrdinal("TotalItems"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving expired stock");
                throw;
            }

            return new PagedResult<ExpiredStock> { Items = expiredStocks, TotalCount = totalCount, PageNumber = pageNumber, PageSize = pageSize };
        }
    }
}
