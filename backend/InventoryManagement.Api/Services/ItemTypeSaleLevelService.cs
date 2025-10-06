using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public class ItemTypeSaleLevelService : IItemTypeSaleLevelService
    {
        private readonly string _connectionString;
        private readonly ILogger<ItemTypeSaleLevelService> _logger;

        public ItemTypeSaleLevelService(
            IConfiguration configuration,
            ILogger<ItemTypeSaleLevelService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<ItemTypeSaleLevel>> GetAllAsync()
        {
            var levels = new List<ItemTypeSaleLevel>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("ItemTypeSaleLevels_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    levels.Add(MapToItemTypeSaleLevel(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving item type sale levels");
                throw;
            }

            return levels;
        }

        public async Task<ItemTypeSaleLevel?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("ItemTypeSaleLevels_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return MapToItemTypeSaleLevel(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving item type sale level with id {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<int> CreateAsync(CreateItemTypeSaleLevelRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("ItemTypeSaleLevels_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@ItemTypeId", request.ItemTypeId);
                command.Parameters.AddWithValue("@FastRunningLevel", request.FastRunningLevel);
                command.Parameters.AddWithValue("@SlowMovingLevel", request.SlowMovingLevel);
                command.Parameters.AddWithValue("@DeadLevel", request.DeadLevel);
                command.Parameters.AddWithValue("@BranchId", request.BranchId);
                command.Parameters.AddWithValue("@CreatedById", string.IsNullOrEmpty(request.CreatedById) ? DBNull.Value : request.CreatedById);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();

                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating item type sale level");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, UpdateItemTypeSaleLevelRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("ItemTypeSaleLevels_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@ItemTypeId", request.ItemTypeId);
                command.Parameters.AddWithValue("@FastRunningLevel", request.FastRunningLevel);
                command.Parameters.AddWithValue("@SlowMovingLevel", request.SlowMovingLevel);
                command.Parameters.AddWithValue("@DeadLevel", request.DeadLevel);
                command.Parameters.AddWithValue("@BranchId", request.BranchId);
                command.Parameters.AddWithValue("@ModifiedById", string.IsNullOrEmpty(request.ModifiedById) ? DBNull.Value : request.ModifiedById);

                await connection.OpenAsync();
                var rowsAffected = await command.ExecuteNonQueryAsync();

                return rowsAffected > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating item type sale level with id {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("ItemTypeSaleLevels_Delete", connection)
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
                _logger.LogError(ex, "Error deleting item type sale level with id {Id}", id);
                throw;
            }
        }

        public async Task<ItemTypeSaleLevelLookupData> GetLookupDataAsync()
        {
            var lookupData = new ItemTypeSaleLevelLookupData();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("ItemTypeSaleLevels_GetLookupData", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                // Read Item Types
                while (await reader.ReadAsync())
                {
                    lookupData.ItemTypes.Add(new LookupItem
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

        private static ItemTypeSaleLevel MapToItemTypeSaleLevel(SqlDataReader reader)
        {
            return new ItemTypeSaleLevel
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                ItemTypeId = reader.GetInt32(reader.GetOrdinal("ItemTypeId")),
                ItemTypeName = reader.IsDBNull(reader.GetOrdinal("ItemTypeName")) ? null : reader.GetString(reader.GetOrdinal("ItemTypeName")),
                FastRunningLevel = reader.GetInt32(reader.GetOrdinal("FastRunningLevel")),
                SlowMovingLevel = reader.GetInt32(reader.GetOrdinal("SlowMovingLevel")),
                DeadLevel = reader.GetInt32(reader.GetOrdinal("DeadLevel")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                BranchName = reader.IsDBNull(reader.GetOrdinal("BranchName")) ? null : reader.GetString(reader.GetOrdinal("BranchName")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetString(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetString(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                IsDeleted = reader.GetBoolean(reader.GetOrdinal("IsDeleted"))
            };
        }
    }
}
