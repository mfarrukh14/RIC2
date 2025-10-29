using System.Data;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    public class RackRowService : IRackRowService
    {
        private readonly string _connectionString;
        private readonly ILogger<RackRowService> _logger;

        public RackRowService(IConfiguration configuration, ILogger<RackRowService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException("Connection string not found");
            _logger = logger;
        }

        public async Task<IEnumerable<RackRow>> GetAllRackRowsAsync()
        {
            try
            {
                var rows = new List<RackRow>();

                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("RackRow_GetAll", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                rows.Add(new RackRow
                                {
                                    Id = reader.GetGuid(reader.GetOrdinal("Id")),
                                    Name = reader.GetString(reader.GetOrdinal("Name")),
                                    Description = reader.IsDBNull(reader.GetOrdinal("Description"))
                                        ? null
                                        : reader.GetString(reader.GetOrdinal("Description")),
                                    StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                                    RackId = reader.GetInt32(reader.GetOrdinal("RackId")),
                                    BranchId = reader.IsDBNull(reader.GetOrdinal("BranchId"))
                                        ? null
                                        : reader.GetGuid(reader.GetOrdinal("BranchId")),
                                    IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                                    CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById"))
                                        ? null
                                        : reader.GetGuid(reader.GetOrdinal("CreatedById")),
                                    CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                                    ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById"))
                                        ? null
                                        : reader.GetGuid(reader.GetOrdinal("ModifiedById")),
                                    ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn"))
                                        ? null
                                        : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                                    StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName"))
                                        ? null
                                        : reader.GetString(reader.GetOrdinal("StoreName")),
                                    RackName = reader.IsDBNull(reader.GetOrdinal("RackName"))
                                        ? null
                                        : reader.GetString(reader.GetOrdinal("RackName"))
                                });
                            }
                        }
                    }
                }

                return rows;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all rack rows");
                throw;
            }
        }

        public async Task<RackRow?> GetRackRowByIdAsync(Guid id)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("RackRow_GetById", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@Id", id);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                return new RackRow
                                {
                                    Id = reader.GetGuid(reader.GetOrdinal("Id")),
                                    Name = reader.GetString(reader.GetOrdinal("Name")),
                                    Description = reader.IsDBNull(reader.GetOrdinal("Description"))
                                        ? null
                                        : reader.GetString(reader.GetOrdinal("Description")),
                                    StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                                    RackId = reader.GetInt32(reader.GetOrdinal("RackId")),
                                    BranchId = reader.IsDBNull(reader.GetOrdinal("BranchId"))
                                        ? null
                                        : reader.GetGuid(reader.GetOrdinal("BranchId")),
                                    IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                                    CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById"))
                                        ? null
                                        : reader.GetGuid(reader.GetOrdinal("CreatedById")),
                                    CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                                    ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById"))
                                        ? null
                                        : reader.GetGuid(reader.GetOrdinal("ModifiedById")),
                                    ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn"))
                                        ? null
                                        : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                                    StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName"))
                                        ? null
                                        : reader.GetString(reader.GetOrdinal("StoreName")),
                                    RackName = reader.IsDBNull(reader.GetOrdinal("RackName"))
                                        ? null
                                        : reader.GetString(reader.GetOrdinal("RackName"))
                                };
                            }
                        }
                    }
                }

                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack row by ID: {Id}", id);
                throw;
            }
        }

        public async Task<IEnumerable<RackRow>> GetRackRowsByRackIdAsync(int rackId)
        {
            try
            {
                var rows = new List<RackRow>();

                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("RackRow_GetByRackId", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@RackId", rackId);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                rows.Add(new RackRow
                                {
                                    Id = reader.GetGuid(reader.GetOrdinal("Id")),
                                    Name = reader.GetString(reader.GetOrdinal("Name")),
                                    Description = reader.IsDBNull(reader.GetOrdinal("Description"))
                                        ? null
                                        : reader.GetString(reader.GetOrdinal("Description")),
                                    StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                                    RackId = reader.GetInt32(reader.GetOrdinal("RackId")),
                                    BranchId = reader.IsDBNull(reader.GetOrdinal("BranchId"))
                                        ? null
                                        : reader.GetGuid(reader.GetOrdinal("BranchId")),
                                    IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                                    CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById"))
                                        ? null
                                        : reader.GetGuid(reader.GetOrdinal("CreatedById")),
                                    CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                                    ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById"))
                                        ? null
                                        : reader.GetGuid(reader.GetOrdinal("ModifiedById")),
                                    ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn"))
                                        ? null
                                        : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                                    StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName"))
                                        ? null
                                        : reader.GetString(reader.GetOrdinal("StoreName")),
                                    RackName = reader.IsDBNull(reader.GetOrdinal("RackName"))
                                        ? null
                                        : reader.GetString(reader.GetOrdinal("RackName"))
                                });
                            }
                        }
                    }
                }

                return rows;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack rows by rack ID: {RackId}", rackId);
                throw;
            }
        }

        public async Task<RackRow> CreateRackRowAsync(RackRowCreateRequest request)
        {
            try
            {
                var newId = Guid.NewGuid();

                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("RackRow_Insert", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;

                        command.Parameters.AddWithValue("@Id", newId);
                        command.Parameters.AddWithValue("@Name", request.Name);
                        command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
                        command.Parameters.AddWithValue("@StoreId", request.StoreId);
                        command.Parameters.AddWithValue("@RackId", request.RackId);
                        command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@IsActive", request.IsActive);
                        command.Parameters.AddWithValue("@CreatedById", (object?)request.CreatedById ?? DBNull.Value);

                        await command.ExecuteNonQueryAsync();
                    }
                }

                var createdRow = await GetRackRowByIdAsync(newId);
                return createdRow ?? throw new Exception("Failed to retrieve created rack row");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating rack row");
                throw;
            }
        }

        public async Task<bool> UpdateRackRowAsync(Guid id, RackRowUpdateRequest request)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("RackRow_Update", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;

                        command.Parameters.AddWithValue("@Id", id);
                        command.Parameters.AddWithValue("@Name", request.Name);
                        command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
                        command.Parameters.AddWithValue("@StoreId", request.StoreId);
                        command.Parameters.AddWithValue("@RackId", request.RackId);
                        command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@IsActive", request.IsActive);
                        command.Parameters.AddWithValue("@ModifiedById", (object?)request.ModifiedById ?? DBNull.Value);

                        var rowsAffected = await command.ExecuteNonQueryAsync();
                        return rowsAffected > 0;
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating rack row: {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteRackRowAsync(Guid id)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("RackRow_Delete", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@Id", id);

                        var rowsAffected = await command.ExecuteNonQueryAsync();
                        return rowsAffected > 0;
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting rack row: {Id}", id);
                throw;
            }
        }
    }
}
