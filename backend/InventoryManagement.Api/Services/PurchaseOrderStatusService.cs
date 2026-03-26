using System.Data;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    public class PurchaseOrderStatusService : IPurchaseOrderStatusService
    {
        private readonly string _connectionString;
        private readonly ILogger<PurchaseOrderStatusService> _logger;

        public PurchaseOrderStatusService(IConfiguration configuration, ILogger<PurchaseOrderStatusService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IReadOnlyList<PurchaseOrderStatusDto>> GetAllAsync()
        {
            var results = new List<PurchaseOrderStatusDto>();

            const string sql = @"
SELECT
    PurchaseOrderStatusId,
    StatusName,
    Description,
    IsActive,
    CreatedOn
FROM dbo.PurchaseOrderStatuses
ORDER BY StatusName ASC;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(sql, connection) { CommandType = CommandType.Text };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    results.Add(Map(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase order statuses");
                throw;
            }

            return results;
        }

        public async Task<PurchaseOrderStatusDto?> GetByIdAsync(int id)
        {
            const string sql = @"
SELECT
    PurchaseOrderStatusId,
    StatusName,
    Description,
    IsActive,
    CreatedOn
FROM dbo.PurchaseOrderStatuses
WHERE PurchaseOrderStatusId = @PurchaseOrderStatusId;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(sql, connection) { CommandType = CommandType.Text };
                command.Parameters.AddWithValue("@PurchaseOrderStatusId", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    return Map(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase order status with ID {PurchaseOrderStatusId}", id);
                throw;
            }

            return null;
        }

        public async Task<PurchaseOrderStatusDto> CreateAsync(PurchaseOrderStatusUpsertRequest request)
        {
            const string sql = @"
INSERT INTO dbo.PurchaseOrderStatuses
(
    StatusName,
    Description,
    IsActive,
    CreatedOn
)
VALUES
(
    @StatusName,
    @Description,
    @IsActive,
    SYSUTCDATETIME()
);

SELECT CAST(SCOPE_IDENTITY() AS INT);";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(sql, connection) { CommandType = CommandType.Text };
                command.Parameters.AddWithValue("@StatusName", request.Name.Trim());
                command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                var id = Convert.ToInt32(await command.ExecuteScalarAsync());
                return await GetByIdAsync(id) ?? throw new InvalidOperationException("Purchase order status was created but could not be retrieved.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase order status");
                throw;
            }
        }

        public async Task<PurchaseOrderStatusDto?> UpdateAsync(int id, PurchaseOrderStatusUpsertRequest request)
        {
            const string sql = @"
UPDATE dbo.PurchaseOrderStatuses
SET
    StatusName = @StatusName,
    Description = @Description,
    IsActive = @IsActive
WHERE PurchaseOrderStatusId = @PurchaseOrderStatusId;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(sql, connection) { CommandType = CommandType.Text };
                command.Parameters.AddWithValue("@PurchaseOrderStatusId", id);
                command.Parameters.AddWithValue("@StatusName", request.Name.Trim());
                command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
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
                _logger.LogError(ex, "Error updating purchase order status with ID {PurchaseOrderStatusId}", id);
                throw;
            }
        }

        private static PurchaseOrderStatusDto Map(SqlDataReader reader)
        {
            return new PurchaseOrderStatusDto
            {
                PurchaseOrderStatusId = reader.GetInt32(reader.GetOrdinal("PurchaseOrderStatusId")),
                Name = reader.GetString(reader.GetOrdinal("StatusName")),
                Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn"))
            };
        }
    }
}