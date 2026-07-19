using InventoryManagement.Api.DTOs;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;
using System.Data;
using System.Linq;

namespace InventoryManagement.Api.Services
{
    public class VendorServiceSP : IVendorService
    {
        private readonly IConfiguration _configuration;
        private readonly string _connectionString;

        public VendorServiceSP(IConfiguration configuration)
        {
            _configuration = configuration;
            _connectionString = _configuration.GetConnectionString("DefaultConnection") ?? throw new InvalidOperationException("Connection string not found");
        }

        public async Task<IEnumerable<VendorDto>> GetAllVendorsAsync()
        {
            var vendors = new List<VendorDto>();

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Vendor_GetAll", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            while (await reader.ReadAsync())
            {
                vendors.Add(MapReaderToDto(reader));
            }

            return vendors;
        }

        public async Task<VendorDto?> GetVendorByIdAsync(int id)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Vendor_GetById", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();

            if (await reader.ReadAsync())
            {
                return MapReaderToDto(reader);
            }

            return null;
        }

        public async Task<VendorDto> CreateVendorAsync(CreateVendorDto createVendorDto)
        {
            await EnsureNameNotDuplicateAsync(createVendorDto.Name, excludeId: null);

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Vendor_Insert", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            // Add parameters for the stored procedure
            command.Parameters.AddWithValue("@Name", createVendorDto.Name);
            command.Parameters.AddWithValue("@Description", (object?)createVendorDto.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Email", (object?)createVendorDto.Email1 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CNo", (object?)createVendorDto.Phone1 ?? DBNull.Value);
            command.Parameters.AddWithValue("@Address", (object?)createVendorDto.Address ?? DBNull.Value);
            command.Parameters.AddWithValue("@NTN", (object?)createVendorDto.TaxIdNumber ?? DBNull.Value);
            command.Parameters.AddWithValue("@STN", DBNull.Value);
            command.Parameters.AddWithValue("@CPName1", (object?)createVendorDto.ContactPersonName1 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CPEmail1", (object?)createVendorDto.Email1 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CPContactNumber1", (object?)createVendorDto.Phone1 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CPName2", (object?)createVendorDto.ContactPersonName2 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CPEmail2", (object?)createVendorDto.Email2 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CPContactNumber2", (object?)createVendorDto.Phone2 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CountryId", DBNull.Value);
            command.Parameters.AddWithValue("@StateOrProvinceId", DBNull.Value);
            command.Parameters.AddWithValue("@CityId", DBNull.Value);
            command.Parameters.AddWithValue("@BranchId", DBNull.Value);
            command.Parameters.AddWithValue("@Code", (object?)createVendorDto.Code ?? DBNull.Value);
            command.Parameters.AddWithValue("@VendorOrCustomer", DBNull.Value);
            command.Parameters.AddWithValue("@IncomeTaxStatus", DBNull.Value);
            command.Parameters.AddWithValue("@VendorType", DBNull.Value);
            command.Parameters.AddWithValue("@TaxPayerCategoryId", DBNull.Value);
            command.Parameters.AddWithValue("@TaxPayerStatus", DBNull.Value);
            command.Parameters.AddWithValue("@SaleTaxType", DBNull.Value);
            command.Parameters.AddWithValue("@ExemptUnderSRO", DBNull.Value);
            command.Parameters.AddWithValue("@AccountPayableId", DBNull.Value);
            command.Parameters.AddWithValue("@AccountReceivableId", DBNull.Value);
            command.Parameters.AddWithValue("@CreditStatus", DBNull.Value);
            command.Parameters.AddWithValue("@NetDueDays", DBNull.Value);
            command.Parameters.AddWithValue("@CreditLimit", DBNull.Value);
            command.Parameters.AddWithValue("@FaxNo", DBNull.Value);
            command.Parameters.AddWithValue("@IsVerified", false);
            command.Parameters.AddWithValue("@CreatedById", 1); // TODO: Get from current user

            await connection.OpenAsync();
            var result = await command.ExecuteReaderAsync();
            
            int newId = 0;
            if (await result.ReadAsync())
            {
                newId = result.GetInt32("Id");
            }
            result.Close();

            return await GetVendorByIdAsync(newId) ?? throw new InvalidOperationException("Failed to create vendor");
        }

