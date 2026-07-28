using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public class LocationService : ILocationService
    {
        private readonly string _connectionString;
        private readonly ILogger<LocationService> _logger;

        public LocationService(IConfiguration configuration, ILogger<LocationService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException("Connection string not found");
            _logger = logger;
        }

        public async Task<IEnumerable<DropdownItem>> GetCountriesAsync()
        {
            var items = new List<DropdownItem>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Country_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    items.Add(new DropdownItem
                    {
                        Value = reader.GetInt32(reader.GetOrdinal("Id")),
                        Text = reader.GetString(reader.GetOrdinal("Name"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving countries");
                throw;
            }

            return items;
        }

        public async Task<IEnumerable<DropdownItem>> GetProvincesByCountryAsync(int countryId)
        {
            var items = new List<DropdownItem>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StateOrProvince_GetByCountry", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@CountryId", countryId);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    items.Add(new DropdownItem
                    {
                        Value = reader.GetInt32(reader.GetOrdinal("Id")),
                        Text = reader.GetString(reader.GetOrdinal("Name"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving provinces for country {CountryId}", countryId);
                throw;
            }

            return items;
        }

        public async Task<IEnumerable<DropdownItem>> GetCitiesByProvinceAsync(int provinceId)
        {
            var items = new List<DropdownItem>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("City_GetByStateOrProvince", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@StateOrProvinceId", provinceId);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    items.Add(new DropdownItem
                    {
                        Value = reader.GetInt32(reader.GetOrdinal("Id")),
                        Text = reader.GetString(reader.GetOrdinal("Name"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving cities for province {ProvinceId}", provinceId);
                throw;
            }

            return items;
        }
    }
}
