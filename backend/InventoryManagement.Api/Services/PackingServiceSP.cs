using Microsoft.Data.SqlClient;
using System.Data;
using System.Linq;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class PackingServiceSP : IPackingService
    {
        private readonly string _connectionString;

        public PackingServiceSP(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
        }

        public async Task<IEnumerable<Packing>> GetAllPackingsAsync(int branchId)
        {
            var packings = new List<Packing>();

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Packing_GetAll", connection)
            {
                CommandType = CommandType.StoredProcedure
            };
            command.Parameters.AddWithValue("@BranchId", branchId);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                packings.Add(MapReaderToPacking(reader));
            }

            return packings;
        }

        public async Task<Packing?> GetPackingByIdAsync(int id)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Packing_GetById", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                return MapReaderToPacking(reader);
            }

            return null;
        }

        public async Task<int> CreatePackingAsync(CreatePackingRequest request)
        {
            await EnsureNameNotDuplicateAsync(request.Name, request.BranchId, excludeId: null);

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Packing_Insert", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            AddPackingParameters(command, request);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result);
        }

        public async Task<bool> UpdatePackingAsync(UpdatePackingRequest request)
        {
            await EnsureNameNotDuplicateAsync(request.Name, request.BranchId, excludeId: request.Id);

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Packing_Update", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", request.Id);
            AddPackingParameters(command, request);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result) > 0;
        }

        public async Task<bool> DeletePackingAsync(int id, int modifiedById)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Packing_Delete", connection)
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
                throw new InvalidOperationException("Cannot delete packing. It has associated records elsewhere in the system.", ex);
            }
        }

        private async Task EnsureNameNotDuplicateAsync(string name, int? branchId, int? excludeId)
        {
            if (branchId == null)
            {
                return;
            }

            var normalizedName = name?.Trim() ?? string.Empty;
            var packings = await GetAllPackingsAsync(branchId.Value);

            var isDuplicate = packings.Any(p =>
                (!excludeId.HasValue || p.Id != excludeId.Value) &&
                string.Equals(p.Name?.Trim(), normalizedName, StringComparison.OrdinalIgnoreCase));

            if (isDuplicate)
            {
                throw new InvalidOperationException($"A packing type named '{normalizedName}' already exists.");
            }
        }

        private static Packing MapReaderToPacking(SqlDataReader reader)
        {
            return new Packing
            {
                Id = reader.GetInt32("Id"),
                Name = reader.GetString("Name"),
                Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                Pack = reader.IsDBNull("Pack") ? null : reader.GetInt32("Pack"),
                Leaf = reader.IsDBNull("Leaf") ? null : reader.GetInt32("Leaf"),
                NumberOfItems = reader.IsDBNull("NumberOfItems") ? null : reader.GetInt32("NumberOfItems"),
                BranchId = reader.IsDBNull("BranchId") ? null : reader.GetInt32("BranchId"),
                IsActive = reader.IsDBNull("IsActive") || reader.GetBoolean("IsActive"),
                CreatedById = reader.IsDBNull("CreatedById") ? 0 : reader.GetInt32("CreatedById"),
                CreatedOn = reader.IsDBNull("CreatedOn") ? DateTime.MinValue : reader.GetDateTime("CreatedOn"),
                ModifiedById = reader.IsDBNull("ModifiedById") ? null : reader.GetInt32("ModifiedById"),
                ModifiedOn = reader.IsDBNull("ModifiedOn") ? null : reader.GetDateTime("ModifiedOn"),
                BranchName = reader.IsDBNull("BranchName") ? null : reader.GetString("BranchName")
            };
        }

        private static void AddPackingParameters(SqlCommand command, object request)
        {
            switch (request)
            {
                case CreatePackingRequest createRequest:
                    command.Parameters.AddWithValue("@Name", createRequest.Name);
                    command.Parameters.AddWithValue("@Description", (object?)createRequest.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Pack", (object?)createRequest.Pack ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Leaf", (object?)createRequest.Leaf ?? DBNull.Value);
                    command.Parameters.AddWithValue("@NumberOfItems", (object?)createRequest.NumberOfItems ?? DBNull.Value);
                    command.Parameters.AddWithValue("@BranchId", (object?)createRequest.BranchId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CreatedById", createRequest.CreatedById);
                    break;

                case UpdatePackingRequest updateRequest:
                    command.Parameters.AddWithValue("@Name", updateRequest.Name);
                    command.Parameters.AddWithValue("@Description", (object?)updateRequest.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Pack", (object?)updateRequest.Pack ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Leaf", (object?)updateRequest.Leaf ?? DBNull.Value);
                    command.Parameters.AddWithValue("@NumberOfItems", (object?)updateRequest.NumberOfItems ?? DBNull.Value);
                    command.Parameters.AddWithValue("@BranchId", (object?)updateRequest.BranchId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@IsActive", updateRequest.IsActive);
                    command.Parameters.AddWithValue("@ModifiedById", updateRequest.ModifiedById);
                    break;
            }
        }
    }
}