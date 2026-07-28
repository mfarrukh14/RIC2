using Microsoft.Data.SqlClient;
using System.Data;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class StockAuditService : IStockAuditService
    {
        private readonly string _connectionString;

        public StockAuditService(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
        }

        public async Task<List<StockAuditItem>> SearchStockAuditItemsAsync(StockAuditSearchRequest request)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("StockAudit_Search", connection);
            command.CommandType = CommandType.StoredProcedure;
            
            command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
            command.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
            command.Parameters.AddWithValue("@ItemTypeId", (object?)request.ItemTypeId ?? DBNull.Value);
            command.Parameters.AddWithValue("@StockTypeId", (object?)request.StockTypeId ?? DBNull.Value);
            command.Parameters.AddWithValue("@ItemIds", (object?)request.ItemIds ?? DBNull.Value);
            command.Parameters.AddWithValue("@ManufacturerIds", (object?)request.ManufacturerIds ?? DBNull.Value);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            
            var items = new List<StockAuditItem>();
            while (await reader.ReadAsync())
            {
                items.Add(new StockAuditItem
                {
                    ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                    ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? null : reader.GetString(reader.GetOrdinal("ItemName")),
                    StockType = reader.IsDBNull(reader.GetOrdinal("StockType")) ? null : reader.GetString(reader.GetOrdinal("StockType")),
                    TotalItems = reader.GetDouble(reader.GetOrdinal("TotalItems")),
                    QtyOnShelf = reader.GetDouble(reader.GetOrdinal("QtyOnShelf")),
                    Difference = reader.GetDouble(reader.GetOrdinal("Difference")),
                    MPL = reader.GetDouble(reader.GetOrdinal("MPL")),
                    SalePrice = reader.GetDecimal(reader.GetOrdinal("SalePrice")),
                    QuantityPerPacket = reader.GetDouble(reader.GetOrdinal("QuantityPerPacket")),
                    ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn"))
                });
            }

            return items;
        }

        public async Task<StockAudit> CreateStockAuditAsync(StockAuditRequest request)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("StockAudit_Insert", connection);
            command.CommandType = CommandType.StoredProcedure;
            
            command.Parameters.AddWithValue("@StoreId", request.StoreId);
            command.Parameters.AddWithValue("@BranchId", request.BranchId);
            // The deployed StockAudit_Insert proc names these @AuditDate/@Notes, not @StockAuditDate/@Remarks.
            command.Parameters.AddWithValue("@AuditDate", request.StockAuditDate);
            command.Parameters.AddWithValue("@Notes", (object?)request.Remarks ?? DBNull.Value);
            command.Parameters.AddWithValue("@CreatedById", (object?)request.CreatedById ?? DBNull.Value);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                return new StockAudit
                {
                    Id = reader.GetInt32(reader.GetOrdinal("Id")),
                    StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                    BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                    StockAuditDate = reader.GetDateTime(reader.GetOrdinal("AuditDate")),
                    Remarks = reader.IsDBNull(reader.GetOrdinal("Notes")) ? null : reader.GetString(reader.GetOrdinal("Notes")),
                    IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                    CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                    CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                    ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                    ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                    IsDeleted = null
                };
            }

            throw new Exception("Failed to create stock audit");
        }
    }
}
