using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public class ItemService : IItemService
    {
        private readonly string _connectionString;
        private readonly ILogger<ItemService> _logger;

        public ItemService(IConfiguration configuration, ILogger<ItemService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? throw new ArgumentNullException("Connection string not found");
            _logger = logger;
        }

        public async Task<IEnumerable<Item>> GetAllAsync()
        {
            var items = new List<Item>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Item_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    items.Add(MapToItem(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving items");
                throw;
            }

            return items;
        }

        public async Task<Item?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Item_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return MapToItem(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving item with ID {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<int> CreateAsync(ItemCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Item_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                AddItemParameters(command, request);
                command.Parameters.AddWithValue("@CreatedById", 1); // TODO: Get from current user

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();
                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating item");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, ItemUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Item_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                AddItemParameters(command, request);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                await connection.OpenAsync();
                var affectedRows = await command.ExecuteScalarAsync();
                return Convert.ToInt32(affectedRows) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating item with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Item_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                await connection.OpenAsync();
                var affectedRows = await command.ExecuteScalarAsync();
                return Convert.ToInt32(affectedRows) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting item with ID {Id}", id);
                throw;
            }
        }

        public async Task<IEnumerable<Category>> GetCategoriesAsync()
        {
            var categories = new List<Category>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Category_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    categories.Add(new Category
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name"),
                        Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving categories");
                throw;
            }

            return categories;
        }

        public async Task<Category?> GetCategoryByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Category_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return new Category
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name"),
                        Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                        IsActive = reader.GetBoolean("IsActive")
                    };
                }
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving category with ID {Id}", id);
                throw;
            }
        }

        public async Task<int> CreateCategoryAsync(string name, string? description, bool isActive)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Category_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Name", name);
                command.Parameters.AddWithValue("@Description", (object?)description ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsActive", isActive);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();
                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating category");
                throw;
            }
        }

        public async Task<bool> UpdateCategoryAsync(int id, string name, string? description, bool isActive)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Category_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@Name", name);
                command.Parameters.AddWithValue("@Description", (object?)description ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsActive", isActive);

                await connection.OpenAsync();
                var rowsAffected = await command.ExecuteNonQueryAsync();
                return rowsAffected > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating category with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteCategoryAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Category_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                var rowsAffected = await command.ExecuteNonQueryAsync();
                return rowsAffected > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting category with ID {Id}", id);
                throw;
            }
        }

        public async Task<IEnumerable<SubCategory>> GetSubCategoriesAsync()
        {
            var subCategories = new List<SubCategory>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SubCategory_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    subCategories.Add(new SubCategory
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name"),
                        Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                        CategoryId = reader.IsDBNull("CategoryId") ? null : reader.GetInt32("CategoryId"),
                        CategoryName = reader.IsDBNull("CategoryName") ? null : reader.GetString("CategoryName"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sub-categories");
                throw;
            }

            return subCategories;
        }

        public async Task<IEnumerable<Price>> GetPricesAsync()
        {
            var prices = new List<Price>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Price_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    prices.Add(new Price
                    {
                        Id = reader.GetInt32("Id"),
                        RetailPrice = reader.GetDecimal("RetailPrice"),
                        SalePrice = reader.GetDecimal("SalePrice"),
                        MarketPrice = reader.GetDecimal("MarketPrice"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving prices");
                throw;
            }

            return prices;
        }

        public async Task<IEnumerable<TaxRate>> GetTaxRatesAsync()
        {
            var taxRates = new List<TaxRate>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("TaxRate_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    taxRates.Add(new TaxRate
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name"),
                        Rate = reader.GetDecimal("Rate"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving tax rates");
                throw;
            }

            return taxRates;
        }

        public async Task<IEnumerable<TaxDescription>> GetTaxDescriptionsAsync()
        {
            var taxDescriptions = new List<TaxDescription>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("TaxDescription_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    taxDescriptions.Add(new TaxDescription
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name"),
                        Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving tax descriptions");
                throw;
            }

            return taxDescriptions;
        }

        public async Task<IEnumerable<TaxType>> GetTaxTypesAsync()
        {
            var taxTypes = new List<TaxType>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("TaxType_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    taxTypes.Add(new TaxType
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name"),
                        Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving tax types");
                throw;
            }

            return taxTypes;
        }

        private static void AddItemParameters(SqlCommand command, dynamic request)
        {
            command.Parameters.AddWithValue("@Name", request.Name);
            command.Parameters.AddWithValue("@Description", (object?)request.Description ?? DBNull.Value);
            command.Parameters.AddWithValue("@Model", (object?)request.Model ?? DBNull.Value);
            command.Parameters.AddWithValue("@BarCode", (object?)request.BarCode ?? DBNull.Value);
            command.Parameters.AddWithValue("@Specification", (object?)request.Specification ?? DBNull.Value);
            command.Parameters.AddWithValue("@ItemTypeId", (object?)request.ItemTypeId ?? DBNull.Value);
            command.Parameters.AddWithValue("@BrandId", (object?)request.BrandId ?? DBNull.Value);
            command.Parameters.AddWithValue("@PackingId", (object?)request.PackingId ?? DBNull.Value);
            command.Parameters.AddWithValue("@UnitId", (object?)request.UnitId ?? DBNull.Value);
            command.Parameters.AddWithValue("@PriceId", (object?)request.PriceId ?? DBNull.Value);
            command.Parameters.AddWithValue("@CategoryId", (object?)request.CategoryId ?? DBNull.Value);
            command.Parameters.AddWithValue("@SubCategoryId", (object?)request.SubCategoryId ?? DBNull.Value);
            command.Parameters.AddWithValue("@Frequency", (object?)request.Frequency ?? DBNull.Value);
            command.Parameters.AddWithValue("@IsProduct", (object?)request.IsProduct ?? DBNull.Value);
            command.Parameters.AddWithValue("@BatchExpiryRequired", (object?)request.BatchExpiryRequired ?? DBNull.Value);
            command.Parameters.AddWithValue("@DescriptionForSale", (object?)request.DescriptionForSale ?? DBNull.Value);
            command.Parameters.AddWithValue("@SaleUnitId", (object?)request.SaleUnitId ?? DBNull.Value);
            command.Parameters.AddWithValue("@Conversion", (object?)request.Conversion ?? DBNull.Value);
            command.Parameters.AddWithValue("@CaseContains", (object?)request.CaseContains ?? DBNull.Value);
            command.Parameters.AddWithValue("@HSCode", (object?)request.HSCode ?? DBNull.Value);
            command.Parameters.AddWithValue("@RetailPrice", (object?)request.RetailPrice ?? DBNull.Value);
            command.Parameters.AddWithValue("@CostMethod", (object?)request.CostMethod ?? DBNull.Value);
            command.Parameters.AddWithValue("@SalesAccountId", (object?)request.SalesAccountId ?? DBNull.Value);
            command.Parameters.AddWithValue("@InventoryAccountId", (object?)request.InventoryAccountId ?? DBNull.Value);
            command.Parameters.AddWithValue("@ExpenseAccountId", (object?)request.ExpenseAccountId ?? DBNull.Value);
            command.Parameters.AddWithValue("@TaxRateId", (object?)request.TaxRateId ?? DBNull.Value);
            command.Parameters.AddWithValue("@TaxDescriptionId", (object?)request.TaxDescriptionId ?? DBNull.Value);
            command.Parameters.AddWithValue("@TaxTypeId", (object?)request.TaxTypeId ?? DBNull.Value);
            command.Parameters.AddWithValue("@Colour", (object?)request.Colour ?? DBNull.Value);
            command.Parameters.AddWithValue("@MinimumPanicLevel", (object?)request.MinimumPanicLevel ?? DBNull.Value);
            command.Parameters.AddWithValue("@IsHidePanicFromBill", (object?)request.IsHidePanicFromBill ?? DBNull.Value);
            command.Parameters.AddWithValue("@QuantityPerPacket", (object?)request.QuantityPerPacket ?? DBNull.Value);
            command.Parameters.AddWithValue("@IsConsumptionItem", (object?)request.IsConsumptionItem ?? DBNull.Value);
            command.Parameters.AddWithValue("@IsFridgeItem", (object?)request.IsFridgeItem ?? DBNull.Value);
            command.Parameters.AddWithValue("@Code", (object?)request.Code ?? DBNull.Value);
            command.Parameters.AddWithValue("@MarketPrice", (object?)request.MarketPrice ?? DBNull.Value);
            command.Parameters.AddWithValue("@MinimumOrderPrice", (object?)request.MinimumOrderPrice ?? DBNull.Value);
            command.Parameters.AddWithValue("@MinimumOrderQuantity", (object?)request.MinimumOrderQuantity ?? DBNull.Value);
            command.Parameters.AddWithValue("@PackageType", (object?)request.PackageType ?? DBNull.Value);
            command.Parameters.AddWithValue("@PackageSize", (object?)request.PackageSize ?? DBNull.Value);
            command.Parameters.AddWithValue("@IsActive", request.IsActive);
        }

        private static Item MapToItem(SqlDataReader reader)
        {
            return new Item
            {
                Id = reader.GetInt32("Id"),
                Name = reader.GetString("Name"),
                Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                Model = reader.IsDBNull("Model") ? null : reader.GetString("Model"),
                BarCode = reader.IsDBNull("BarCode") ? null : reader.GetString("BarCode"),
                Specification = reader.IsDBNull("Specification") ? null : reader.GetString("Specification"),
                ItemTypeId = reader.IsDBNull("ItemTypeId") ? null : reader.GetInt32("ItemTypeId"),
                ItemTypeName = reader.IsDBNull("ItemTypeName") ? null : reader.GetString("ItemTypeName"),
                BrandId = reader.IsDBNull("BrandId") ? null : reader.GetInt32("BrandId"),
                BrandName = reader.IsDBNull("BrandName") ? null : reader.GetString("BrandName"),
                PackingId = reader.IsDBNull("PackingId") ? null : reader.GetInt32("PackingId"),
                PackingName = reader.IsDBNull("PackingName") ? null : reader.GetString("PackingName"),
                UnitId = reader.IsDBNull("UnitId") ? null : reader.GetInt32("UnitId"),
                UnitName = reader.IsDBNull("UnitName") ? null : reader.GetString("UnitName"),
                PriceId = reader.IsDBNull("PriceId") ? null : reader.GetInt32("PriceId"),
                RetailPrice = reader.IsDBNull("RetailPrice") ? null : reader.GetDecimal("RetailPrice"),
                SalePrice = reader.IsDBNull("SalePrice") ? null : reader.GetDecimal("SalePrice"),
                MarketPrice = reader.IsDBNull("MarketPrice") ? null : reader.GetDecimal("MarketPrice"),
                CategoryId = reader.IsDBNull("CategoryId") ? null : reader.GetInt32("CategoryId"),
                CategoryName = reader.IsDBNull("CategoryName") ? null : reader.GetString("CategoryName"),
                SubCategoryId = reader.IsDBNull("SubCategoryId") ? null : reader.GetInt32("SubCategoryId"),
                SubCategoryName = reader.IsDBNull("SubCategoryName") ? null : reader.GetString("SubCategoryName"),
                IsActive = reader.GetBoolean("IsActive"),
                CreatedById = reader.IsDBNull("CreatedById") ? null : reader.GetInt32("CreatedById"),
                CreatedOn = reader.IsDBNull("CreatedOn") ? null : reader.GetDateTime("CreatedOn"),
                ModifiedById = reader.IsDBNull("ModifiedById") ? null : reader.GetInt32("ModifiedById"),
                ModifiedOn = reader.IsDBNull("ModifiedOn") ? null : reader.GetDateTime("ModifiedOn"),
                Frequency = reader.IsDBNull("Frequency") ? null : reader.GetInt32("Frequency"),
                IsProduct = reader.IsDBNull("IsProduct") ? null : reader.GetBoolean("IsProduct"),
                BatchExpiryRequired = reader.IsDBNull("BatchExpiryRequired") ? null : reader.GetBoolean("BatchExpiryRequired"),
                DescriptionForSale = reader.IsDBNull("DescriptionForSale") ? null : reader.GetString("DescriptionForSale"),
                SaleUnitId = reader.IsDBNull("SaleUnitId") ? null : reader.GetInt32("SaleUnitId"),
                SaleUnitName = reader.IsDBNull("SaleUnitName") ? null : reader.GetString("SaleUnitName"),
                Conversion = reader.IsDBNull("Conversion") ? null : reader.GetDecimal("Conversion"),
                CaseContains = reader.IsDBNull("CaseContains") ? null : reader.GetString("CaseContains"),
                HSCode = reader.IsDBNull("HSCode") ? null : reader.GetString("HSCode"),
                ItemRetailPrice = reader.IsDBNull("ItemRetailPrice") ? null : reader.GetDecimal("ItemRetailPrice"),
                CostMethod = reader.IsDBNull("CostMethod") ? null : reader.GetInt32("CostMethod"),
                SalesAccountId = reader.IsDBNull("SalesAccountId") ? null : reader.GetInt32("SalesAccountId"),
                SalesAccountName = reader.IsDBNull("SalesAccountName") ? null : reader.GetString("SalesAccountName"),
                InventoryAccountId = reader.IsDBNull("InventoryAccountId") ? null : reader.GetInt32("InventoryAccountId"),
                InventoryAccountName = reader.IsDBNull("InventoryAccountName") ? null : reader.GetString("InventoryAccountName"),
                ExpenseAccountId = reader.IsDBNull("ExpenseAccountId") ? null : reader.GetInt32("ExpenseAccountId"),
                ExpenseAccountName = reader.IsDBNull("ExpenseAccountName") ? null : reader.GetString("ExpenseAccountName"),
                TaxRateId = reader.IsDBNull("TaxRateId") ? null : reader.GetInt32("TaxRateId"),
                TaxRateName = reader.IsDBNull("TaxRateName") ? null : reader.GetString("TaxRateName"),
                TaxDescriptionId = reader.IsDBNull("TaxDescriptionId") ? null : reader.GetInt32("TaxDescriptionId"),
                TaxDescriptionName = reader.IsDBNull("TaxDescriptionName") ? null : reader.GetString("TaxDescriptionName"),
                TaxTypeId = reader.IsDBNull("TaxTypeId") ? null : reader.GetInt32("TaxTypeId"),
                TaxTypeName = reader.IsDBNull("TaxTypeName") ? null : reader.GetString("TaxTypeName"),
                Colour = reader.IsDBNull("Colour") ? null : reader.GetString("Colour"),
                MinimumPanicLevel = reader.IsDBNull("MinimumPanicLevel") ? null : reader.GetFloat("MinimumPanicLevel"),
                IsHidePanicFromBill = reader.IsDBNull("IsHidePanicFromBill") ? null : reader.GetBoolean("IsHidePanicFromBill"),
                QuantityPerPacket = reader.IsDBNull("QuantityPerPacket") ? null : reader.GetFloat("QuantityPerPacket"),
                IsConsumptionItem = reader.IsDBNull("IsConsumptionItem") ? null : reader.GetBoolean("IsConsumptionItem"),
                IsFridgeItem = reader.IsDBNull("IsFridgeItem") ? null : reader.GetBoolean("IsFridgeItem"),
                Code = reader.IsDBNull("Code") ? null : reader.GetString("Code"),
                ItemMarketPrice = reader.IsDBNull("ItemMarketPrice") ? null : reader.GetDecimal("ItemMarketPrice"),
                MinimumOrderPrice = reader.IsDBNull("MinimumOrderPrice") ? null : reader.GetDecimal("MinimumOrderPrice"),
                MinimumOrderQuantity = reader.IsDBNull("MinimumOrderQuantity") ? null : reader.GetDecimal("MinimumOrderQuantity"),
                PackageType = reader.IsDBNull("PackageType") ? null : reader.GetString("PackageType"),
                PackageSize = reader.IsDBNull("PackageSize") ? null : reader.GetString("PackageSize")
            };
        }
    }
}