using System.Data;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    public class DemandRequestStatusService : IDemandRequestStatusService
    {
        private readonly string _connectionString;
        private readonly ILogger<DemandRequestStatusService> _logger;
        private readonly string _schemaPrefix;

        public DemandRequestStatusService(IConfiguration configuration, ILogger<DemandRequestStatusService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
            var builder = new SqlConnectionStringBuilder(_connectionString);
            _schemaPrefix = builder.InitialCatalog.Equals("HMS", StringComparison.OrdinalIgnoreCase) ? "Inv" : "dbo";
        }

        private string NormalizeSql(string sql) => sql.Replace("dbo.", $"{_schemaPrefix}.");

        public async Task<IReadOnlyList<DemandRequestStatusDto>> GetAllAsync()
        {
            var results = new List<DemandRequestStatusDto>();

            const string sql = @"
SELECT
    Id AS DemandRequestStatusId,
    Name AS StatusName,
    Description,
    IsActive,
    CreatedOn
FROM dbo.DemandRequestStatuses
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
                _logger.LogError(ex, "Error retrieving demand request statuses");
                throw;
            }

            return results;
        }

        public async Task<DemandRequestStatusDto?> GetByIdAsync(int id)
        {
            const string sql = @"
SELECT
    Id AS DemandRequestStatusId,
    Name AS StatusName,
    Description,
    IsActive,
    CreatedOn
FROM dbo.DemandRequestStatuses
WHERE Id = @DemandRequestStatusId;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection) { CommandType = CommandType.Text };
                command.Parameters.AddWithValue("@DemandRequestStatusId", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    return Map(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand request status with ID {DemandRequestStatusId}", id);
                throw;
            }

            return null;
        }

        public async Task<DemandRequestStatusDto> CreateAsync(DemandRequestStatusUpsertRequest request)
        {
            const string sql = @"
INSERT INTO dbo.DemandRequestStatuses
(
    Name,
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
                using var command = new SqlCommand(NormalizeSql(sql), connection) { CommandType = CommandType.Text };
                command.Parameters.AddWithValue("@StatusName", request.Name.Trim());
                command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                var id = Convert.ToInt32(await command.ExecuteScalarAsync());
                return await GetByIdAsync(id) ?? throw new InvalidOperationException("Demand request status was created but could not be retrieved.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating demand request status");
                throw;
            }
        }

        public async Task<DemandRequestStatusDto?> UpdateAsync(int id, DemandRequestStatusUpsertRequest request)
        {
            const string sql = @"
UPDATE dbo.DemandRequestStatuses
SET
    Name = @StatusName,
    Description = @Description,
    IsActive = @IsActive
WHERE Id = @DemandRequestStatusId;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection) { CommandType = CommandType.Text };
                command.Parameters.AddWithValue("@DemandRequestStatusId", id);
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
                _logger.LogError(ex, "Error updating demand request status with ID {DemandRequestStatusId}", id);
                throw;
            }
        }

        private static DemandRequestStatusDto Map(SqlDataReader reader)
        {
            return new DemandRequestStatusDto
            {
                DemandRequestStatusId = reader.GetInt32(reader.GetOrdinal("DemandRequestStatusId")),
                Name = reader.GetString(reader.GetOrdinal("StatusName")),
                Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn"))
            };
        }
    }
}
