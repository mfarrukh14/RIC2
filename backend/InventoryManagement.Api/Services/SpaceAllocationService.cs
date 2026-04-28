using System.Data;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    public class SpaceAllocationService : ISpaceAllocationService
    {
        private readonly string _connectionString;
        private readonly ILogger<SpaceAllocationService> _logger;

        public SpaceAllocationService(IConfiguration configuration, ILogger<SpaceAllocationService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException("Connection string not found");
            _logger = logger;
        }

        public async Task<IEnumerable<SpaceAllocation>> GetAllSpaceAllocationsAsync()
        {
            try
            {
                var allocations = new List<SpaceAllocation>();

                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("SpaceAllocation_GetAll", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                allocations.Add(MapSpaceAllocation(reader));
                            }
                        }
                    }
                }

                return allocations;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all space allocations");
                throw;
            }
        }

        public async Task<SpaceAllocation?> GetSpaceAllocationByIdAsync(int id)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("SpaceAllocation_GetById", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@Id", id);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                return MapSpaceAllocation(reader);
                            }
                        }
                    }
                }

                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving space allocation by ID: {Id}", id);
                throw;
            }
        }

        public async Task<SpaceAllocation> CreateSpaceAllocationAsync(SpaceAllocationCreateRequest request)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("SpaceAllocation_Insert", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;

                        command.Parameters.AddWithValue("@StoreId", request.StoreId);
                        command.Parameters.AddWithValue("@ItemId", request.ItemId);
                        command.Parameters.AddWithValue("@FeeId", (object?)request.FeeId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@RackId", request.RackId);
                        command.Parameters.AddWithValue("@RackRowId", (object?)request.RackRowId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@RackColumnId", (object?)request.RackColumnId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@RackDrawerId", (object?)request.RackDrawerId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@MedicineId", (object?)request.MedicineId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@IsActive", request.IsActive);
                        command.Parameters.AddWithValue("@CreatedById", (object?)request.CreatedById ?? DBNull.Value);

                        var result = await command.ExecuteScalarAsync();
                        var newId = Convert.ToInt32(result);

                        var created = await GetSpaceAllocationByIdAsync(newId);
                        return created ?? throw new Exception("Failed to retrieve created space allocation");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating space allocation");
                throw;
            }
        }

        public async Task<bool> UpdateSpaceAllocationAsync(int id, SpaceAllocationUpdateRequest request)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("SpaceAllocation_Update", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;

                        command.Parameters.AddWithValue("@Id", id);
                        command.Parameters.AddWithValue("@StoreId", request.StoreId);
                        command.Parameters.AddWithValue("@ItemId", request.ItemId);
                        command.Parameters.AddWithValue("@FeeId", (object?)request.FeeId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@RackId", request.RackId);
                        command.Parameters.AddWithValue("@RackRowId", (object?)request.RackRowId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@RackColumnId", (object?)request.RackColumnId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@RackDrawerId", (object?)request.RackDrawerId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@MedicineId", (object?)request.MedicineId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@IsActive", request.IsActive);
                        command.Parameters.AddWithValue("@ModifiedById", (object?)request.ModifiedById ?? DBNull.Value);

                        var rowsAffected = await command.ExecuteNonQueryAsync();
                        return rowsAffected > 0;
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating space allocation: {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteSpaceAllocationAsync(int id)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("SpaceAllocation_Delete", connection))
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
                _logger.LogError(ex, "Error deleting space allocation: {Id}", id);
                throw;
            }
        }

        private static SpaceAllocation MapSpaceAllocation(SqlDataReader reader)
        {
            return new SpaceAllocation
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                FeeId = reader.IsDBNull(reader.GetOrdinal("FeeId"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("FeeId")),
                RackId = reader.GetInt32(reader.GetOrdinal("RackId")),
                RackRowId = reader.IsDBNull(reader.GetOrdinal("RackRowId"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("RackRowId")),
                RackColumnId = reader.IsDBNull(reader.GetOrdinal("RackColumnId"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("RackColumnId")),
                RackDrawerId = reader.IsDBNull(reader.GetOrdinal("RackDrawerId"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("RackDrawerId")),
                MedicineId = reader.IsDBNull(reader.GetOrdinal("MedicineId"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("MedicineId")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById"))
                    ? null
                    : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn"))
                    ? null
                    : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("StoreName")),
                ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("ItemName")),
                RackName = reader.IsDBNull(reader.GetOrdinal("RackName"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("RackName")),
                RowName = reader.IsDBNull(reader.GetOrdinal("RowName"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("RowName")),
                ColumnName = reader.IsDBNull(reader.GetOrdinal("ColumnName"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("ColumnName")),
                DrawerName = reader.IsDBNull(reader.GetOrdinal("DrawerName"))
                    ? null
                    : reader.GetString(reader.GetOrdinal("DrawerName"))
            };
        }
    }
}
