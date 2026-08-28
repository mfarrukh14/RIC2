using Microsoft.Data.SqlClient;
using System.Data;
using System.Linq;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class ItemTypeServiceSP : IItemTypeService
    {
        private readonly string _connectionString;

        public ItemTypeServiceSP(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
        }

        public async Task<IEnumerable<ItemType>> GetAllItemTypesAsync(int branchId)
        {
            var itemTypes = new List<ItemType>();

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ItemType_GetAll", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.AddWithValue("@BranchId", branchId);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                itemTypes.Add(MapReaderToItemType(reader));
            }

            return itemTypes;
        }

        public async Task<ItemType?> GetItemTypeByIdAsync(int id)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ItemType_GetById", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                return MapReaderToItemType(reader);
            }

            return null;
        }

        public async Task<int> CreateItemTypeAsync(CreateItemTypeRequest request)
        {
            await EnsureNameNotDuplicateAsync(request.Name, request.BranchId, excludeId: null);

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ItemType_Insert", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            AddItemTypeParameters(command, request);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result);
        }

        public async Task<bool> UpdateItemTypeAsync(UpdateItemTypeRequest request)
        {
            await EnsureNameNotDuplicateAsync(request.Name, request.BranchId, excludeId: request.Id);

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ItemType_Update", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", request.Id);
            AddItemTypeParameters(command, request);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result) > 0;
        }

        public async Task<bool> DeleteItemTypeAsync(int id, int modifiedById)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ItemType_Delete", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);
            command.Parameters.AddWithValue("@ModifiedById", modifiedById);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result) > 0;
        }

        private async Task EnsureNameNotDuplicateAsync(string name, int? branchId, int? excludeId)
        {
            if (branchId == null)
            {
                return;
            }

            var normalizedName = name?.Trim() ?? string.Empty;
            var itemTypes = await GetAllItemTypesAsync(branchId.Value);

            var isDuplicate = itemTypes.Any(t =>
                (!excludeId.HasValue || t.Id != excludeId.Value) &&
                string.Equals(t.Name?.Trim(), normalizedName, StringComparison.OrdinalIgnoreCase));

            if (isDuplicate)
            {
                throw new InvalidOperationException($"An item type named '{normalizedName}' already exists.");
            }
        }

        private static ItemType MapReaderToItemType(SqlDataReader reader)
        {
            return new ItemType
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

        private static void AddItemTypeParameters(SqlCommand command, object request)
        {
            switch (request)
            {
                case CreateItemTypeRequest createRequest:
                    command.Parameters.AddWithValue("@Name", createRequest.Name);
                    command.Parameters.AddWithValue("@Description", (object?)createRequest.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@BranchId", (object?)createRequest.BranchId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CreatedById", createRequest.CreatedById);
                    break;

                case UpdateItemTypeRequest updateRequest:
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