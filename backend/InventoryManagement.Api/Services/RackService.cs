using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public class RackService : IRackService
    {
        private readonly string _connectionString;
        private readonly ILogger<RackService> _logger;

        public RackService(IConfiguration configuration, ILogger<RackService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string not found");
            _logger = logger;
        }

        public async Task<IEnumerable<Rack>> GetAllRacksAsync(int branchId)
        {
            var racks = new List<Rack>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Rack_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@BranchId", branchId);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    racks.Add(MapRackFromReader(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving racks");
                throw;
            }

            return racks;
        }

        public async Task<Rack?> GetRackByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Rack_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return MapRackFromReader(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack with ID {RackId}", id);
                throw;
            }

            return null;
        }

        public async Task<int> CreateRackAsync(RackRequest request, int userId)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Rack_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Name", request.Name);
                command.Parameters.AddWithValue("@StoreId", request.StoreId);
                command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
                command.Parameters.AddWithValue("@Location", (object?)request.Location ?? DBNull.Value);
                command.Parameters.AddWithValue("@NumberOfRows", request.NumberOfRows);
                command.Parameters.AddWithValue("@NumberOfCols", request.NumberOfCols);
                command.Parameters.AddWithValue("@NumberOfDrawrs", request.NumberOfDraws);
                command.Parameters.AddWithValue("@BranchId", request.BranchId);
                command.Parameters.AddWithValue("@CreatedById", userId);
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();
                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating rack");
                throw;
            }
        }

        public async Task<bool> UpdateRackAsync(RackRequest request, int userId)
        {
            if (!request.Id.HasValue)
                throw new ArgumentException("Id is required for update");

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Rack_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", request.Id.Value);
                command.Parameters.AddWithValue("@Name", request.Name);
                command.Parameters.AddWithValue("@StoreId", request.StoreId);
                command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
                command.Parameters.AddWithValue("@Location", (object?)request.Location ?? DBNull.Value);
                command.Parameters.AddWithValue("@NumberOfRows", request.NumberOfRows);
                command.Parameters.AddWithValue("@NumberOfCols", request.NumberOfCols);
                command.Parameters.AddWithValue("@NumberOfDrawrs", request.NumberOfDraws);
                command.Parameters.AddWithValue("@ModifiedById", userId);
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating rack with ID {RackId}", request.Id);
                throw;
            }
        }

        public async Task<bool> DeleteRackAsync(int id, int userId)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Rack_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                await command.ExecuteNonQueryAsync();
                return true;
            }
            catch (SqlException ex) when (ex.Number == 547)
            {
                _logger.LogWarning(ex, "Cannot delete rack with ID {RackId} due to a foreign key constraint", id);
                throw new InvalidOperationException("Cannot delete rack. It has associated records elsewhere in the system.", ex);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting rack with ID {RackId}", id);
                throw;
            }
        }

        private static Rack MapRackFromReader(SqlDataReader reader)
        {
            return new Rack
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = GetNullableString(reader, "StoreName"),
                Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
                Location = reader.IsDBNull(reader.GetOrdinal("Location")) ? null : reader.GetString(reader.GetOrdinal("Location")),
                NumberOfRows = reader.GetInt32(reader.GetOrdinal("NumberOfRows")),
                NumberOfCols = reader.GetInt32(reader.GetOrdinal("NumberOfCols")),
                NumberOfDraws = reader.GetInt32(FindOrdinal(reader, "NumberOfDrawrs", "NumberOfDraws")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedOn = reader.IsDBNull(reader.GetOrdinal("CreatedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("CreatedOn"))
            };
        }

        private static int FindOrdinal(SqlDataReader reader, params string[] columnNames)
        {
            for (var index = 0; index < reader.FieldCount; index++)
            {
                var currentName = reader.GetName(index);
                foreach (var columnName in columnNames)
                {
                    if (string.Equals(currentName, columnName, StringComparison.OrdinalIgnoreCase))
                    {
                        return index;
                    }
                }
            }

            throw new IndexOutOfRangeException($"None of the expected columns were found: {string.Join(", ", columnNames)}");
        }

        private static string? GetNullableString(SqlDataReader reader, string columnName)
        {
            var ordinal = reader.GetOrdinal(columnName);
            return reader.IsDBNull(ordinal) ? null : Convert.ToString(reader.GetValue(ordinal));
        }
    }
}
