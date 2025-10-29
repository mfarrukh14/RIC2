using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public class RackColumnService : IRackColumnService
    {
        private readonly string _connectionString;
        private readonly ILogger<RackColumnService> _logger;

        public RackColumnService(IConfiguration configuration, ILogger<RackColumnService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException("Connection string not found");
            _logger = logger;
        }

        public async Task<IEnumerable<RackColumn>> GetAllRackColumnsAsync()
        {
            var rackColumns = new List<RackColumn>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("RackColumn_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    rackColumns.Add(MapToRackColumn(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all rack columns");
                throw;
            }

            return rackColumns;
        }

        public async Task<RackColumn?> GetRackColumnByIdAsync(Guid id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("RackColumn_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return MapToRackColumn(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack column with ID: {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<IEnumerable<RackColumn>> GetRackColumnsByRackIdAsync(int rackId)
        {
            var rackColumns = new List<RackColumn>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("RackColumn_GetByRackId", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@RackId", rackId);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    rackColumns.Add(MapToRackColumn(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack columns for rack: {RackId}", rackId);
                throw;
            }

            return rackColumns;
        }

        public async Task<Guid> CreateRackColumnAsync(RackColumnCreateRequest request, Guid userId)
        {
            var newId = Guid.NewGuid();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("RackColumn_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", newId);
                command.Parameters.AddWithValue("@Name", request.Name);
                command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", request.StoreId);
                command.Parameters.AddWithValue("@RackId", request.RackId);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();

                return newId;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating rack column");
                throw;
            }
        }

        public async Task<bool> UpdateRackColumnAsync(RackColumnUpdateRequest request, Guid userId)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("RackColumn_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", request.Id);
                command.Parameters.AddWithValue("@Name", request.Name);
                command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", request.StoreId);
                command.Parameters.AddWithValue("@RackId", request.RackId);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                var rowsAffected = await command.ExecuteNonQueryAsync();

                return rowsAffected > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating rack column with ID: {Id}", request.Id);
                throw;
            }
        }

        public async Task<bool> DeleteRackColumnAsync(Guid id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("RackColumn_Delete", connection)
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
                _logger.LogError(ex, "Error deleting rack column with ID: {Id}", id);
                throw;
            }
        }

        private RackColumn MapToRackColumn(SqlDataReader reader)
        {
            return new RackColumn
            {
                Id = reader.GetGuid(reader.GetOrdinal("Id")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                RackId = reader.GetInt32(reader.GetOrdinal("RackId")),
                BranchId = reader.IsDBNull(reader.GetOrdinal("BranchId")) ? null : reader.GetGuid(reader.GetOrdinal("BranchId")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetGuid(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetGuid(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                RackName = reader.IsDBNull(reader.GetOrdinal("RackName")) ? null : reader.GetString(reader.GetOrdinal("RackName"))
            };
        }
    }
}
