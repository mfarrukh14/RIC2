using Microsoft.Data.SqlClient;
using System.Data;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class ManufacturerServiceSP : IManufacturerService
    {
        private readonly string _connectionString;

        public ManufacturerServiceSP(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
        }

        public async Task<IEnumerable<Manufacturer>> GetAllManufacturersAsync()
        {
            var manufacturers = new List<Manufacturer>();

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Manufacturer_GetAll", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                manufacturers.Add(MapReaderToManufacturer(reader));
            }

            return manufacturers;
        }

        public async Task<Manufacturer?> GetManufacturerByIdAsync(int id)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Manufacturer_GetById", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                return MapReaderToManufacturer(reader);
            }

            return null;
        }

        public async Task<int> CreateManufacturerAsync(CreateManufacturerRequest request)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Manufacturer_Insert", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            AddManufacturerParameters(command, request);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result);
        }

        public async Task<bool> UpdateManufacturerAsync(UpdateManufacturerRequest request)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Manufacturer_Update", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", request.Id);
            AddManufacturerParameters(command, request);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result) > 0;
        }

        public async Task<bool> DeleteManufacturerAsync(int id, int modifiedById)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Manufacturer_Delete", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);
            command.Parameters.AddWithValue("@ModifiedById", modifiedById);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result) > 0;
        }

        private static Manufacturer MapReaderToManufacturer(SqlDataReader reader)
        {
            return new Manufacturer
            {
                Id = reader.GetInt32("Id"),
                Name = reader.GetString("Name"),
                Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                Email = reader.IsDBNull("Email") ? null : reader.GetString("Email"),
                Address = reader.IsDBNull("Address") ? null : reader.GetString("Address"),
                CNo = reader.IsDBNull("CNo") ? null : reader.GetString("CNo"),
                NTN = reader.IsDBNull("NTN") ? null : reader.GetString("NTN"),
                STN = reader.IsDBNull("STN") ? null : reader.GetString("STN"),
                CPName1 = reader.IsDBNull("CPName1") ? null : reader.GetString("CPName1"),
                CPEmail1 = reader.IsDBNull("CPEmail1") ? null : reader.GetString("CPEmail1"),
                CPContactNumber1 = reader.IsDBNull("CPContactNumber1") ? null : reader.GetString("CPContactNumber1"),
                CPName2 = reader.IsDBNull("CPName2") ? null : reader.GetString("CPName2"),
                CPEmail2 = reader.IsDBNull("CPEmail2") ? null : reader.GetString("CPEmail2"),
                CPContactNumber2 = reader.IsDBNull("CPContactNumber2") ? null : reader.GetString("CPContactNumber2"),
                CountryId = reader.IsDBNull("CountryId") ? null : reader.GetInt32("CountryId"),
                StateOrProvinceId = reader.IsDBNull("StateOrProvinceId") ? null : reader.GetInt32("StateOrProvinceId"),
                CityId = reader.IsDBNull("CityId") ? null : reader.GetInt32("CityId"),
                BranchId = reader.IsDBNull("BranchId") ? null : reader.GetInt32("BranchId"),
                RegisteredOwner = reader.IsDBNull("RegisteredOwner") ? null : reader.GetString("RegisteredOwner"),
                IsActive = reader.GetBoolean("IsActive"),
                CreatedById = reader.GetInt32("CreatedById"),
                CreatedOn = reader.GetDateTime("CreatedOn"),
                ModifiedById = reader.IsDBNull("ModifiedById") ? null : reader.GetInt32("ModifiedById"),
                ModifiedOn = reader.IsDBNull("ModifiedOn") ? null : reader.GetDateTime("ModifiedOn"),
                CountryName = reader.IsDBNull("CountryName") ? null : reader.GetString("CountryName"),
                StateOrProvinceName = reader.IsDBNull("StateOrProvinceName") ? null : reader.GetString("StateOrProvinceName"),
                CityName = reader.IsDBNull("CityName") ? null : reader.GetString("CityName"),
                BranchName = reader.IsDBNull("BranchName") ? null : reader.GetString("BranchName")
            };
        }

        private static void AddManufacturerParameters(SqlCommand command, object request)
        {
            switch (request)
            {
                case CreateManufacturerRequest createRequest:
                    command.Parameters.AddWithValue("@Name", createRequest.Name);
                    command.Parameters.AddWithValue("@Description", (object?)createRequest.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Email", (object?)createRequest.Email ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Address", (object?)createRequest.Address ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CNo", (object?)createRequest.CNo ?? DBNull.Value);
                    command.Parameters.AddWithValue("@NTN", (object?)createRequest.NTN ?? DBNull.Value);
                    command.Parameters.AddWithValue("@STN", (object?)createRequest.STN ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPName1", (object?)createRequest.CPName1 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPEmail1", (object?)createRequest.CPEmail1 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPContactNumber1", (object?)createRequest.CPContactNumber1 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPName2", (object?)createRequest.CPName2 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPEmail2", (object?)createRequest.CPEmail2 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPContactNumber2", (object?)createRequest.CPContactNumber2 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CountryId", (object?)createRequest.CountryId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@StateOrProvinceId", (object?)createRequest.StateOrProvinceId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CityId", (object?)createRequest.CityId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@BranchId", (object?)createRequest.BranchId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@RegisteredOwner", (object?)createRequest.RegisteredOwner ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CreatedById", createRequest.CreatedById);
                    break;

                case UpdateManufacturerRequest updateRequest:
                    command.Parameters.AddWithValue("@Name", updateRequest.Name);
                    command.Parameters.AddWithValue("@Description", (object?)updateRequest.Description ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Email", (object?)updateRequest.Email ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Address", (object?)updateRequest.Address ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CNo", (object?)updateRequest.CNo ?? DBNull.Value);
                    command.Parameters.AddWithValue("@NTN", (object?)updateRequest.NTN ?? DBNull.Value);
                    command.Parameters.AddWithValue("@STN", (object?)updateRequest.STN ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPName1", (object?)updateRequest.CPName1 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPEmail1", (object?)updateRequest.CPEmail1 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPContactNumber1", (object?)updateRequest.CPContactNumber1 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPName2", (object?)updateRequest.CPName2 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPEmail2", (object?)updateRequest.CPEmail2 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CPContactNumber2", (object?)updateRequest.CPContactNumber2 ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CountryId", (object?)updateRequest.CountryId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@StateOrProvinceId", (object?)updateRequest.StateOrProvinceId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@CityId", (object?)updateRequest.CityId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@BranchId", (object?)updateRequest.BranchId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@RegisteredOwner", (object?)updateRequest.RegisteredOwner ?? DBNull.Value);
                    command.Parameters.AddWithValue("@IsActive", updateRequest.IsActive);
                    command.Parameters.AddWithValue("@ModifiedById", updateRequest.ModifiedById);
                    break;
            }
        }
    }
}