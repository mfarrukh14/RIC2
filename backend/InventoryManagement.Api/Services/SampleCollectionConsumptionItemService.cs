using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public class SampleCollectionConsumptionItemService : ISampleCollectionConsumptionItemService
    {
        private readonly string _connectionString;
        private readonly ILogger<SampleCollectionConsumptionItemService> _logger;

        public SampleCollectionConsumptionItemService(
            IConfiguration configuration,
            ILogger<SampleCollectionConsumptionItemService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<SampleCollectionConsumptionItem>> GetAllAsync()
        {
            var items = new List<SampleCollectionConsumptionItem>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SampleCollectionConsumptionItems_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    items.Add(MapToSampleCollectionConsumptionItem(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sample collection consumption items");
                throw;
            }

            return items;
        }

        public async Task<SampleCollectionConsumptionItem?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SampleCollectionConsumptionItems_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return MapToSampleCollectionConsumptionItem(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sample collection consumption item with id {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<int> CreateAsync(CreateSampleCollectionConsumptionItemRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SampleCollectionConsumptionItems_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@ItemId", request.ItemId);
                command.Parameters.AddWithValue("@MedicineId", request.MedicineId.HasValue ? request.MedicineId.Value : DBNull.Value);
                command.Parameters.AddWithValue("@FeeId", request.FeeId.HasValue ? request.FeeId.Value : DBNull.Value);
                command.Parameters.AddWithValue("@DepartmentId", request.DepartmentId);
                command.Parameters.AddWithValue("@BranchId", request.BranchId);
                command.Parameters.AddWithValue("@Quantity", request.Quantity);
                command.Parameters.AddWithValue("@CreatedById", string.IsNullOrEmpty(request.CreatedById) ? DBNull.Value : request.CreatedById);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();

                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating sample collection consumption item");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, UpdateSampleCollectionConsumptionItemRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SampleCollectionConsumptionItems_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@ItemId", request.ItemId);
                command.Parameters.AddWithValue("@MedicineId", request.MedicineId.HasValue ? request.MedicineId.Value : DBNull.Value);
                command.Parameters.AddWithValue("@FeeId", request.FeeId.HasValue ? request.FeeId.Value : DBNull.Value);
                command.Parameters.AddWithValue("@DepartmentId", request.DepartmentId);
                command.Parameters.AddWithValue("@BranchId", request.BranchId);
                command.Parameters.AddWithValue("@Quantity", request.Quantity);
                command.Parameters.AddWithValue("@ModifiedById", string.IsNullOrEmpty(request.ModifiedById) ? DBNull.Value : request.ModifiedById);

                await connection.OpenAsync();
                var rowsAffected = await command.ExecuteNonQueryAsync();

                return rowsAffected > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating sample collection consumption item with id {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SampleCollectionConsumptionItems_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                var rowsAffected = await command.ExecuteNonQueryAsync();

                return rowsAffected > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting sample collection consumption item with id {Id}", id);
                throw;
            }
        }

        public async Task<SampleCollectionConsumptionItemLookupData> GetLookupDataAsync()
        {
            var lookupData = new SampleCollectionConsumptionItemLookupData();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SampleCollectionConsumptionItems_GetLookupData", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                // Read Departments
                while (await reader.ReadAsync())
                {
                    lookupData.Departments.Add(new LookupItem
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        Name = reader.GetString(reader.GetOrdinal("Name"))
                    });
                }

                // Read Items
                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.Items.Add(new LookupItem
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        Name = reader.GetString(reader.GetOrdinal("Name"))
                    });
                }

                // Read Branches
                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.Branches.Add(new LookupItem
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        Name = reader.GetString(reader.GetOrdinal("Name"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving lookup data");
                throw;
            }

            return lookupData;
        }

        private static SampleCollectionConsumptionItem MapToSampleCollectionConsumptionItem(SqlDataReader reader)
        {
            return new SampleCollectionConsumptionItem
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? null : reader.GetString(reader.GetOrdinal("ItemName")),
                MedicineId = reader.IsDBNull(reader.GetOrdinal("MedicineId")) ? null : reader.GetInt32(reader.GetOrdinal("MedicineId")),
                FeeId = reader.IsDBNull(reader.GetOrdinal("FeeId")) ? null : reader.GetInt32(reader.GetOrdinal("FeeId")),
                DepartmentId = reader.GetInt32(reader.GetOrdinal("DepartmentId")),
                DepartmentName = reader.IsDBNull(reader.GetOrdinal("DepartmentName")) ? null : reader.GetString(reader.GetOrdinal("DepartmentName")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                BranchName = reader.IsDBNull(reader.GetOrdinal("BranchName")) ? null : reader.GetString(reader.GetOrdinal("BranchName")),
                Quantity = reader.GetInt32(reader.GetOrdinal("Quantity")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetString(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetString(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                IsDeleted = reader.GetBoolean(reader.GetOrdinal("IsDeleted")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive"))
            };
        }
    }
}
