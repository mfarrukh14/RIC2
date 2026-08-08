using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public class SurgicalItemGroupService : ISurgicalItemGroupService
    {
        private readonly string _connectionString;
        private readonly ILogger<SurgicalItemGroupService> _logger;

        public SurgicalItemGroupService(
            IConfiguration configuration,
            ILogger<SurgicalItemGroupService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<SurgicalItemGroup>> GetAllAsync(int branchId)
        {
            var groups = new List<SurgicalItemGroup>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SurgicalItemGroups_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@BranchId", branchId);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    groups.Add(MapToSurgicalItemGroup(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving surgical item groups");
                throw;
            }

            return groups;
        }

        public async Task<SurgicalItemGroup?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SurgicalItemGroups_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return MapToSurgicalItemGroup(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving surgical item group with id {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<int> CreateAsync(CreateSurgicalItemGroupRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SurgicalItemGroups_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Name", string.IsNullOrEmpty(request.Name) ? DBNull.Value : request.Name);
                command.Parameters.AddWithValue("@Description", string.IsNullOrEmpty(request.Description) ? DBNull.Value : request.Description);
                command.Parameters.AddWithValue("@BranchId", request.BranchId);
                command.Parameters.AddWithValue("@SubServiceId", string.IsNullOrEmpty(request.SubServiceId) ? DBNull.Value : request.SubServiceId);
                command.Parameters.AddWithValue("@CreatedById", string.IsNullOrEmpty(request.CreatedById) ? DBNull.Value : request.CreatedById);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();

                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating surgical item group");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, UpdateSurgicalItemGroupRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SurgicalItemGroups_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@Name", string.IsNullOrEmpty(request.Name) ? DBNull.Value : request.Name);
                command.Parameters.AddWithValue("@Description", string.IsNullOrEmpty(request.Description) ? DBNull.Value : request.Description);
                command.Parameters.AddWithValue("@BranchId", request.BranchId);
                command.Parameters.AddWithValue("@SubServiceId", string.IsNullOrEmpty(request.SubServiceId) ? DBNull.Value : request.SubServiceId);
                command.Parameters.AddWithValue("@ModifiedById", string.IsNullOrEmpty(request.ModifiedById) ? DBNull.Value : request.ModifiedById);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();

                return Convert.ToInt32(result) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating surgical item group with id {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SurgicalItemGroups_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();

                return Convert.ToInt32(result) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting surgical item group with id {Id}", id);
                throw;
            }
        }

        public async Task<SurgicalItemGroupLookupData> GetLookupDataAsync()
        {
            var lookupData = new SurgicalItemGroupLookupData();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SurgicalItemGroups_GetLookupData", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                // Read Branches
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

        private static SurgicalItemGroup MapToSurgicalItemGroup(SqlDataReader reader)
        {
            return new SurgicalItemGroup
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                Name = reader.IsDBNull(reader.GetOrdinal("Name")) ? null : reader.GetString(reader.GetOrdinal("Name")),
                Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                BranchName = reader.IsDBNull(reader.GetOrdinal("BranchName")) ? null : reader.GetString(reader.GetOrdinal("BranchName")),
                SubServiceId = reader.IsDBNull(reader.GetOrdinal("SubServiceId")) ? null : reader.GetString(reader.GetOrdinal("SubServiceId")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")).ToString(),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")).ToString(),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                IsDeleted = reader.GetBoolean(reader.GetOrdinal("IsDeleted"))
            };
        }
    }
}
