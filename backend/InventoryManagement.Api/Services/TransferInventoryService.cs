using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public class TransferInventoryService : ITransferInventoryService
    {
        private readonly string _connectionString;
        private readonly ILogger<TransferInventoryService> _logger;

        public TransferInventoryService(IConfiguration configuration, ILogger<TransferInventoryService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<List<TransferInventory>> GetAllAsync()
        {
            var transfers = new List<TransferInventory>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("TransferInventory_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    transfers.Add(MapToTransferInventory(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all transfer inventories");
                throw;
            }

            return transfers;
        }

        public async Task<TransferInventory?> GetByIdAsync(int id)
        {
            TransferInventory? transfer = null;

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("TransferInventory_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    transfer = MapToTransferInventory(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving transfer inventory with ID {Id}", id);
                throw;
            }

            return transfer;
        }

        public async Task<TransferInventory> CreateAsync(TransferInventoryCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("TransferInventory_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@FromStoreId", request.FromStoreId);
                command.Parameters.AddWithValue("@ToStoreId", request.ToStoreId);
                command.Parameters.AddWithValue("@StockTypeId", request.StockTypeId);
                command.Parameters.AddWithValue("@ItemId", request.ItemId);
                command.Parameters.AddWithValue("@ItemName", (object?)request.ItemName ?? DBNull.Value);
                command.Parameters.AddWithValue("@Quantity", request.Quantity);
                command.Parameters.AddWithValue("@TransferDate", (object?)request.TransferDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@Status", (object?)request.Status ?? "Pending");
                command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@CreatedById", 1); // TODO: Get from current user

                await connection.OpenAsync();
                var transferId = Convert.ToInt32(await command.ExecuteScalarAsync());

                return await GetByIdAsync(transferId) ?? throw new Exception("Failed to retrieve created transfer");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating transfer inventory");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, TransferInventoryUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("TransferInventory_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@FromStoreId", request.FromStoreId);
                command.Parameters.AddWithValue("@ToStoreId", request.ToStoreId);
                command.Parameters.AddWithValue("@StockTypeId", request.StockTypeId);
                command.Parameters.AddWithValue("@ItemId", request.ItemId);
                command.Parameters.AddWithValue("@ItemName", (object?)request.ItemName ?? DBNull.Value);
                command.Parameters.AddWithValue("@Quantity", request.Quantity);
                command.Parameters.AddWithValue("@Status", (object?)request.Status ?? DBNull.Value);
                command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                await connection.OpenAsync();
                var affectedRows = await command.ExecuteScalarAsync();
                return Convert.ToInt32(affectedRows) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating transfer inventory with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("TransferInventory_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                await connection.OpenAsync();
                var affectedRows = await command.ExecuteScalarAsync();
                return Convert.ToInt32(affectedRows) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting transfer inventory with ID {Id}", id);
                throw;
            }
        }

        public async Task<TransferInventoryLookupData> GetLookupDataAsync()
        {
            var lookupData = new TransferInventoryLookupData();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("TransferInventory_GetLookupData", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                // Stores
                while (await reader.ReadAsync())
                {
                    lookupData.Stores.Add(new Store
                    {
                        StoreId = reader.GetInt32("Id"),
                        StoreName = reader.GetString("Name")
                    });
                }

                // Stock Types
                if (await reader.NextResultAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        lookupData.StockTypes.Add(new StockType
                        {
                            Id = reader.GetInt32("Id"),
                            Name = reader.GetString("Name")
                        });
                    }
                }

                // Items
                if (await reader.NextResultAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        lookupData.Items.Add(new Item
                        {
                            Id = reader.GetInt32("Id"),
                            Name = reader.GetString("Name")
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving transfer inventory lookup data");
                throw;
            }

            return lookupData;
        }

        public async Task<int> GetAvailableQuantityAsync(int storeId, int itemId)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("TransferInventory_GetAvailableQuantity", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@StoreId", storeId);
                command.Parameters.AddWithValue("@ItemId", itemId);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();
                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving available quantity for item {ItemId} in store {StoreId}", itemId, storeId);
                throw;
            }
        }

        private static TransferInventory MapToTransferInventory(SqlDataReader reader)
        {
            return new TransferInventory
            {
                Id = reader.GetInt32("Id"),
                // TransferNumber (aliased DRNo) and Status are nullable on Inv.TransferInventory -
                // legacy/migrated rows can have either unset.
                DRNo = reader.IsDBNull("DRNo") ? string.Empty : reader.GetString("DRNo"),
                FromStoreId = reader.GetInt32("FromStoreId"),
                FromStoreName = reader.IsDBNull("FromStoreName") ? null : reader.GetString("FromStoreName"),
                ToStoreId = reader.GetInt32("ToStoreId"),
                ToStoreName = reader.IsDBNull("ToStoreName") ? null : reader.GetString("ToStoreName"),
                StockTypeId = reader.IsDBNull("StockTypeId") ? null : reader.GetInt32("StockTypeId"),
                StockTypeName = reader.IsDBNull("StockTypeName") ? null : reader.GetString("StockTypeName"),
                ItemId = reader.IsDBNull("ItemId") ? null : reader.GetInt32("ItemId"),
                ItemName = reader.IsDBNull("ItemName") ? null : reader.GetString("ItemName"),
                Quantity = reader.GetInt32("Quantity"),
                TransferDate = reader.GetDateTime("TransferDate"),
                Status = reader.IsDBNull("Status") ? "Pending" : reader.GetString("Status"),
                Notes = reader.IsDBNull("Notes") ? null : reader.GetString("Notes"),
                IsActive = reader.GetBoolean("IsActive"),
                CreatedOn = reader.IsDBNull("CreatedOn") ? null : reader.GetDateTime("CreatedOn")
            };
        }
    }
}
