using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public interface IStoreAllocationToUserService
    {
        Task<IEnumerable<StoreAllocationToUser>> GetAllAsync();
        Task<StoreAllocationToUser?> GetByIdAsync(int id);
        Task<StoreAllocationToUser> CreateAsync(StoreAllocationToUserCreateRequest request);
        Task UpdateAsync(int id, StoreAllocationToUserUpdateRequest request);
        Task DeleteAsync(int id);
        Task<IReadOnlyList<DropdownItem>> GetEmployeeDropdownAsync();
    }

    public class StoreAllocationToUserService : IStoreAllocationToUserService
    {
        private readonly string _connectionString;
        private readonly ILogger<StoreAllocationToUserService> _logger;

        public StoreAllocationToUserService(IConfiguration configuration, ILogger<StoreAllocationToUserService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<StoreAllocationToUser>> GetAllAsync()
        {
            try
            {
                var allocations = new List<StoreAllocationToUser>();

                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("StoreAllocationToUser_GetAll", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                allocations.Add(MapReaderToAllocation(reader));
                            }
                        }
                    }
                }

                return allocations;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all store allocations");
                throw;
            }
        }

        public async Task<StoreAllocationToUser?> GetByIdAsync(int id)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("StoreAllocationToUser_GetById", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@Id", id);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                return MapReaderToAllocation(reader);
                            }
                        }
                    }
                }

                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving allocation by ID: {Id}", id);
                throw;
            }
        }

        public async Task<StoreAllocationToUser> CreateAsync(StoreAllocationToUserCreateRequest request)
        {
            try
            {
                int newId;

                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("StoreAllocationToUser_Insert", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@StoreId", request.StoreId);
                        command.Parameters.AddWithValue("@UserId", request.UserId);
                        command.Parameters.AddWithValue("@IsActive", request.IsActive);
                        command.Parameters.AddWithValue("@CreatedById", DBNull.Value);

                        var result = await command.ExecuteScalarAsync();
                        newId = Convert.ToInt32(result);
                    }
                }

                var created = await GetByIdAsync(newId);
                return created ?? throw new Exception("Failed to retrieve created allocation");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating store allocation");
                throw;
            }
        }

        public async Task UpdateAsync(int id, StoreAllocationToUserUpdateRequest request)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("StoreAllocationToUser_Update", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@Id", id);
                        command.Parameters.AddWithValue("@StoreId", request.StoreId);
                        command.Parameters.AddWithValue("@UserId", request.UserId);
                        command.Parameters.AddWithValue("@IsActive", request.IsActive);
                        command.Parameters.AddWithValue("@ModifiedById", DBNull.Value);

                        await command.ExecuteNonQueryAsync();
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating allocation with ID: {Id}", id);
                throw;
            }
        }

        public async Task DeleteAsync(int id)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("StoreAllocationToUser_Delete", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@Id", id);

                        await command.ExecuteNonQueryAsync();
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting allocation with ID: {Id}", id);
                throw;
            }
        }

        public async Task<IReadOnlyList<DropdownItem>> GetEmployeeDropdownAsync()
        {
            var employees = new List<DropdownItem>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                // Resolves each user's real person name (Employee.FullName, falling back to
                // First+Last) instead of their login UserName. Admin-tier accounts
                // (UserTypes.Value <= 3: Super Admin / Organization Admin / Branch Admin)
                // are excluded - they already have implicit access to every store, so they
                // don't need, and shouldn't need, an explicit allocation row.
                const string sql = @"
SELECT
    u.UserID AS Value,
    ISNULL(e.FullName, NULLIF(LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, ''))), '')) AS Text
FROM dbo.Users u
INNER JOIN dbo.Employee e ON u.EmpID = e.EmpID
INNER JOIN MemberShip.UserTypes ut ON ut.UTId = u.UserTypeId
WHERE ISNULL(u.Status, 1) = 1
  AND ut.Value > 3
  AND ISNULL(e.FullName, NULLIF(LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, ''))), '')) IS NOT NULL
ORDER BY Text;";

                using var command = new SqlCommand(sql, connection);
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    employees.Add(new DropdownItem
                    {
                        Value = reader.GetInt32(reader.GetOrdinal("Value")),
                        Text = reader.GetString(reader.GetOrdinal("Text"))
                    });
                }

                return employees;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving employee dropdown");
                throw;
            }
        }

        private StoreAllocationToUser MapReaderToAllocation(SqlDataReader reader)
        {
            return new StoreAllocationToUser
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                UserId = reader.IsDBNull(reader.GetOrdinal("UserId")) ? null : reader.GetInt32(reader.GetOrdinal("UserId")),
                EmployeeName = reader.GetString(reader.GetOrdinal("EmployeeName")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn"))
            };
        }

    }
}
