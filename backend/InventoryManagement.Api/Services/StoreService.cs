using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class StoreService : IStoreService
    {
        private readonly string _connectionString;
        private readonly ILogger<StoreService> _logger;

        public StoreService(IConfiguration configuration, ILogger<StoreService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<Store>> GetAllAsync()
        {
            try
            {
                var stores = new List<Store>();

                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("Store_GetAll", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            while (await reader.ReadAsync())
                            {
                                stores.Add(MapReaderToStore(reader));
                            }
                        }
                    }
                }

                return stores;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all stores");
                throw;
            }
        }

        public async Task<Store?> GetByIdAsync(int id)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("Store_GetById", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@StoreId", id);

                        using (var reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                return MapReaderToStore(reader);
                            }
                        }
                    }
                }

                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving store by ID: {StoreId}", id);
                throw;
            }
        }

        public async Task<Store> CreateAsync(StoreCreateRequest request)
        {
            try
            {
                int newStoreId;

                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("Store_Insert", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        AddStoreParameters(command, request);

                        var result = await command.ExecuteScalarAsync();
                        newStoreId = Convert.ToInt32(result);
                    }
                }

                var createdStore = await GetByIdAsync(newStoreId);
                return createdStore ?? throw new Exception("Failed to retrieve created store");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating store");
                throw;
            }
        }

        public async Task UpdateAsync(int id, StoreUpdateRequest request)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("Store_Update", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@StoreId", id);
                        AddStoreParameters(command, request);

                        await command.ExecuteNonQueryAsync();
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating store with ID: {StoreId}", id);
                throw;
            }
        }

        public async Task DeleteAsync(int id)
        {
            try
            {
                using (var connection = new SqlConnection(_connectionString))
                {
                    await connection.OpenAsync();

                    using (var command = new SqlCommand("Store_Delete", connection))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@StoreId", id);

                        await command.ExecuteNonQueryAsync();
                    }
                }
            }
            catch (SqlException ex) when (ex.Message.Contains("Cannot delete store"))
            {
                _logger.LogWarning(ex, "Cannot delete store with ID: {StoreId} due to dependencies", id);
                throw new InvalidOperationException(ex.Message, ex);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting store with ID: {StoreId}", id);
                throw;
            }
        }

        public async Task<IReadOnlyList<DropdownItem>> GetPharmacyStoreDropdownAsync(PharmacyStoreDropdownRequest request)
        {
            var items = new List<DropdownItem>();
            var branchId = request.BranchId.HasValue && request.BranchId > 0
                ? request.BranchId.Value
                : 1;
            var storeId = request.PharmacyStoreId.HasValue && request.PharmacyStoreId > 0
                ? request.PharmacyStoreId
                : null;
            var stockType = request.StockType.HasValue && request.StockType > 0
                ? request.StockType
                : null;
            var patientType = request.PatientType.HasValue && request.PatientType > 0
                ? request.PatientType
                : null;

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                if (stockType is null && patientType is null)
                {
                    try
                    {
                        using var sharedDropdownCommand = new SqlCommand("DropDown.SP_DDL_AllPharmacyStore", connection)
                        {
                            CommandType = CommandType.StoredProcedure
                        };

                        sharedDropdownCommand.Parameters.AddWithValue("@BranchId", branchId);

                        using (var sharedReader = await sharedDropdownCommand.ExecuteReaderAsync())
                        {
                            while (await sharedReader.ReadAsync())
                            {
                                items.Add(new DropdownItem
                                {
                                    Value = Convert.ToInt32(sharedReader.GetValue(sharedReader.GetOrdinal("Value"))),
                                    Text = sharedReader.GetString(sharedReader.GetOrdinal("Text"))
                                });
                            }
                        }

                        if (storeId is not null)
                        {
                            items = items.Where(item => item.Value == storeId.Value).ToList();
                        }

                        if (items.Count > 0)
                        {
                            return items;
                        }
                    }
                    catch (SqlException ex)
                    {
                        _logger.LogDebug(ex, "Shared pharmacy store dropdown procedure unavailable; falling back to store tables.");
                        items.Clear();
                    }
                }

                using var command = new SqlCommand(@"
SELECT DISTINCT
    s.StoreId,
    s.StoreName
FROM dbo.Stores s
LEFT JOIN dbo.StockTypeAssociations sta
    ON s.StoreId = sta.PharmacyStoreId
    AND sta.IsDeleted = 0
WHERE s.IsActive = 1
  AND (@StoreId IS NULL OR s.StoreId = @StoreId)
  AND (@StockType IS NULL OR sta.StockTypes = @StockType)
  AND (@PatientType IS NULL OR sta.PatientTypes = @PatientType)
ORDER BY s.StoreName;", connection)
                {
                    CommandType = CommandType.Text
                };

                                command.Parameters.AddWithValue("@StoreId", (object?)storeId ?? DBNull.Value);
                                command.Parameters.AddWithValue("@StockType", (object?)stockType ?? DBNull.Value);
                                command.Parameters.AddWithValue("@PatientType", (object?)patientType ?? DBNull.Value);

                using (var reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        items.Add(new DropdownItem
                        {
                            Value = reader.GetInt32(reader.GetOrdinal("StoreId")),
                            Text = reader.GetString(reader.GetOrdinal("StoreName"))
                        });
                    }
                }

                if (items.Count == 0)
                {
                    using var fallbackCommand = new SqlCommand(@"
SELECT
    s.StoreId,
    s.StoreName
FROM dbo.Stores s
WHERE s.IsActive = 1
  AND (@StoreId IS NULL OR s.StoreId = @StoreId)
ORDER BY s.StoreName;", connection)
                    {
                        CommandType = CommandType.Text
                    };

                    fallbackCommand.Parameters.AddWithValue("@StoreId", (object?)storeId ?? DBNull.Value);

                    using (var fallbackReader = await fallbackCommand.ExecuteReaderAsync())
                    {
                        while (await fallbackReader.ReadAsync())
                        {
                            items.Add(new DropdownItem
                            {
                                Value = fallbackReader.GetInt32(fallbackReader.GetOrdinal("StoreId")),
                                Text = fallbackReader.GetString(fallbackReader.GetOrdinal("StoreName"))
                            });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving pharmacy store dropdown");
                throw;
            }

            return items;
        }

        private Store MapReaderToStore(SqlDataReader reader)
        {
            return new Store
            {
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.GetString(reader.GetOrdinal("StoreName")),
                StoreCode = reader.IsDBNull(reader.GetOrdinal("StoreCode")) ? null : reader.GetString(reader.GetOrdinal("StoreCode")),
                Description = reader.IsDBNull(reader.GetOrdinal("Description")) ? null : reader.GetString(reader.GetOrdinal("Description")),
                StoreType = reader.IsDBNull(reader.GetOrdinal("StoreType")) ? null : reader.GetString(reader.GetOrdinal("StoreType")),
                ReceiptType = reader.IsDBNull(reader.GetOrdinal("ReceiptType")) ? null : reader.GetString(reader.GetOrdinal("ReceiptType")),
                POSType = reader.IsDBNull(reader.GetOrdinal("POSType")) ? null : reader.GetString(reader.GetOrdinal("POSType")),
                ParentStoreId = reader.IsDBNull(reader.GetOrdinal("ParentStoreId")) ? null : reader.GetInt32(reader.GetOrdinal("ParentStoreId")),
                ParentStoreName = reader.IsDBNull(reader.GetOrdinal("ParentStoreName")) ? null : reader.GetString(reader.GetOrdinal("ParentStoreName")),
                BuildingId = reader.IsDBNull(reader.GetOrdinal("BuildingId")) ? null : reader.GetInt32(reader.GetOrdinal("BuildingId")),
                FloorId = reader.IsDBNull(reader.GetOrdinal("FloorId")) ? null : reader.GetInt32(reader.GetOrdinal("FloorId")),
                RoomId = reader.IsDBNull(reader.GetOrdinal("RoomId")) ? null : reader.GetInt32(reader.GetOrdinal("RoomId")),
                Email = reader.IsDBNull(reader.GetOrdinal("Email")) ? null : reader.GetString(reader.GetOrdinal("Email")),
                CellNumber = reader.IsDBNull(reader.GetOrdinal("CellNumber")) ? null : reader.GetString(reader.GetOrdinal("CellNumber")),
                QueuePatientCallStatusValue = reader.IsDBNull(reader.GetOrdinal("QueuePatientCallStatusValue")) ? null : reader.GetString(reader.GetOrdinal("QueuePatientCallStatusValue")),
                MarkTokenAsAutoCollectedOnDispense = reader.IsDBNull(reader.GetOrdinal("MarkTokenAsAutoCollectedOnDispense")) ? null : reader.GetBoolean(reader.GetOrdinal("MarkTokenAsAutoCollectedOnDispense")),
                DisplayRequestsWithoutTokenIssued = reader.IsDBNull(reader.GetOrdinal("DisplayRequestsWithoutTokenIssued")) ? null : reader.GetBoolean(reader.GetOrdinal("DisplayRequestsWithoutTokenIssued")),
                EnglishNote = reader.IsDBNull(reader.GetOrdinal("EnglishNote")) ? null : reader.GetString(reader.GetOrdinal("EnglishNote")),
                UrduNote = reader.IsDBNull(reader.GetOrdinal("UrduNote")) ? null : reader.GetString(reader.GetOrdinal("UrduNote")),
                ServiceCharges = reader.IsDBNull(reader.GetOrdinal("ServiceCharges")) ? null : reader.GetBoolean(reader.GetOrdinal("ServiceCharges")),
                GST = reader.IsDBNull(reader.GetOrdinal("GST")) ? null : reader.GetBoolean(reader.GetOrdinal("GST")),
                PricingType = reader.IsDBNull(reader.GetOrdinal("PricingType")) ? null : reader.GetString(reader.GetOrdinal("PricingType")),
                DisableRetailSale = reader.IsDBNull(reader.GetOrdinal("DisableRetailSale")) ? null : reader.GetBoolean(reader.GetOrdinal("DisableRetailSale")),
                GSTN = reader.IsDBNull(reader.GetOrdinal("GSTN")) ? null : reader.GetString(reader.GetOrdinal("GSTN")),
                NTN = reader.IsDBNull(reader.GetOrdinal("NTN")) ? null : reader.GetString(reader.GetOrdinal("NTN")),
                DayClosing = reader.IsDBNull(reader.GetOrdinal("DayClosing")) ? null : reader.GetString(reader.GetOrdinal("DayClosing")),
                ClosingCashAccountId = reader.IsDBNull(reader.GetOrdinal("ClosingCashAccountId")) ? null : reader.GetInt32(reader.GetOrdinal("ClosingCashAccountId")),
                ClosingRevenueAccountId = reader.IsDBNull(reader.GetOrdinal("ClosingRevenueAccountId")) ? null : reader.GetInt32(reader.GetOrdinal("ClosingRevenueAccountId")),
                ClosingInventoryAccountId = reader.IsDBNull(reader.GetOrdinal("ClosingInventoryAccountId")) ? null : reader.GetInt32(reader.GetOrdinal("ClosingInventoryAccountId")),
                ClosingInventoryExpenseAccountId = reader.IsDBNull(reader.GetOrdinal("ClosingInventoryExpenseAccountId")) ? null : reader.GetInt32(reader.GetOrdinal("ClosingInventoryExpenseAccountId")),
                ClosingTaxExpenseAccountId = reader.IsDBNull(reader.GetOrdinal("ClosingTaxExpenseAccountId")) ? null : reader.GetInt32(reader.GetOrdinal("ClosingTaxExpenseAccountId")),
                PayableAccountId = reader.IsDBNull(reader.GetOrdinal("PayableAccountId")) ? null : reader.GetInt32(reader.GetOrdinal("PayableAccountId")),
                AdvanceTaxPercentageAccountId = reader.IsDBNull(reader.GetOrdinal("AdvanceTaxPercentageAccountId")) ? null : reader.GetInt32(reader.GetOrdinal("AdvanceTaxPercentageAccountId")),
                RevenueDiscountAccountId = reader.IsDBNull(reader.GetOrdinal("RevenueDiscountAccountId")) ? null : reader.GetInt32(reader.GetOrdinal("RevenueDiscountAccountId")),
                Address = reader.IsDBNull(reader.GetOrdinal("Address")) ? null : reader.GetString(reader.GetOrdinal("Address")),
                Latitude = reader.IsDBNull(reader.GetOrdinal("Latitude")) ? null : reader.GetString(reader.GetOrdinal("Latitude")),
                Longitude = reader.IsDBNull(reader.GetOrdinal("Longitude")) ? null : reader.GetString(reader.GetOrdinal("Longitude")),
                Country = reader.IsDBNull(reader.GetOrdinal("Country")) ? null : reader.GetString(reader.GetOrdinal("Country")),
                StateOrProvince = reader.IsDBNull(reader.GetOrdinal("StateOrProvince")) ? null : reader.GetString(reader.GetOrdinal("StateOrProvince")),
                City = reader.IsDBNull(reader.GetOrdinal("City")) ? null : reader.GetString(reader.GetOrdinal("City")),
                StoreImage = reader.IsDBNull(reader.GetOrdinal("StoreImage")) ? null : reader.GetString(reader.GetOrdinal("StoreImage")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn"))
            };
        }

        private void AddStoreParameters(SqlCommand command, object request)
        {
            var type = request.GetType();
            var properties = type.GetProperties();

            foreach (var prop in properties)
            {
                if (prop.Name == "StoreId") continue;

                var value = prop.GetValue(request);
                var paramName = $"@{prop.Name}";
                command.Parameters.AddWithValue(paramName, value ?? DBNull.Value);
            }
        }
    }
}
