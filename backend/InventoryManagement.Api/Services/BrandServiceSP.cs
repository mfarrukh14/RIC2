using Microsoft.Data.SqlClient;
using System.Data;
using InventoryManagement.Api.Models;
using System.Linq;

namespace InventoryManagement.Api.Services
{
    public class BrandInUseException : Exception
    {
        public int ItemCount { get; }

        public BrandInUseException(int itemCount)
            : base($"This brand is used by {itemCount} item(s). Deleting it will remove the brand from those items.")
        {
            ItemCount = itemCount;
        }
    }

    public class BrandServiceSP : IBrandService
    {
        private readonly string _connectionString;

        public BrandServiceSP(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
        }

        public async Task<IEnumerable<Brand>> GetAllBrandsAsync()
        {
            var brands = new List<Brand>();

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Brand_GetAll", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                brands.Add(MapReaderToBrand(reader));
            }

            return brands;
        }

        public async Task<Brand?> GetBrandByIdAsync(int id)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Brand_GetById", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                return MapReaderToBrand(reader);
            }

            return null;
        }

        public async Task<int> CreateBrandAsync(CreateBrandRequest request)
        {
            await EnsureNameNotDuplicateAsync(request.Name, excludeId: null);

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Brand_Insert", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            AddBrandParameters(command, request);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result);
        }

        public async Task<bool> UpdateBrandAsync(UpdateBrandRequest request)
        {
            await EnsureNameNotDuplicateAsync(request.Name, excludeId: request.Id);

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Brand_Update", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", request.Id);
            AddBrandParameters(command, request);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result) > 0;
        }

        public async Task<bool> DeleteBrandAsync(int id, int modifiedById, bool force = false)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Brand_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@Force", force);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                int affectedRows = 0;
                int itemCount = 0;
                if (await reader.ReadAsync())
                {
                    affectedRows = reader.GetInt32(reader.GetOrdinal("AffectedRows"));
                    itemCount = reader.GetInt32(reader.GetOrdinal("ItemCount"));
                }

                if (affectedRows == 0 && itemCount > 0 && !force)
                {
                    throw new BrandInUseException(itemCount);
                }

                return affectedRows > 0;
            }
            catch (SqlException ex) when (ex.Number == 547)
            {
                throw new InvalidOperationException("Cannot delete brand. It has associated records elsewhere in the system.", ex);
            }
        }

        private async Task EnsureNameNotDuplicateAsync(string name, int? excludeId)
        {
            var normalizedName = name?.Trim() ?? string.Empty;
            var brands = await GetAllBrandsAsync();

            var isDuplicate = brands.Any(b =>
                (!excludeId.HasValue || b.Id != excludeId.Value) &&
                string.Equals(b.Name?.Trim(), normalizedName, StringComparison.OrdinalIgnoreCase));

            if (isDuplicate)
            {
                throw new InvalidOperationException($"A brand named '{normalizedName}' already exists.");
            }
        }

        private static Brand MapReaderToBrand(SqlDataReader reader)
        {
            return new Brand
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

        private static void AddBrandParameters(SqlCommand command, object request)
        {
            switch (request)
            {
                case CreateBrandRequest createRequest:
                    command.Parameters.AddWithValue("@Name", createRequest.Name);
                    command.Parameters.AddWithValue("@Description", (object?)createRequest.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@BranchId", (object?)createRequest.BranchId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CreatedById", createRequest.CreatedById);
                    break;

                case UpdateBrandRequest updateRequest:
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