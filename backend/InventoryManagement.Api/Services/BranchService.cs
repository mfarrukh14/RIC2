using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public interface IBranchService
    {
        Task<IEnumerable<Branch>> GetAllAsync();
    }

    public class BranchService : IBranchService
    {
        private readonly string _connectionString;
        private readonly ILogger<BranchService> _logger;
        private readonly string _schemaPrefix;

        public BranchService(IConfiguration configuration, ILogger<BranchService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
            var builder = new SqlConnectionStringBuilder(_connectionString);
            _schemaPrefix = builder.InitialCatalog.StartsWith("HMS", StringComparison.OrdinalIgnoreCase) ? "Inv" : "dbo";
        }

        private string NormalizeSql(string sql) => sql.Replace("dbo.", $"{_schemaPrefix}.");

        public async Task<IEnumerable<Branch>> GetAllAsync()
        {
            var branches = new List<Branch>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                const string sql = "SELECT Id, Name, Address, IsActive, CreatedOn, ModifiedOn FROM dbo.Branches WHERE IsActive = 1 ORDER BY Name";
                using var command = new SqlCommand(NormalizeSql(sql), connection);
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    branches.Add(new Branch
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        Name = reader.GetString(reader.GetOrdinal("Name")),
                        Address = reader.IsDBNull(reader.GetOrdinal("Address")) ? null : reader.GetString(reader.GetOrdinal("Address")),
                        IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                        CreatedOn = reader.IsDBNull(reader.GetOrdinal("CreatedOn")) ? DateTime.MinValue : reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                        ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn"))
                    });
                }

                return branches;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving branches");
                throw;
            }
        }
    }
}