        public async Task<VendorDto?> UpdateVendorAsync(int id, UpdateVendorDto updateVendorDto)
        {
            await EnsureNameNotDuplicateAsync(updateVendorDto.Name, excludeId: id);

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("Vendor_Update", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);
            command.Parameters.AddWithValue("@Name", updateVendorDto.Name);
            command.Parameters.AddWithValue("@Description", (object?)updateVendorDto.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Email", (object?)updateVendorDto.Email1 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CNo", (object?)updateVendorDto.Phone1 ?? DBNull.Value);
            command.Parameters.AddWithValue("@Address", (object?)updateVendorDto.Address ?? DBNull.Value);
            command.Parameters.AddWithValue("@NTN", (object?)updateVendorDto.TaxIdNumber ?? DBNull.Value);
            command.Parameters.AddWithValue("@STN", DBNull.Value);
            command.Parameters.AddWithValue("@CPName1", (object?)updateVendorDto.ContactPersonName1 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CPEmail1", (object?)updateVendorDto.Email1 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CPContactNumber1", (object?)updateVendorDto.Phone1 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CPName2", (object?)updateVendorDto.ContactPersonName2 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CPEmail2", (object?)updateVendorDto.Email2 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CPContactNumber2", (object?)updateVendorDto.Phone2 ?? DBNull.Value);
            command.Parameters.AddWithValue("@CountryId", DBNull.Value);
            command.Parameters.AddWithValue("@StateOrProvinceId", DBNull.Value);
            command.Parameters.AddWithValue("@CityId", DBNull.Value);
            command.Parameters.AddWithValue("@BranchId", DBNull.Value);
            command.Parameters.AddWithValue("@Code", (object?)updateVendorDto.Code ?? DBNull.Value);
            command.Parameters.AddWithValue("@VendorOrCustomer", DBNull.Value);
            command.Parameters.AddWithValue("@IncomeTaxStatus", DBNull.Value);
            command.Parameters.AddWithValue("@VendorType", DBNull.Value);
            command.Parameters.AddWithValue("@TaxPayerCategoryId", DBNull.Value);
            command.Parameters.AddWithValue("@TaxPayerStatus", DBNull.Value);
            command.Parameters.AddWithValue("@SaleTaxType", DBNull.Value);
            command.Parameters.AddWithValue("@ExemptUnderSRO", DBNull.Value);
            command.Parameters.AddWithValue("@AccountPayableId", DBNull.Value);
            command.Parameters.AddWithValue("@AccountReceivableId", DBNull.Value);
            command.Parameters.AddWithValue("@CreditStatus", DBNull.Value);
            command.Parameters.AddWithValue("@NetDueDays", DBNull.Value);
            command.Parameters.AddWithValue("@CreditLimit", DBNull.Value);
            command.Parameters.AddWithValue("@FaxNo", DBNull.Value);
            command.Parameters.AddWithValue("@IsVerified", false);
            command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user
            command.Parameters.AddWithValue("@IsActive", updateVendorDto.IsActive);

            await connection.OpenAsync();
            var result = await command.ExecuteReaderAsync();

            int rowsAffected = 0;
            if (await result.ReadAsync())
            {
                rowsAffected = result.GetInt32("RowsAffected");
            }
            result.Close();

            if (rowsAffected > 0)
            {
                return await GetVendorByIdAsync(id);
            }

            return null;
        }

        public async Task<bool> DeleteVendorAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Vendor_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                var result = await command.ExecuteReaderAsync();

                int rowsAffected = 0;
                if (await result.ReadAsync())
                {
                    rowsAffected = result.GetInt32("RowsAffected");
                }

                return rowsAffected > 0;
            }
            catch (SqlException ex) when (ex.Number == 547)
            {
                throw new InvalidOperationException("Cannot delete vendor. It has associated records elsewhere in the system.", ex);
            }
        }

        private async Task EnsureNameNotDuplicateAsync(string name, int? excludeId)
        {
            var normalizedName = name?.Trim() ?? string.Empty;
            var vendors = await GetAllVendorsAsync();

            var isDuplicate = vendors.Any(v =>
                (!excludeId.HasValue || v.Id != excludeId.Value) &&
                string.Equals(v.Name?.Trim(), normalizedName, StringComparison.OrdinalIgnoreCase));

            if (isDuplicate)
            {
                throw new InvalidOperationException($"A vendor named '{normalizedName}' already exists.");
            }
        }

        private void AddVendorParameters(SqlCommand command, object vendorDto)
        {
            var properties = vendorDto.GetType().GetProperties();
            
            foreach (var prop in properties)
            {
                var value = prop.GetValue(vendorDto);
                var paramName = "@" + prop.Name;
                
                if (value == null)
                {
                    command.Parameters.AddWithValue(paramName, DBNull.Value);
                }
                else
                {
                    command.Parameters.AddWithValue(paramName, value);
                }
            }
        }

        private VendorDto MapReaderToDto(SqlDataReader reader)
        {
            return new VendorDto
            {
                Id = reader.GetInt32("Id"),
                Name = reader.GetString("Name"),
                Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                Code = reader.IsDBNull("Code") ? null : reader.GetString("Code"),
                
                // Map new fields to existing DTO structure
                Type = reader.IsDBNull("VendorType") ? null : reader.GetInt32("VendorType").ToString(),
                Address = reader.IsDBNull("Address") ? null : reader.GetString("Address"),
                City = reader.IsDBNull("CityName") ? null : reader.GetString("CityName"),
                State = reader.IsDBNull("StateOrProvinceName") ? null : reader.GetString("StateOrProvinceName"),
                Country = reader.IsDBNull("CountryName") ? null : reader.GetString("CountryName"),
                PostalCode = null, // Not in new schema
                
                // Contact Person 1
                ContactPersonName1 = reader.IsDBNull("CPName1") ? null : reader.GetString("CPName1"),
                ContactPersonType1 = null, // Not in new schema
                Email1 = reader.IsDBNull("CPEmail1") ? null : reader.GetString("CPEmail1"),
                Phone1 = reader.IsDBNull("CPContactNumber1") ? null : reader.GetString("CPContactNumber1"),
                
                // Contact Person 2
                ContactPersonName2 = reader.IsDBNull("CPName2") ? null : reader.GetString("CPName2"),
                ContactPersonType2 = null, // Not in new schema
                Email2 = reader.IsDBNull("CPEmail2") ? null : reader.GetString("CPEmail2"),
                Phone2 = reader.IsDBNull("CPContactNumber2") ? null : reader.GetString("CPContactNumber2"),
                
                // Account/Bank details - map to existing fields
                VendorAccountNumber = reader.IsDBNull("Code") ? null : reader.GetString("Code"),
                TaxIdNumber = reader.IsDBNull("NTN") ? null : reader.GetString("NTN"),
                BankName = null, // Not in new schema
                AccountNumber = null, // Not in new schema
                RoutingNumber = null, // Not in new schema
                SwiftCode = null, // Not in new schema
                IbanNumber = null, // Not in new schema
                CreditLimit = reader.IsDBNull("CreditLimit") ? null : reader.GetInt32("CreditLimit").ToString(),
                PaymentTerms = reader.IsDBNull("NetDueDays") ? null : $"NET {reader.GetInt32("NetDueDays")}",
                
                IsActive = reader.GetBoolean("IsActive"),
                CreatedAt = reader.GetDateTime("CreatedOn"),
                UpdatedAt = reader.IsDBNull("ModifiedOn") ? null : reader.GetDateTime("ModifiedOn")
            };
        }
    }
}