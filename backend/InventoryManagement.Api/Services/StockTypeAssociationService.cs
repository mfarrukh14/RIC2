using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class StockTypeAssociationService : IStockTypeAssociationService
    {
        private readonly string _connectionString;
        private readonly ILogger<StockTypeAssociationService> _logger;
        private const int _systemUserId = 1; // TODO: Get from current user

        public StockTypeAssociationService(IConfiguration configuration, ILogger<StockTypeAssociationService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");
            _logger = logger;
        }

        public async Task<IEnumerable<StockTypeAssociation>> GetAllStockTypeAssociationsAsync()
        {
            var associations = new List<StockTypeAssociation>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockTypeAssociation_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    associations.Add(new StockTypeAssociation
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        PharmacyStoreId = reader.GetInt32(reader.GetOrdinal("PharmacyStoreId")),
                        StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("StoreName")),
                        StockTypes = reader.GetInt32(reader.GetOrdinal("StockTypes")),
                        StockTypeName = reader.IsDBNull(reader.GetOrdinal("StockTypeName"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("StockTypeName")),
                        // Genuinely NULL for rows seeded via StoreId/StockTypeId only
                        // (see model comment) - no substitute column exists.
                        PatientTypes = reader.IsDBNull(reader.GetOrdinal("PatientTypes"))
                            ? null
                            : reader.GetInt32(reader.GetOrdinal("PatientTypes")),
                        CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all stock type associations");
                throw;
            }

            return associations;
        }

        public async Task<StockTypeAssociation?> GetStockTypeAssociationByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockTypeAssociation_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return new StockTypeAssociation
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        PharmacyStoreId = reader.GetInt32(reader.GetOrdinal("PharmacyStoreId")),
                        StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("StoreName")),
                        StockTypes = reader.GetInt32(reader.GetOrdinal("StockTypes")),
                        StockTypeName = reader.IsDBNull(reader.GetOrdinal("StockTypeName"))
                            ? null
                            : reader.GetString(reader.GetOrdinal("StockTypeName")),
                        PatientTypes = reader.IsDBNull(reader.GetOrdinal("PatientTypes"))
                            ? null
                            : reader.GetInt32(reader.GetOrdinal("PatientTypes")),
                        CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn"))
                    };
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock type association with ID {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<int> CreateStockTypeAssociationAsync(StockTypeAssociationRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockTypeAssociation_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@PharmacyStoreId", request.PharmacyStoreId);
                command.Parameters.AddWithValue("@StockTypes", request.StockTypes);
                command.Parameters.AddWithValue("@PatientTypes", request.PatientTypes);
                command.Parameters.AddWithValue("@CreatedById", _systemUserId);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();

                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating stock type association");
                throw;
            }
        }

        public async Task<bool> UpdateStockTypeAssociationAsync(int id, StockTypeAssociationRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockTypeAssociation_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@PharmacyStoreId", request.PharmacyStoreId);
                command.Parameters.AddWithValue("@StockTypes", request.StockTypes);
                command.Parameters.AddWithValue("@PatientTypes", request.PatientTypes);
                command.Parameters.AddWithValue("@ModifiedById", _systemUserId);

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
                _logger.LogError(ex, "Error updating stock type association with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteStockTypeAssociationAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockTypeAssociation_Delete", connection)
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
                _logger.LogError(ex, "Error deleting stock type association with ID {Id}", id);
                throw;
            }
        }
    }
}
