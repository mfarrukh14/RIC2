using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class StoreService : IStoreService
    {
        private readonly string _connectionString;

        public StoreService(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
        }

        public async Task<IEnumerable<Store>> GetAllAsync()
        {
            var stores = new List<Store>();

            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                using (var command = new SqlCommand("SELECT StoreId, StoreName, StoreCode, Description, IsActive, CreatedOn, ModifiedOn FROM Stores WHERE IsActive = 1 ORDER BY StoreName", connection))
                {
                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            stores.Add(new Store
                            {
                                StoreId = reader.GetInt32(0),
                                StoreName = reader.GetString(1),
                                StoreCode = reader.IsDBNull(2) ? null : reader.GetString(2),
                                Description = reader.IsDBNull(3) ? null : reader.GetString(3),
                                IsActive = reader.GetBoolean(4),
                                CreatedOn = reader.GetDateTime(5),
                                ModifiedOn = reader.IsDBNull(6) ? null : reader.GetDateTime(6)
                            });
                        }
                    }
                }
            }

            return stores;
        }

        public async Task<Store?> GetByIdAsync(int id)
        {
            using (var connection = new SqlConnection(_connectionString))
            {
                await connection.OpenAsync();
                using (var command = new SqlCommand("SELECT StoreId, StoreName, StoreCode, Description, IsActive, CreatedOn, ModifiedOn FROM Stores WHERE StoreId = @Id", connection))
                {
                    command.Parameters.AddWithValue("@Id", id);

                    using (var reader = await command.ExecuteReaderAsync())
                    {
                        if (await reader.ReadAsync())
                        {
                            return new Store
                            {
                                StoreId = reader.GetInt32(0),
                                StoreName = reader.GetString(1),
                                StoreCode = reader.IsDBNull(2) ? null : reader.GetString(2),
                                Description = reader.IsDBNull(3) ? null : reader.GetString(3),
                                IsActive = reader.GetBoolean(4),
                                CreatedOn = reader.GetDateTime(5),
                                ModifiedOn = reader.IsDBNull(6) ? null : reader.GetDateTime(6)
                            };
                        }
                    }
                }
            }

            return null;
        }
    }
}
