using Microsoft.Data.SqlClient;
using System.Data;
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

        public async Task<IEnumerable<Packing>> GetAllPackingsAsync()
        {
            var packings = new List<Packing>();

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Packing_GetAll", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

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
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Packing_Delete", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);
            command.Parameters.AddWithValue("@ModifiedById", modifiedById);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result) > 0;
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
                IsActive = reader.GetBoolean("IsActive"),
                CreatedById = reader.GetInt32("CreatedById"),
                CreatedOn = reader.GetDateTime("CreatedOn"),
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