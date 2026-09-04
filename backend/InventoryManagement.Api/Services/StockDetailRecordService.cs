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

        public async Task<PagedResult<StockDetailRecord>> GetStockDetailRecordsAsync(StockDetailRecordSearchRequest request)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(request.PageNumber, request.PageSize);
            var result = new PagedResult<StockDetailRecord> { PageNumber = pageNumber, PageSize = pageSize };
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
                PaginationHelper.AddPagingParameters(command, pageNumber, pageSize);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    if (result.TotalCount == 0)
                    {
                        result.TotalCount = PaginationHelper.ReadTotalCount(reader);
                    }

                    var stockTypeOrdinal = reader.GetOrdinal("StockType");
                    var buyingPriceOrdinal = reader.GetOrdinal("BuyingPrice");
                    var sellingPriceOrdinal = reader.GetOrdinal("SellingPrice");

                    records.Add(new StockDetailRecord
                    {
                        // Sr now comes from the proc's ROW_NUMBER() OVER (ORDER BY i.Name) -
                        // computed over the full filtered set before paging, so it reflects
                        // true report position rather than restarting at 1 on every page.
                        Sr = reader.GetInt32(reader.GetOrdinal("Sr")),
                        Name = reader.GetString(reader.GetOrdinal("Name")),
                        StockType = reader.IsDBNull(stockTypeOrdinal) ? string.Empty : reader.GetString(stockTypeOrdinal),
                        BuyingPrice = reader.IsDBNull(buyingPriceOrdinal) ? 0 : reader.GetDecimal(buyingPriceOrdinal),
                        SellingPrice = reader.IsDBNull(sellingPriceOrdinal) ? 0 : reader.GetDecimal(sellingPriceOrdinal),
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

            result.Items = records;
            return result;
        }
    }
}
