using Microsoft.Data.SqlClient;
using InventoryManagement.API.Models;
using InventoryManagement.Api.Models;

namespace InventoryManagement.API.Services
{
    public class PurchaseSummaryInvoiceService : IPurchaseSummaryInvoiceService
    {
        private readonly string _connectionString;
        private readonly ILogger<PurchaseSummaryInvoiceService> _logger;

        public PurchaseSummaryInvoiceService(IConfiguration configuration, ILogger<PurchaseSummaryInvoiceService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<PurchaseSummaryInvoiceResponse> GetAllAsync(PurchaseSummaryInvoiceFilterRequest? filter = null)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(filter?.PageNumber ?? 1, filter?.PageSize ?? PaginationHelper.DefaultPageSize);
            var response = new PurchaseSummaryInvoiceResponse { PageNumber = pageNumber, PageSize = pageSize };

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummaryInvoice_GetAll", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                // Add filter parameters
                command.Parameters.AddWithValue("@BranchId", (object?)filter?.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", (object?)filter?.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@InventoryDateStart", (object?)filter?.InventoryDateStart ?? DBNull.Value);
                command.Parameters.AddWithValue("@InventoryDateEnd", (object?)filter?.InventoryDateEnd ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorId", (object?)filter?.VendorId ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceDateStart", (object?)filter?.InvoiceDateStart ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceDateEnd", (object?)filter?.InvoiceDateEnd ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceNo", (object?)filter?.InvoiceNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@ReportType", (object?)filter?.ReportType ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceType", (object?)filter?.InvoiceType ?? DBNull.Value);
                PaginationHelper.AddPagingParameters(command, pageNumber, pageSize);

                using var reader = await command.ExecuteReaderAsync();

                // Read records
                while (await reader.ReadAsync())
                {
                    if (response.TotalCount == 0)
                    {
                        response.TotalCount = PaginationHelper.ReadTotalCount(reader);
                    }

                    response.Records.Add(MapToPurchaseSummaryInvoice(reader));
                }

                // Read totals
                if (await reader.NextResultAsync())
                {
                    if (await reader.ReadAsync())
                    {
                        response.Totals = new PurchaseSummaryInvoiceTotals
                        {
                            TotalAmount = reader.IsDBNull(0) ? 0 : reader.GetDecimal(0),
                            TotalAdvanceTax = reader.IsDBNull(1) ? 0 : reader.GetDecimal(1),
                            TotalDiscount = reader.IsDBNull(2) ? 0 : reader.GetDecimal(2),
                            GrandTotal = reader.IsDBNull(3) ? 0 : reader.GetDecimal(3)
                        };
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching purchase summary invoice records");
                throw;
            }

            return response;
        }

        public async Task<PurchaseSummaryInvoice?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummaryInvoice_GetById", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@Id", id);

