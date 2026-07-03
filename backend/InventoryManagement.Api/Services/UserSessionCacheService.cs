using System.Collections.Concurrent;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    // In-memory, process-wide cache of logged-in users, keyed by UserId.
    // ConcurrentDictionary gives us thread-safe login/logout for many users at once.
    public class UserSessionCacheService : IUserSessionCacheService
    {
        private readonly ConcurrentDictionary<int, UserSession> _sessions = new();
        private readonly string _connectionString;
        private readonly string _branchSchemaPrefix;
        private readonly ILogger<UserSessionCacheService> _logger;

        public UserSessionCacheService(IConfiguration configuration, ILogger<UserSessionCacheService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;

            var builder = new SqlConnectionStringBuilder(_connectionString);
            _branchSchemaPrefix = builder.InitialCatalog.Equals("HMS", StringComparison.OrdinalIgnoreCase) ? "Inv" : "dbo";
        }

        public async Task<UserSession?> LoginAsync(int userId)
        {
            var userRecord = await FetchUserRowAsync(userId);
            if (userRecord == null)
            {
                return null;
            }

            int? branchId = userRecord.TryGetValue("BranchId", out var branchIdValue) && branchIdValue is int id ? id : null;
            string? branchName = branchId.HasValue ? await FetchBranchNameAsync(branchId.Value) : null;

            var session = new UserSession
            {
                UserId = userId,
                BranchId = branchId,
                BranchName = branchName,
                LoggedInOn = DateTime.UtcNow,
                User = userRecord
            };

            // Overwrites any existing entry for this user (e.g. a stale session from a prior login).
            _sessions[userId] = session;
            return session;
        }

        public void Logout(int userId)
        {
            _sessions.TryRemove(userId, out _);
        }

        public bool TryGet(int userId, out UserSession? session)
        {
            return _sessions.TryGetValue(userId, out session);
        }

        private async Task<Dictionary<string, object?>?> FetchUserRowAsync(int userId)
        {
            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            using var command = new SqlCommand("SELECT * FROM dbo.Users WHERE UserID = @UserId", connection);
            command.Parameters.AddWithValue("@UserId", userId);

            using var reader = await command.ExecuteReaderAsync();
            if (!await reader.ReadAsync())
            {
                return null;
            }

            var row = new Dictionary<string, object?>();
            for (var i = 0; i < reader.FieldCount; i++)
            {
                var value = reader.GetValue(i);
                row[reader.GetName(i)] = value is DBNull ? null : value;
            }

            return row;
        }

        private async Task<string?> FetchBranchNameAsync(int branchId)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand($"SELECT Name FROM {_branchSchemaPrefix}.Branches WHERE Id = @BranchId", connection);
                command.Parameters.AddWithValue("@BranchId", branchId);

                var result = await command.ExecuteScalarAsync();
                return result as string;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving branch name for BranchId {BranchId}", branchId);
                return null;
            }
        }
    }
}
