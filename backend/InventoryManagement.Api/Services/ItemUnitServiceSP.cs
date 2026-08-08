using Microsoft.Data.SqlClient;
using System.Data;
using System.Linq;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class ItemUnitServiceSP : IItemUnitService
    {
        private readonly string _connectionString;

        public ItemUnitServiceSP(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
        }

        public async Task<IEnumerable<ItemUnit>> GetAllItemUnitsAsync(int branchId)
        {
            var itemUnits = new List<ItemUnit>();

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ItemUnit_GetAll", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.AddWithValue("@BranchId", branchId);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                itemUnits.Add(MapReaderToItemUnit(reader));
            }

            return itemUnits;
        }

        public async Task<ItemUnit?> GetItemUnitByIdAsync(int id)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ItemUnit_GetById", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                return MapReaderToItemUnit(reader);
            }

            return null;
        }

        public async Task<int> CreateItemUnitAsync(CreateItemUnitRequest request)
        {
            await EnsureNameNotDuplicateAsync(request.Name, request.BranchId, excludeId: null);

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ItemUnit_Insert", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            AddItemUnitParameters(command, request);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result);
        }

        public async Task<bool> UpdateItemUnitAsync(UpdateItemUnitRequest request)
        {
            await EnsureNameNotDuplicateAsync(request.Name, request.BranchId, excludeId: request.Id);

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ItemUnit_Update", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", request.Id);
            AddItemUnitParameters(command, request);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result) > 0;
        }

        public async Task<bool> DeleteItemUnitAsync(int id, int modifiedById)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("ItemUnit_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();
                return Convert.ToInt32(result) > 0;
            }
            catch (SqlException ex) when (ex.Number == 547)
            {
                throw new InvalidOperationException("Cannot delete item unit. It has associated records elsewhere in the system.", ex);
            }
        }

        private async Task EnsureNameNotDuplicateAsync(string name, int? branchId, int? excludeId)
        {
            if (branchId == null)
            {
                return;
            }

            var normalizedName = name?.Trim() ?? string.Empty;
            var itemUnits = await GetAllItemUnitsAsync(branchId.Value);

            var isDuplicate = itemUnits.Any(u =>
                (!excludeId.HasValue || u.Id != excludeId.Value) &&
                string.Equals(u.Name?.Trim(), normalizedName, StringComparison.OrdinalIgnoreCase));

            if (isDuplicate)
            {
                throw new InvalidOperationException($"An item unit named '{normalizedName}' already exists.");
            }
        }

        private static ItemUnit MapReaderToItemUnit(SqlDataReader reader)
        {
            return new ItemUnit
            {
                Id = reader.GetInt32("Id"),
                Name = reader.GetString("Name"),
                Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                BranchId = reader.IsDBNull("BranchId") ? null : reader.GetInt32("BranchId"),
                IsActive = reader.GetBoolean("IsActive"),
                CreatedById = reader.IsDBNull("CreatedById") ? 0 : reader.GetInt32("CreatedById"),
                CreatedOn = reader.GetDateTime("CreatedOn"),
                ModifiedById = reader.IsDBNull("ModifiedById") ? null : reader.GetInt32("ModifiedById"),
                ModifiedOn = reader.IsDBNull("ModifiedOn") ? null : reader.GetDateTime("ModifiedOn"),
                BranchName = reader.IsDBNull("BranchName") ? null : reader.GetString("BranchName")
            };
        }

        private static void AddItemUnitParameters(SqlCommand command, object request)
        {
            switch (request)
            {
                case CreateItemUnitRequest createRequest:
                    command.Parameters.AddWithValue("@Name", createRequest.Name);
                    command.Parameters.AddWithValue("@Description", (object?)createRequest.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@BranchId", (object?)createRequest.BranchId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CreatedById", createRequest.CreatedById);
                    break;

                case UpdateItemUnitRequest updateRequest:
                    command.Parameters.AddWithValue("@Name", updateRequest.Name);
                    command.Parameters.AddWithValue("@Description", (object?)updateRequest.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@BranchId", (object?)updateRequest.BranchId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@IsActive", updateRequest.IsActive);
                    command.Parameters.AddWithValue("@ModifiedById", updateRequest.ModifiedById);
                    break;
            }
        }
    }
}