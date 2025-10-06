using Microsoft.Data.SqlClient;
using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public class ReturnInventoryService : IReturnInventoryService
    {
        private readonly string _connectionString;
        private readonly ILogger<ReturnInventoryService> _logger;

        public ReturnInventoryService(IConfiguration configuration, ILogger<ReturnInventoryService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<List<ReturnInventory>> GetAllAsync(ReturnInventoryFilterRequest? filter = null)
        {
            var returns = new List<ReturnInventory>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("ReturnInventory_GetAll", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                // Add filter parameters
                command.Parameters.AddWithValue("@BranchId", (object?)filter?.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", (object?)filter?.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemTypeId", (object?)filter?.ItemTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemType", (object?)filter?.ItemType ?? DBNull.Value);
                command.Parameters.AddWithValue("@StartDate", (object?)filter?.StartDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", (object?)filter?.EndDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@PurchaseOrderNo", (object?)filter?.PurchaseOrderNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemId", (object?)filter?.ItemId ?? DBNull.Value);
                command.Parameters.AddWithValue("@InventoryNo", (object?)filter?.InventoryNo ?? DBNull.Value);

                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    returns.Add(MapToReturnInventory(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching return inventory records");
                throw;
            }

            return returns;
        }

        public async Task<ReturnInventory?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("ReturnInventory_GetById", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@Id", id);

                using var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    return MapToReturnInventory(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching return inventory with ID {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<ReturnInventory> CreateAsync(ReturnInventoryCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("ReturnInventory_Insert", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@InventoryNo", (object?)request.InventoryNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@PurchaseOrderNo", (object?)request.PurchaseOrderNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemTypeId", (object?)request.ItemTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemId", request.ItemId);
                command.Parameters.AddWithValue("@ItemName", request.ItemName);
                command.Parameters.AddWithValue("@ReturnQuantity", request.ReturnQuantity);
                command.Parameters.AddWithValue("@StockTypeId", (object?)request.StockTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorId", (object?)request.VendorId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ReturnDate", (object?)request.ReturnDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@Reason", (object?)request.Reason ?? DBNull.Value);
                command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);
                command.Parameters.AddWithValue("@CreatedById", 1); // TODO: Get from current user

                var id = await command.ExecuteScalarAsync();
                var returnInventory = await GetByIdAsync(Convert.ToInt32(id));
                return returnInventory ?? throw new Exception("Failed to retrieve created return inventory");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating return inventory");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, ReturnInventoryUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("ReturnInventory_Update", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@InventoryNo", (object?)request.InventoryNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@PurchaseOrderNo", (object?)request.PurchaseOrderNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemTypeId", (object?)request.ItemTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemId", request.ItemId);
                command.Parameters.AddWithValue("@ItemName", request.ItemName);
                command.Parameters.AddWithValue("@ReturnQuantity", request.ReturnQuantity);
                command.Parameters.AddWithValue("@StockTypeId", (object?)request.StockTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorId", (object?)request.VendorId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ReturnDate", request.ReturnDate);
                command.Parameters.AddWithValue("@Reason", (object?)request.Reason ?? DBNull.Value);
                command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                var rowsAffected = await command.ExecuteScalarAsync();
                return Convert.ToInt32(rowsAffected) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating return inventory with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("ReturnInventory_Delete", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                var rowsAffected = await command.ExecuteScalarAsync();
                return Convert.ToInt32(rowsAffected) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting return inventory with ID {Id}", id);
                throw;
            }
        }

        public async Task<ReturnInventoryLookupData> GetLookupDataAsync()
        {
            var lookupData = new ReturnInventoryLookupData();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("ReturnInventory_GetLookupData", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                using var reader = await command.ExecuteReaderAsync();

                // Read Branches
                while (await reader.ReadAsync())
                {
                    lookupData.Branches.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                // Read Stores
                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.Stores.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                // Read Item Types
                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.ItemTypes.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                // Read Stock Types
                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.StockTypes.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                // Read Vendors
                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.Vendors.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                // Read Items
                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.Items.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching return inventory lookup data");
                throw;
            }

            return lookupData;
        }

        private ReturnInventory MapToReturnInventory(SqlDataReader reader)
        {
            return new ReturnInventory
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                InventoryNo = reader.IsDBNull(reader.GetOrdinal("InventoryNo")) ? null : reader.GetString(reader.GetOrdinal("InventoryNo")),
                PurchaseOrderNo = reader.IsDBNull(reader.GetOrdinal("PurchaseOrderNo")) ? null : reader.GetString(reader.GetOrdinal("PurchaseOrderNo")),
                BranchId = reader.IsDBNull(reader.GetOrdinal("BranchId")) ? null : reader.GetInt32(reader.GetOrdinal("BranchId")),
                BranchName = reader.IsDBNull(reader.GetOrdinal("BranchName")) ? null : reader.GetString(reader.GetOrdinal("BranchName")),
                StoreId = reader.IsDBNull(reader.GetOrdinal("StoreId")) ? null : reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                ItemTypeId = reader.IsDBNull(reader.GetOrdinal("ItemTypeId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemTypeId")),
                ItemTypeName = reader.IsDBNull(reader.GetOrdinal("ItemTypeName")) ? null : reader.GetString(reader.GetOrdinal("ItemTypeName")),
                ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.GetString(reader.GetOrdinal("ItemName")),
                ReturnQuantity = reader.GetInt32(reader.GetOrdinal("ReturnQuantity")),
                StockTypeId = reader.IsDBNull(reader.GetOrdinal("StockTypeId")) ? null : reader.GetInt32(reader.GetOrdinal("StockTypeId")),
                StockTypeName = reader.IsDBNull(reader.GetOrdinal("StockTypeName")) ? null : reader.GetString(reader.GetOrdinal("StockTypeName")),
                VendorId = reader.IsDBNull(reader.GetOrdinal("VendorId")) ? null : reader.GetInt32(reader.GetOrdinal("VendorId")),
                VendorName = reader.IsDBNull(reader.GetOrdinal("VendorName")) ? null : reader.GetString(reader.GetOrdinal("VendorName")),
                ReturnDate = reader.GetDateTime(reader.GetOrdinal("ReturnDate")),
                Reason = reader.IsDBNull(reader.GetOrdinal("Reason")) ? null : reader.GetString(reader.GetOrdinal("Reason")),
                Notes = reader.IsDBNull(reader.GetOrdinal("Notes")) ? null : reader.GetString(reader.GetOrdinal("Notes")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.GetInt32(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn"))
            };
        }
    }
}
