using Microsoft.Data.SqlClient;
using System.Data;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class StockStatsService : IStockStatsService
    {
        private readonly string _connectionString;

        public StockStatsService(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
        }

        public async Task<PagedResult<StockStatsItem>> SearchStockStatsAsync(StockStatsSearchRequest request)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(request.PageNumber, request.PageSize);
            var result = new PagedResult<StockStatsItem> { PageNumber = pageNumber, PageSize = pageSize };

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("StockStats_Search", connection);
            command.CommandType = CommandType.StoredProcedure;

            command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
            command.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
            command.Parameters.AddWithValue("@StartDate", (object?)request.StartDate ?? DBNull.Value);
            command.Parameters.AddWithValue("@EndDate", (object?)request.EndDate ?? DBNull.Value);
            command.Parameters.AddWithValue("@ItemTypeId", (object?)request.ItemTypeId ?? DBNull.Value);
            command.Parameters.AddWithValue("@ItemIds", (object?)request.ItemIds ?? DBNull.Value);
            command.Parameters.AddWithValue("@StockTypeId", (object?)request.StockTypeId ?? DBNull.Value);
            command.Parameters.AddWithValue("@SaleType", request.SaleType);
            PaginationHelper.AddPagingParameters(command, pageNumber, pageSize);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            var items = new List<StockStatsItem>();
            while (await reader.ReadAsync())
            {
                if (result.TotalCount == 0)
                {
                    result.TotalCount = PaginationHelper.ReadTotalCount(reader);
                }

                items.Add(new StockStatsItem
                {
                    ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                    ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? null : reader.GetString(reader.GetOrdinal("ItemName")),
                    StockType = reader.IsDBNull(reader.GetOrdinal("StockType")) ? null : reader.GetString(reader.GetOrdinal("StockType")),
                    Opening = reader.GetDouble(reader.GetOrdinal("Opening")),
                    Received = reader.GetDouble(reader.GetOrdinal("Received")),
                    Issued = reader.GetDouble(reader.GetOrdinal("Issued")),
                    Balance = reader.GetDouble(reader.GetOrdinal("Balance"))
                });
            }

            result.Items = items;
            return result;
        }
    }
}
