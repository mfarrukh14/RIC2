using System.Data;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    public class PurchaseOrderTypeService : IPurchaseOrderTypeService
    {
        private readonly string _connectionString;
        private readonly ILogger<PurchaseOrderTypeService> _logger;
        private readonly string _schemaPrefix;

        public PurchaseOrderTypeService(IConfiguration configuration, ILogger<PurchaseOrderTypeService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
            var builder = new SqlConnectionStringBuilder(_connectionString);
            _schemaPrefix = builder.InitialCatalog.Equals("HMS", StringComparison.OrdinalIgnoreCase) ? "Inv" : "dbo";
        }

        private string NormalizeSql(string sql) => sql.Replace("dbo.", $"{_schemaPrefix}.");

        public async Task<IReadOnlyList<PurchaseOrderTypeDto>> GetAllAsync()
        {
            var results = new List<PurchaseOrderTypeDto>();

            const string sql = @"
SELECT
    Id AS PurchaseOrderTypeId,
    Name,
    Description,
    IsActive,
    CreatedOn
FROM dbo.PurchaseOrderTypes
ORDER BY Name ASC;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection) { CommandType = CommandType.Text };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    results.Add(Map(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase order types");
                throw;
            }

            return results;
        }

        public async Task<PurchaseOrderTypeDto?> GetByIdAsync(int id)
        {
            const string sql = @"
SELECT
    Id AS PurchaseOrderTypeId,
    Name,
    Description,
    IsActive,
    CreatedOn
FROM dbo.PurchaseOrderTypes
WHERE Id = @PurchaseOrderTypeId;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection) { CommandType = CommandType.Text };
                command.Parameters.AddWithValue("@PurchaseOrderTypeId", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    return Map(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase order type with ID {PurchaseOrderTypeId}", id);
                throw;
            }

            return null;
        }

        public async Task<PurchaseOrderTypeDto> CreateAsync(PurchaseOrderTypeUpsertRequest request)
        {
            const string sql = @"
INSERT INTO dbo.PurchaseOrderTypes
(
    Name,
    Description,
    IsActive,
    CreatedOn
)
VALUES
(
    @Name,
    @Description,
    @IsActive,
    SYSUTCDATETIME()
);

SELECT CAST(SCOPE_IDENTITY() AS INT);";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection) { CommandType = CommandType.Text };
                command.Parameters.AddWithValue("@Name", request.Name.Trim());
                command.Parameters.AddWithValue("@Description", (object?)NormalizeDescription(request.Description) ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                var id = Convert.ToInt32(await command.ExecuteScalarAsync());
                return await GetByIdAsync(id) ?? throw new InvalidOperationException("Purchase order type was created but could not be retrieved.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase order type");
                throw;
            }
        }

        public async Task<PurchaseOrderTypeDto?> UpdateAsync(int id, PurchaseOrderTypeUpsertRequest request)
        {
            const string sql = @"
UPDATE dbo.PurchaseOrderTypes
SET
    Name = @Name,
    Description = @Description,
    IsActive = @IsActive,
    ModifiedOn = SYSUTCDATETIME()
WHERE Id = @PurchaseOrderTypeId;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection) { CommandType = CommandType.Text };
                command.Parameters.AddWithValue("@PurchaseOrderTypeId", id);
                command.Parameters.AddWithValue("@Name", request.Name.Trim());
                command.Parameters.AddWithValue("@Description", (object?)NormalizeDescription(request.Description) ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                var rowsAffected = await command.ExecuteNonQueryAsync();
                if (rowsAffected == 0)
                {
                    return null;
                }

                return await GetByIdAsync(id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating purchase order type with ID {PurchaseOrderTypeId}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            const string sql = @"
DELETE FROM dbo.PurchaseOrderTypes
WHERE Id = @PurchaseOrderTypeId;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection) { CommandType = CommandType.Text };
                command.Parameters.AddWithValue("@PurchaseOrderTypeId", id);

                await connection.OpenAsync();
                var rowsAffected = await command.ExecuteNonQueryAsync();
                return rowsAffected > 0;
            }
            catch (SqlException ex) when (ex.Number == 547)
            {
                _logger.LogWarning(ex, "Cannot delete purchase order type with ID {PurchaseOrderTypeId} because it is in use", id);
                throw new InvalidOperationException("This purchase order type is already in use and cannot be deleted.", ex);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting purchase order type with ID {PurchaseOrderTypeId}", id);
                throw;
            }
        }

        private static string? NormalizeDescription(string? description)
        {
            var value = description?.Trim();
            return string.IsNullOrWhiteSpace(value) ? null : value;
        }

        private static PurchaseOrderTypeDto Map(SqlDataReader reader)
        {
            return new PurchaseOrderTypeDto
            {
                PurchaseOrderTypeId = reader.GetInt32(reader.GetOrdinal("PurchaseOrderTypeId")),
                Name = reader.GetString(reader.GetOrdinal("Name")),
                Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn"))
            };
        }
    }
}
