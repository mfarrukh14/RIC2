using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class RackDrawerService : IRackDrawerService
    {
        private readonly string _connectionString;
        private readonly ILogger<RackDrawerService> _logger;

        public RackDrawerService(IConfiguration configuration, ILogger<RackDrawerService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<RackDrawer>> GetAllAsync(int branchId)
        {
            var rackDrawers = new List<RackDrawer>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("RackDrawer_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@BranchId", branchId);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    rackDrawers.Add(MapToRackDrawer(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack drawers");
                throw;
            }

            return rackDrawers;
        }

        public async Task<RackDrawer?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("RackDrawer_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return MapToRackDrawer(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack drawer by ID: {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<RackDrawer> CreateAsync(RackDrawerCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("RackDrawer_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Name", request.Name);
                command.Parameters.AddWithValue("@Description", request.Description ?? (object)DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", request.StoreId);
                command.Parameters.AddWithValue("@RackId", request.RackId);
                command.Parameters.AddWithValue("@RackRowId", (object?)request.RackRowId ?? DBNull.Value);
                command.Parameters.AddWithValue("@RackColumnId", (object?)request.RackColumnId ?? DBNull.Value);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();
                var id = Convert.ToInt32(result);

                return await GetByIdAsync(id) ?? throw new Exception("Failed to retrieve created rack drawer");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating rack drawer");
                throw;
            }
        }

        public async Task<RackDrawer?> UpdateAsync(RackDrawerUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("RackDrawer_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", request.Id);
                command.Parameters.AddWithValue("@Name", request.Name);
                command.Parameters.AddWithValue("@Description", request.Description ?? (object)DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", request.StoreId);
                command.Parameters.AddWithValue("@RackId", request.RackId);
                command.Parameters.AddWithValue("@RackRowId", (object?)request.RackRowId ?? DBNull.Value);
                command.Parameters.AddWithValue("@RackColumnId", (object?)request.RackColumnId ?? DBNull.Value);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return await GetByIdAsync(request.Id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating rack drawer with ID: {Id}", request.Id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("RackDrawer_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting rack drawer with ID: {Id}", id);
                throw;
            }
        }

        private RackDrawer MapToRackDrawer(SqlDataReader reader)
        {
            return new RackDrawer
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                RackId = reader.GetInt32(reader.GetOrdinal("RackId")),
                RackRowId = reader.IsDBNull(reader.GetOrdinal("RackRowId")) ? null : reader.GetInt32(reader.GetOrdinal("RackRowId")),
                RackColumnId = reader.IsDBNull(reader.GetOrdinal("RackColumnId")) ? null : reader.GetInt32(reader.GetOrdinal("RackColumnId")),
                BranchId = reader.IsDBNull(reader.GetOrdinal("BranchId")) ? null : reader.GetInt32(reader.GetOrdinal("BranchId")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                RackName = reader.IsDBNull(reader.GetOrdinal("RackName")) ? null : reader.GetString(reader.GetOrdinal("RackName")),
                RowName = reader.IsDBNull(reader.GetOrdinal("RowName")) ? null : reader.GetString(reader.GetOrdinal("RowName")),
                ColumnName = reader.IsDBNull(reader.GetOrdinal("ColumnName")) ? null : reader.GetString(reader.GetOrdinal("ColumnName"))
            };
        }
    }
}