                using var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    return MapToPurchaseSummaryInvoice(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching purchase summary invoice with ID {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<PurchaseSummaryInvoice> CreateAsync(PurchaseSummaryInvoiceCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummaryInvoice_Insert", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@InvoiceDate", request.InvoiceDate);
                command.Parameters.AddWithValue("@InvoiceNo", request.InvoiceNo);
                command.Parameters.AddWithValue("@VendorId", (object?)request.VendorId ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorName", (object?)request.VendorName ?? DBNull.Value);
                command.Parameters.AddWithValue("@Amount", request.Amount);
                command.Parameters.AddWithValue("@AdvanceTax", (object?)request.AdvanceTax ?? DBNull.Value);
                command.Parameters.AddWithValue("@Discount", (object?)request.Discount ?? DBNull.Value);
                command.Parameters.AddWithValue("@TotalAmount", request.TotalAmount);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@InventoryDate", (object?)request.InventoryDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@ReportType", (object?)request.ReportType ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceType", (object?)request.InvoiceType ?? DBNull.Value);
                command.Parameters.AddWithValue("@CreatedById", 1); // TODO: Get from current user

                var id = await command.ExecuteScalarAsync();
                var invoice = await GetByIdAsync(Convert.ToInt32(id));
                return invoice ?? throw new Exception("Failed to retrieve created purchase summary invoice");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase summary invoice");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, PurchaseSummaryInvoiceUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummaryInvoice_Update", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@InvoiceDate", request.InvoiceDate);
                command.Parameters.AddWithValue("@InvoiceNo", request.InvoiceNo);
                command.Parameters.AddWithValue("@VendorId", (object?)request.VendorId ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorName", (object?)request.VendorName ?? DBNull.Value);
                command.Parameters.AddWithValue("@Amount", request.Amount);
                command.Parameters.AddWithValue("@AdvanceTax", (object?)request.AdvanceTax ?? DBNull.Value);
                command.Parameters.AddWithValue("@Discount", (object?)request.Discount ?? DBNull.Value);
                command.Parameters.AddWithValue("@TotalAmount", request.TotalAmount);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@InventoryDate", (object?)request.InventoryDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@ReportType", (object?)request.ReportType ?? DBNull.Value);
                command.Parameters.AddWithValue("@InvoiceType", (object?)request.InvoiceType ?? DBNull.Value);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                var rowsAffected = await command.ExecuteScalarAsync();
                return Convert.ToInt32(rowsAffected) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating purchase summary invoice with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummaryInvoice_Delete", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                var rowsAffected = await command.ExecuteScalarAsync();
                return Convert.ToInt32(rowsAffected) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting purchase summary invoice with ID {Id}", id);
                throw;
            }
        }

        public async Task<PurchaseSummaryInvoiceLookupData> GetLookupDataAsync()
        {
            var lookupData = new PurchaseSummaryInvoiceLookupData();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("PurchaseSummaryInvoice_GetLookupData", connection);
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
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching purchase summary invoice lookup data");
                throw;
            }

            return lookupData;
        }

        private PurchaseSummaryInvoice MapToPurchaseSummaryInvoice(SqlDataReader reader)
        {
            return new PurchaseSummaryInvoice
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                InvoiceDate = reader.GetDateTime(reader.GetOrdinal("InvoiceDate")),
                InvoiceNo = reader.GetString(reader.GetOrdinal("InvoiceNo")),
                VendorId = reader.IsDBNull(reader.GetOrdinal("VendorId")) ? null : reader.GetInt32(reader.GetOrdinal("VendorId")),
                VendorName = reader.IsDBNull(reader.GetOrdinal("VendorName")) ? null : reader.GetString(reader.GetOrdinal("VendorName")),
                Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
                AdvanceTax = reader.IsDBNull(reader.GetOrdinal("AdvanceTax")) ? null : reader.GetDecimal(reader.GetOrdinal("AdvanceTax")),
                Discount = reader.IsDBNull(reader.GetOrdinal("Discount")) ? null : reader.GetDecimal(reader.GetOrdinal("Discount")),
                TotalAmount = reader.GetDecimal(reader.GetOrdinal("TotalAmount")),
                BranchId = reader.IsDBNull(reader.GetOrdinal("BranchId")) ? null : reader.GetInt32(reader.GetOrdinal("BranchId")),
                BranchName = reader.IsDBNull(reader.GetOrdinal("BranchName")) ? null : reader.GetString(reader.GetOrdinal("BranchName")),
                StoreId = reader.IsDBNull(reader.GetOrdinal("StoreId")) ? null : reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                InventoryDate = reader.IsDBNull(reader.GetOrdinal("InventoryDate")) ? null : reader.GetDateTime(reader.GetOrdinal("InventoryDate")),
                ReportType = reader.IsDBNull(reader.GetOrdinal("ReportType")) ? null : reader.GetString(reader.GetOrdinal("ReportType")),
                InvoiceType = reader.IsDBNull(reader.GetOrdinal("InvoiceType")) ? null : reader.GetString(reader.GetOrdinal("InvoiceType"))
            };
        }
    }
}
