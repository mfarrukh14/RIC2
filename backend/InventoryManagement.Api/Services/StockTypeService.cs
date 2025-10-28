using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class StockTypeService : IStockTypeService
    {
        private readonly string _connectionString;
        private readonly ILogger<StockTypeService> _logger;

        public StockTypeService(IConfiguration configuration, ILogger<StockTypeService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
            _logger = logger;
        }

        public async Task<IEnumerable<StockType>> GetAllStockTypesAsync()
        {
            var stockTypes = new List<StockType>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockType_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    var stockTypeId = reader.GetInt32(reader.GetOrdinal("Id"));
                    var stockTypeName = reader.GetString(reader.GetOrdinal("Name"));
                    
                    stockTypes.Add(new StockType
                    {
                        Id = stockTypeId,
                        Name = stockTypeName,
                        StockTypeId = stockTypeId,
                        StockTypeName = stockTypeName,
                        Description = reader.IsDBNull(reader.GetOrdinal("Description"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("Description")),
                        IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all stock types");
                throw;
            }

            return stockTypes;
        }

        public async Task<StockType?> GetStockTypeByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockType_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return new StockType
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        Name = reader.GetString(reader.GetOrdinal("Name")),
                        Description = reader.IsDBNull(reader.GetOrdinal("Description"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("Description")),
                        IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive"))
                    };
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock type with ID {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<int> CreateStockTypeAsync(StockTypeRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockType_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Name", request.Name);
                command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();

                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating stock type");
                throw;
            }
        }

        public async Task<bool> UpdateStockTypeAsync(int id, StockTypeRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockType_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@Name", request.Name);
                command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    var rowsAffected = reader.GetInt32(0);
                    return rowsAffected > 0;
                }

                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating stock type with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteStockTypeAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockType_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    var rowsAffected = reader.GetInt32(0);
                    return rowsAffected > 0;
                }

                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting stock type with ID {Id}", id);
                throw;
            }
        }
    }
}
