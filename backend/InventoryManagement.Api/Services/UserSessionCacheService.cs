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
        private readonly IConfiguration _configuration;
        private readonly ILogger<UserSessionCacheService> _logger;

        public UserSessionCacheService(IConfiguration configuration, ILogger<UserSessionCacheService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        // This service is a Singleton (the session dictionary must live for the
        // whole process), but the active database can change at runtime via
        // SystemController's debug switch endpoint. Re-reading the connection
        // string on every call - instead of caching it once in the constructor -
        // is what makes a database switch actually apply to login/session lookups,
        // not just to the per-request Scoped services.
        private string GetConnectionString()
            => _configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

        private static string GetBranchSchemaPrefix(string connectionString)
        {
            var builder = new SqlConnectionStringBuilder(connectionString);
            return builder.InitialCatalog.StartsWith("HMS", StringComparison.OrdinalIgnoreCase) ? "Inv" : "dbo";
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

            // MemberShip.UserTypes: 1=Super Admin, 2=Organization Admin, 3=Branch
            // Admin - all three get unrestricted access, matching today's behavior.
            // 4=User, 5=Doctor, 6=Nurse are store-restricted via AllowedStoreIds.
            int? userTypeId = userRecord.TryGetValue("UserTypeId", out var userTypeIdValue) && userTypeIdValue is int utId ? utId : null;
            bool isAdmin = userTypeId is 1 or 2 or 3;
            var allowedStoreIds = isAdmin ? new List<int>() : await FetchAllowedStoreIdsAsync(userId);

            var session = new UserSession
            {
                UserId = userId,
                BranchId = branchId,
                BranchName = branchName,
                LoggedInOn = DateTime.UtcNow,
                User = userRecord,
                IsAdmin = isAdmin,
                AllowedStoreIds = allowedStoreIds
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
            using var connection = new SqlConnection(GetConnectionString());
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

        // Empty result (no rows / no allocation yet) means the caller sees nothing
        // once store-scoping is applied - fails closed rather than open.
        private async Task<List<int>> FetchAllowedStoreIdsAsync(int userId)
        {
            var storeIds = new List<int>();
            try
            {
                using var connection = new SqlConnection(GetConnectionString());
                await connection.OpenAsync();

                using var command = new SqlCommand(
                    "SELECT StoreId FROM Inv.StoreAllocationToUser WHERE UserId = @UserId AND IsActive = 1 AND IsDeleted = 0;",
                    connection);
                command.Parameters.AddWithValue("@UserId", userId);

                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    storeIds.Add(reader.GetInt32(0));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving allowed store IDs for UserId {UserId}", userId);
            }

            return storeIds;
        }

        private async Task<string?> FetchBranchNameAsync(int branchId)
        {
            try
            {
                var connectionString = GetConnectionString();
                using var connection = new SqlConnection(connectionString);
                await connection.OpenAsync();

                var branchSchemaPrefix = GetBranchSchemaPrefix(connectionString);
                using var command = new SqlCommand($"SELECT Name FROM {branchSchemaPrefix}.Branches WHERE Id = @BranchId", connection);
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
