using Microsoft.Data.SqlClient;
using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public class PurchaseSummaryService : IPurchaseSummaryService
    {
        private readonly string _connectionString;
        private readonly ILogger<PurchaseSummaryService> _logger;

        public PurchaseSummaryService(IConfiguration configuration, ILogger<PurchaseSummaryService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<PurchaseSummaryResponse> GetAllAsync(PurchaseSummaryFilterRequest? filter = null)
        {
            var response = new PurchaseSummaryResponse();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummary_GetAll", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                // Add filter parameters
                command.Parameters.AddWithValue("@BranchId", (object?)filter?.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", (object?)filter?.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemTypeId", (object?)filter?.ItemTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemType", (object?)filter?.ItemType ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceDateStart", (object?)filter?.InvoiceDateStart ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceDateEnd", (object?)filter?.InvoiceDateEnd ?? DBNull.Value);
                command.Parameters.AddWithValue("@InventoryDateStart", (object?)filter?.InventoryDateStart ?? DBNull.Value);
                command.Parameters.AddWithValue("@InventoryDateEnd", (object?)filter?.InventoryDateEnd ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemId", (object?)filter?.ItemId ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceNo", (object?)filter?.InvoiceNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@ReportType", (object?)filter?.ReportType ?? DBNull.Value);

                using var reader = await command.ExecuteReaderAsync();
                
                // Read records
                while (await reader.ReadAsync())
                {
                    response.Records.Add(MapToPurchaseSummary(reader));
                }

                // Read totals
                if (await reader.NextResultAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        response.Totals = new PurchaseSummaryTotals
                        {
                            TotalQuantity = reader.IsDBNull(0) ? 0 : reader.GetInt32(0),
                            TotalAmount = reader.IsDBNull(1) ? 0 : reader.GetDecimal(1),
                            TotalAdvanceTax = reader.IsDBNull(2) ? 0 : reader.GetDecimal(2),
                            TotalDiscount = reader.IsDBNull(3) ? 0 : reader.GetDecimal(3),
                            TotalPrice = reader.IsDBNull(4) ? 0 : reader.GetDecimal(4)
                        };
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching purchase summary records");
                throw;
            }

            return response;
        }

        public async Task<PurchaseSummary?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummary_GetById", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@Id", id);

                using var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    return MapToPurchaseSummary(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching purchase summary with ID {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<PurchaseSummary> CreateAsync(PurchaseSummaryCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummary_Insert", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@PurchaseDate", request.PurchaseDate);
                command.Parameters.AddWithValue("@BatchNo", (object?)request.BatchNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemId", request.ItemId);
                command.Parameters.AddWithValue("@ItemName", request.ItemName);
                command.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreName", (object?)request.StoreName ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorId", (object?)request.VendorId ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorName", (object?)request.VendorName ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceNo", (object?)request.InvoiceNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceDate", (object?)request.InvoiceDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@Quantity", request.Quantity);
                command.Parameters.AddWithValue("@Amount", request.Amount);
                command.Parameters.AddWithValue("@AdvanceTax", (object?)request.AdvanceTax ?? DBNull.Value);
                command.Parameters.AddWithValue("@Discount", (object?)request.Discount ?? DBNull.Value);
                command.Parameters.AddWithValue("@TotalPrice", request.TotalPrice);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemTypeId", (object?)request.ItemTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ReportType", (object?)request.ReportType ?? DBNull.Value);
                command.Parameters.AddWithValue("@CreatedById", 1); // TODO: Get from current user

                var id = await command.ExecuteScalarAsync();
                var purchaseSummary = await GetByIdAsync(Convert.ToInt32(id));
                return purchaseSummary ?? throw new Exception("Failed to retrieve created purchase summary");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase summary");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, PurchaseSummaryUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummary_Update", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@PurchaseDate", request.PurchaseDate);
                command.Parameters.AddWithValue("@BatchNo", (object?)request.BatchNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemId", request.ItemId);
                command.Parameters.AddWithValue("@ItemName", request.ItemName);
                command.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreName", (object?)request.StoreName ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorId", (object?)request.VendorId ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorName", (object?)request.VendorName ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceNo", (object?)request.InvoiceNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceDate", (object?)request.InvoiceDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@Quantity", request.Quantity);
                command.Parameters.AddWithValue("@Amount", request.Amount);
                command.Parameters.AddWithValue("@AdvanceTax", (object?)request.AdvanceTax ?? DBNull.Value);
                command.Parameters.AddWithValue("@Discount", (object?)request.Discount ?? DBNull.Value);
                command.Parameters.AddWithValue("@TotalPrice", request.TotalPrice);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemTypeId", (object?)request.ItemTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ReportType", (object?)request.ReportType ?? DBNull.Value);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                var rowsAffected = await command.ExecuteScalarAsync();
                return Convert.ToInt32(rowsAffected) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating purchase summary with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummary_Delete", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                var rowsAffected = await command.ExecuteScalarAsync();
                return Convert.ToInt32(rowsAffected) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting purchase summary with ID {Id}", id);
                throw;
            }
        }

        public async Task<PurchaseSummaryLookupData> GetLookupDataAsync()
        {
            var lookupData = new PurchaseSummaryLookupData();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummary_GetLookupData", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                using var reader = await command.ExecuteReaderAsync();

                // Read Branches
                while (await reader.ReadAsync())
                {
                    lookupData.Branches.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                // Read Stores
                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.Stores.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                // Read Item Types
                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.ItemTypes.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                // Read Vendors
                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.Vendors.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                // Read Items
                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.Items.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching purchase summary lookup data");
                throw;
            }

            return lookupData;
        }

        private PurchaseSummary MapToPurchaseSummary(SqlDataReader reader)
        {
            return new PurchaseSummary
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                PurchaseDate = reader.IsDBNull(reader.GetOrdinal("PurchaseDate")) ? DateTime.MinValue : reader.GetDateTime(reader.GetOrdinal("PurchaseDate")),
                BatchNo = reader.IsDBNull(reader.GetOrdinal("BatchNo")) ? null : reader.GetString(reader.GetOrdinal("BatchNo")),
                // ItemId is genuinely NULL for migrated Medicine/Fee-sourced purchase lines
                // (see MigratePurchaseSummary_iHealthCure_HMSMAIN_TF.sql) - those have no
                // Inv.Items row to point at, only a denormalized display name.
                ItemId = reader.IsDBNull(reader.GetOrdinal("ItemId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemId")),
                // The referenced Item can be missing (hard-deleted after the GRN line was
                // created, since Items support hard delete) - fall back to a placeholder
                // instead of crashing the whole report on one bad row.
                ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? "(item not found)" : reader.GetString(reader.GetOrdinal("ItemName")),
                StoreId = reader.IsDBNull(reader.GetOrdinal("StoreId")) ? null : reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                VendorId = reader.IsDBNull(reader.GetOrdinal("VendorId")) ? null : reader.GetInt32(reader.GetOrdinal("VendorId")),
                VendorName = reader.IsDBNull(reader.GetOrdinal("VendorName")) ? null : reader.GetString(reader.GetOrdinal("VendorName")),
                InvoiceNo = reader.IsDBNull(reader.GetOrdinal("InvoiceNo")) ? null : reader.GetString(reader.GetOrdinal("InvoiceNo")),
                InvoiceDate = reader.IsDBNull(reader.GetOrdinal("InvoiceDate")) ? null : reader.GetDateTime(reader.GetOrdinal("InvoiceDate")),
                Quantity = reader.GetInt32(reader.GetOrdinal("Quantity")),
                Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
                AdvanceTax = reader.IsDBNull(reader.GetOrdinal("AdvanceTax")) ? null : reader.GetDecimal(reader.GetOrdinal("AdvanceTax")),
                Discount = reader.IsDBNull(reader.GetOrdinal("Discount")) ? null : reader.GetDecimal(reader.GetOrdinal("Discount")),
                TotalPrice = reader.GetDecimal(reader.GetOrdinal("TotalPrice")),
                BranchId = reader.IsDBNull(reader.GetOrdinal("BranchId")) ? null : reader.GetInt32(reader.GetOrdinal("BranchId")),
                BranchName = reader.IsDBNull(reader.GetOrdinal("BranchName")) ? null : reader.GetString(reader.GetOrdinal("BranchName")),
                ItemTypeId = reader.IsDBNull(reader.GetOrdinal("ItemTypeId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemTypeId")),
                ItemTypeName = reader.IsDBNull(reader.GetOrdinal("ItemTypeName")) ? null : reader.GetString(reader.GetOrdinal("ItemTypeName")),
                ReportType = reader.IsDBNull(reader.GetOrdinal("ReportType")) ? null : reader.GetString(reader.GetOrdinal("ReportType"))
            };
        }
    }
}
