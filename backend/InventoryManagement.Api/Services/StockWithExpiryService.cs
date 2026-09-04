using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public interface IStockWithExpiryService
    {
        Task<PagedResult<StockWithExpiry>> GetAllAsync(StockWithExpiryFilter filter);
    }

    public class StockWithExpiryService : IStockWithExpiryService
    {
        private readonly string _connectionString;
        private readonly ILogger<StockWithExpiryService> _logger;

        public StockWithExpiryService(IConfiguration configuration, ILogger<StockWithExpiryService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<PagedResult<StockWithExpiry>> GetAllAsync(StockWithExpiryFilter filter)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(filter.PageNumber, filter.PageSize);
            var result = new PagedResult<StockWithExpiry> { PageNumber = pageNumber, PageSize = pageSize };
            var stocks = new List<StockWithExpiry>();

            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("StockWithExpiry_GetAll", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;

                        command.Parameters.AddWithValue("@BranchId", (object?)filter.BranchId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@StoreId", (object?)filter.StoreId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@ItemType", (object?)filter.ItemType ?? DBNull.Value);
                        command.Parameters.AddWithValue("@ItemId", (object?)filter.ItemId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@CategoryId", (object?)filter.CategoryId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@IsExpensiveItem", (object?)filter.IsExpensiveItem ?? DBNull.Value);
                        command.Parameters.AddWithValue("@IsFridgeItem", (object?)filter.IsFridgeItem ?? DBNull.Value);
                        command.Parameters.AddWithValue("@MinimumPanicLevelOnly", filter.MinimumPanicLevelOnly);
                        PaginationHelper.AddPagingParameters(command, pageNumber, pageSize);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                if (result.TotalCount == 0)
                                {
                                    result.TotalCount = PaginationHelper.ReadTotalCount(reader);
                                }

                                stocks.Add(MapReaderToStock(reader));
                            }
                        }
                    }
                }

                result.Items = stocks;
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock with expiry information");
                throw;
            }
        }

        private StockWithExpiry MapReaderToStock(SqlDataReader reader)
        {
            return new StockWithExpiry
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.GetString(reader.GetOrdinal("ItemName")),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.GetString(reader.GetOrdinal("StoreName")),
                BatchNumber = reader.IsDBNull(reader.GetOrdinal("BatchNumber")) ? null : reader.GetString(reader.GetOrdinal("BatchNumber")),
                ExpiryDate = reader.IsDBNull(reader.GetOrdinal("ExpiryDate")) ? null : reader.GetDateTime(reader.GetOrdinal("ExpiryDate")),
                Quantity = reader.GetInt32(reader.GetOrdinal("Quantity")),
                StockType = reader.GetString(reader.GetOrdinal("StockType")),
                
                RackId = reader.IsDBNull(reader.GetOrdinal("RackId")) ? null : reader.GetInt32(reader.GetOrdinal("RackId")),
                RackName = reader.IsDBNull(reader.GetOrdinal("RackName")) ? null : reader.GetString(reader.GetOrdinal("RackName")),
                RackRowId = reader.IsDBNull(reader.GetOrdinal("RackRowId")) ? null : reader.GetInt32(reader.GetOrdinal("RackRowId")),
                RowNumber = reader.IsDBNull(reader.GetOrdinal("RowNumber")) ? null : reader.GetString(reader.GetOrdinal("RowNumber")),
                RackColumnId = reader.IsDBNull(reader.GetOrdinal("RackColumnId")) ? null : reader.GetInt32(reader.GetOrdinal("RackColumnId")),
                ColumnNumber = reader.IsDBNull(reader.GetOrdinal("ColumnNumber")) ? null : reader.GetString(reader.GetOrdinal("ColumnNumber")),
                RackDrawerId = reader.IsDBNull(reader.GetOrdinal("RackDrawerId")) ? null : reader.GetInt32(reader.GetOrdinal("RackDrawerId")),
                DrawerNumber = reader.IsDBNull(reader.GetOrdinal("DrawerNumber")) ? null : reader.GetString(reader.GetOrdinal("DrawerNumber")),
                
                MPL = reader.IsDBNull(reader.GetOrdinal("MPL")) ? 0 : Convert.ToDouble(reader.GetValue(reader.GetOrdinal("MPL"))),
                IsBelowMPL = reader.GetInt32(reader.GetOrdinal("IsBelowMPL")) == 1,
                
                ItemType = reader.IsDBNull(reader.GetOrdinal("ItemType")) ? null : reader.GetString(reader.GetOrdinal("ItemType")),
                IsExpensiveItem = reader.IsDBNull(reader.GetOrdinal("IsExpensiveItem")) ? null : reader.GetBoolean(reader.GetOrdinal("IsExpensiveItem")),
                IsFridgeItem = reader.IsDBNull(reader.GetOrdinal("IsFridgeItem")) ? null : reader.GetBoolean(reader.GetOrdinal("IsFridgeItem")),
                CategoryId = reader.IsDBNull(reader.GetOrdinal("CategoryId")) ? null : reader.GetInt32(reader.GetOrdinal("CategoryId")),
                
                TotalItemsInTransition = reader.GetInt32(reader.GetOrdinal("TotalItemsInTransition")),
                
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById"))
            };
        }
    }
}
