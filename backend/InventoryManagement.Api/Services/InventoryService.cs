using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public class InventoryService : IInventoryService
    {
        private readonly string _connectionString;
        private readonly ILogger<InventoryService> _logger;

        public InventoryService(IConfiguration configuration, ILogger<InventoryService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? throw new ArgumentNullException("Connection string not found");
            _logger = logger;
        }

        public async Task<PagedResult<Inventory>> GetAllAsync(InventoryFilterRequest? filter = null)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(filter?.PageNumber ?? 1, filter?.PageSize ?? PaginationHelper.DefaultPageSize);
            var inventories = new List<Inventory>();
            var totalCount = 0;

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Inventory_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@SearchTerm", (object?)filter?.SearchTerm ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorId", (object?)filter?.VendorId ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateFrom", (object?)filter?.DateFrom ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateTo", (object?)filter?.DateTo ?? DBNull.Value);
                PaginationHelper.AddPagingParameters(command, pageNumber, pageSize);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    if (totalCount == 0)
                    {
                        totalCount = PaginationHelper.ReadTotalCount(reader);
                    }
                    inventories.Add(MapToInventory(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving inventories");
                throw;
            }

            return new PagedResult<Inventory> { Items = inventories, TotalCount = totalCount, PageNumber = pageNumber, PageSize = pageSize };
        }

        public async Task<Inventory?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Inventory_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                Inventory? inventory = null;
                if (await reader.ReadAsync())
                {
                    inventory = MapToInventory(reader);
                }

                // Read details
                if (inventory != null && await reader.NextResultAsync())
                {
                    inventory.Details = new List<InventoryDetail>();
                    while (await reader.ReadAsync())
                    {
                        inventory.Details.Add(MapToInventoryDetail(reader));
                    }
                }

                return inventory;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving inventory with ID {Id}", id);
                throw;
            }
        }

        public async Task<int> CreateAsync(InventoryCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Inventory_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@VendorId", request.VendorId);
                command.Parameters.AddWithValue("@StoreId", request.StoreId);
                command.Parameters.AddWithValue("@BranchId", request.BranchId);
                command.Parameters.AddWithValue("@StockTypeId", request.StockTypeId);
                command.Parameters.AddWithValue("@VendorInvoiceNumber", (object?)request.VendorInvoiceNumber ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorInvoiceTimestamp", (object?)request.VendorInvoiceTimestamp ?? DBNull.Value);
                command.Parameters.AddWithValue("@ManualPurchaseOrderNumber", (object?)request.ManualPurchaseOrderNumber ?? DBNull.Value);
                command.Parameters.AddWithValue("@CreatedById", 1); // TODO: Get from current user

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();
                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating inventory");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, InventoryUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Inventory_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@VendorId", request.VendorId);
                command.Parameters.AddWithValue("@StoreId", request.StoreId);
                command.Parameters.AddWithValue("@BranchId", request.BranchId);
                command.Parameters.AddWithValue("@StockTypeId", request.StockTypeId);
                command.Parameters.AddWithValue("@VendorInvoiceNumber", (object?)request.VendorInvoiceNumber ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorInvoiceTimestamp", (object?)request.VendorInvoiceTimestamp ?? DBNull.Value);
                command.Parameters.AddWithValue("@ManualPurchaseOrderNumber", (object?)request.ManualPurchaseOrderNumber ?? DBNull.Value);
                command.Parameters.AddWithValue("@Amount", (object?)request.Amount ?? DBNull.Value);
                command.Parameters.AddWithValue("@Discount", (object?)request.Discount ?? DBNull.Value);
                command.Parameters.AddWithValue("@DiscountType", (object?)request.DiscountType ?? DBNull.Value);
                command.Parameters.AddWithValue("@Total", (object?)request.Total ?? DBNull.Value);
                command.Parameters.AddWithValue("@AdvanceTaxPercentage", (object?)request.AdvanceTaxPercentage ?? DBNull.Value);
                command.Parameters.AddWithValue("@AdvanceTaxCalculatedAmount", (object?)request.AdvanceTaxCalculatedAmount ?? DBNull.Value);
                command.Parameters.AddWithValue("@RetailCharges", (object?)request.RetailCharges ?? DBNull.Value);
                command.Parameters.AddWithValue("@RetailChargesType", (object?)request.RetailChargesType ?? DBNull.Value);
                command.Parameters.AddWithValue("@GSTCharges", (object?)request.GSTCharges ?? DBNull.Value);
                command.Parameters.AddWithValue("@RetailChargesCalculatedAmount", (object?)request.RetailChargesCalculatedAmount ?? DBNull.Value);
                command.Parameters.AddWithValue("@GSTChargesCalculatedAmount", (object?)request.GSTChargesCalculatedAmount ?? DBNull.Value);
                command.Parameters.AddWithValue("@TotalBuyingPrice", (object?)request.TotalBuyingPrice ?? DBNull.Value);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                await connection.OpenAsync();
                var affectedRows = await command.ExecuteScalarAsync();
                return Convert.ToInt32(affectedRows) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating inventory with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Inventory_Delete", connection)
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
                _logger.LogError(ex, "Error deleting inventory with ID {Id}", id);
                throw;
            }
        }

        public async Task<int> CreateDetailAsync(InventoryDetailCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("InventoryDetail_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                AddDetailParameters(command, request);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();
                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating inventory detail");
                throw;
            }
        }

        public async Task<bool> UpdateDetailAsync(int id, InventoryDetailUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("InventoryDetail_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                AddDetailParameters(command, request, includeInventoryId: false);

                await connection.OpenAsync();
                var affectedRows = await command.ExecuteScalarAsync();
                return Convert.ToInt32(affectedRows) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating inventory detail with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteDetailAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("InventoryDetail_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                var affectedRows = await command.ExecuteScalarAsync();
                return Convert.ToInt32(affectedRows) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting inventory detail with ID {Id}", id);
                throw;
            }
        }

        public async Task<InventoryLookupData> GetLookupDataAsync()
        {
            var lookupData = new InventoryLookupData();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Inventory_GetLookupData", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                // Vendors
                while (await reader.ReadAsync())
                {
                    lookupData.Vendors.Add(new Vendor
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name")
                    });
                }

                // Stores
                if (await reader.NextResultAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        lookupData.Stores.Add(new Store
                        {
                            StoreId = reader.GetInt32("Id"),
                            StoreName = reader.GetString("Name")
                        });
                    }
                }

                // Stock Types
                if (await reader.NextResultAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        lookupData.StockTypes.Add(new StockType
                        {
                            Id = reader.GetInt32("Id"),
                            Name = reader.GetString("Name")
                        });
                    }
                }

                // Items
                if (await reader.NextResultAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        lookupData.Items.Add(new Item
                        {
                            Id = reader.GetInt32("Id"),
                            Name = reader.GetString("Name")
                        });
                    }
                }

                // Manufacturers
                if (await reader.NextResultAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        lookupData.Manufacturers.Add(new Manufacturer
                        {
                            Id = reader.GetInt32("Id"),
                            Name = reader.GetString("Name")
                        });
                    }
                }

                // Branches
                if (await reader.NextResultAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        lookupData.Branches.Add(new Branch
                        {
                            Id = reader.GetInt32("Id"),
                            Name = reader.GetString("Name")
                        });
                    }
                }

                // Categories
                if (await reader.NextResultAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        lookupData.Categories.Add(new Category
                        {
                            Id = reader.GetInt32("Id"),
                            Name = reader.GetString("Name")
                        });
                    }
                }

                // Brands
                if (await reader.NextResultAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        lookupData.Brands.Add(new Brand
                        {
                            Id = reader.GetInt32("Id"),
                            Name = reader.GetString("Name")
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving lookup data");
                throw;
            }

            return lookupData;
        }

        private static void AddDetailParameters(SqlCommand command, InventoryDetailCreateRequest request, bool includeInventoryId = true)
        {
            // InventoryDetail_Update has no @InventoryId parameter - a detail's
            // parent inventory can't be changed via update, only Insert accepts it.
            if (includeInventoryId)
            {
                command.Parameters.AddWithValue("@InventoryId", request.InventoryId);
            }
            command.Parameters.AddWithValue("@ItemId", (object?)request.ItemId ?? DBNull.Value);
            command.Parameters.AddWithValue("@MedicineId", (object?)request.MedicineId ?? DBNull.Value);
            command.Parameters.AddWithValue("@SubServiceId", (object?)request.SubServiceId ?? DBNull.Value);
            command.Parameters.AddWithValue("@ManufacturerId", (object?)request.ManufacturerId ?? DBNull.Value);
            command.Parameters.AddWithValue("@MfgDate", (object?)request.MfgDate ?? DBNull.Value);
            command.Parameters.AddWithValue("@ExpiryDate", (object?)request.ExpiryDate ?? DBNull.Value);
            command.Parameters.AddWithValue("@NoOfBoxes", (object?)request.NoOfBoxes ?? DBNull.Value);
            command.Parameters.AddWithValue("@NoOfPackets", (object?)request.NoOfPackets ?? DBNull.Value);
            command.Parameters.AddWithValue("@ItemsPerPacket", (object?)request.ItemsPerPacket ?? DBNull.Value);
            command.Parameters.AddWithValue("@TotalItems", (object?)request.TotalItems ?? DBNull.Value);
            command.Parameters.AddWithValue("@PackQuantity", (object?)request.PackQuantity ?? DBNull.Value);
            command.Parameters.AddWithValue("@UnitBuyingPrice", (object?)request.UnitBuyingPrice ?? DBNull.Value);
            command.Parameters.AddWithValue("@TotalBuyingPrice", (object?)request.TotalBuyingPrice ?? DBNull.Value);
            command.Parameters.AddWithValue("@AdvanceTaxPercentage", (object?)request.AdvanceTaxPercentage ?? DBNull.Value);
            command.Parameters.AddWithValue("@AdvanceTaxAmount", (object?)request.AdvanceTaxAmount ?? DBNull.Value);
            command.Parameters.AddWithValue("@Discount", (object?)request.Discount ?? DBNull.Value);
            command.Parameters.AddWithValue("@DiscountAmount", (object?)request.DiscountAmount ?? DBNull.Value);
            command.Parameters.AddWithValue("@RetailCharges", (object?)request.RetailCharges ?? DBNull.Value);
            command.Parameters.AddWithValue("@RetailChargesAmount", (object?)request.RetailChargesAmount ?? DBNull.Value);
            command.Parameters.AddWithValue("@GSTCharges", (object?)request.GSTCharges ?? DBNull.Value);
            command.Parameters.AddWithValue("@GSTChargesAmount", (object?)request.GSTChargesAmount ?? DBNull.Value);
            command.Parameters.AddWithValue("@UnitSellingPrice", (object?)request.UnitSellingPrice ?? DBNull.Value);
            command.Parameters.AddWithValue("@TotalSellingPrice", (object?)request.TotalSellingPrice ?? DBNull.Value);
            command.Parameters.AddWithValue("@ProfitMarginPerItem", (object?)request.ProfitMarginPerItem ?? DBNull.Value);
            command.Parameters.AddWithValue("@ProfitPerItem", (object?)request.ProfitPerItem ?? DBNull.Value);
        }

        private static Inventory MapToInventory(SqlDataReader reader)
        {
            return new Inventory
            {
                Id = reader.GetInt32("Id"),
                PurchaseOrderNumber = reader.IsDBNull("PurchaseOrderNumber") ? null : reader.GetString("PurchaseOrderNumber"),
                InvoiceNo = reader.IsDBNull("InvoiceNo") ? null : reader.GetString("InvoiceNo"),
                PurchaseOrderId = reader.IsDBNull("PurchaseOrderId") ? null : reader.GetInt32("PurchaseOrderId"),
                VendorId = reader.IsDBNull("VendorId") ? null : reader.GetInt32("VendorId"),
                VendorName = reader.IsDBNull("VendorName") ? null : reader.GetString("VendorName"),
                StoreId = reader.GetInt32("StoreId"),
                StoreName = reader.IsDBNull("StoreName") ? null : reader.GetString("StoreName"),
                BranchId = reader.GetInt32("BranchId"),
                BranchName = reader.IsDBNull("BranchName") ? null : reader.GetString("BranchName"),
                IsActive = reader.GetBoolean("IsActive"),
                CreatedById = reader.IsDBNull("CreatedById") ? null : reader.GetInt32("CreatedById"),
                CreatedOn = reader.IsDBNull("CreatedOn") ? null : reader.GetDateTime("CreatedOn"),
                ModifiedById = reader.IsDBNull("ModifiedById") ? null : reader.GetInt32("ModifiedById"),
                ModifiedOn = reader.IsDBNull("ModifiedOn") ? null : reader.GetDateTime("ModifiedOn"),
                IsFinalized = reader.IsDBNull("IsFinalized") ? null : reader.GetBoolean("IsFinalized"),
                StockTypeId = reader.IsDBNull("StockTypeId") ? null : reader.GetInt32("StockTypeId"),
                StockTypeName = reader.IsDBNull("StockTypeName") ? null : reader.GetString("StockTypeName"),
                VendorInvoiceNumber = reader.IsDBNull("VendorInvoiceNumber") ? null : reader.GetString("VendorInvoiceNumber"),
                VendorInvoiceTimestamp = reader.IsDBNull("VendorInvoiceTimestamp") ? null : reader.GetDateTime("VendorInvoiceTimestamp"),
                Amount = reader.IsDBNull("Amount") ? null : reader.GetFloat("Amount"),
                Discount = reader.IsDBNull("Discount") ? null : reader.GetFloat("Discount"),
                DiscountType = reader.IsDBNull("DiscountType") ? null : reader.GetInt32("DiscountType"),
                Total = reader.IsDBNull("Total") ? null : reader.GetFloat("Total"),
                PaidAmount = reader.IsDBNull("PaidAmount") ? null : reader.GetFloat("PaidAmount"),
                PaymentStatusId = reader.IsDBNull("PaymentStatusId") ? null : reader.GetInt32("PaymentStatusId"),
                TotalPaidAmount = reader.IsDBNull("TotalPaidAmount") ? null : reader.GetFloat("TotalPaidAmount"),
                PayableAccountId = reader.IsDBNull("PayableAccountId") ? null : reader.GetInt32("PayableAccountId"),
                IsPaymentPending = reader.IsDBNull("IsPaymentPending") ? null : reader.GetBoolean("IsPaymentPending"),
                VoucherId = reader.IsDBNull("VoucherId") ? null : reader.GetInt32("VoucherId"),
                TotalVoucherPaidAmount = reader.IsDBNull("TotalVoucherPaidAmount") ? null : reader.GetFloat("TotalVoucherPaidAmount"),
                TotalBuyingPrice = reader.IsDBNull("TotalBuyingPrice") ? null : reader.GetFloat("TotalBuyingPrice"),
                ReceiptPath = reader.IsDBNull("ReceiptPath") ? null : reader.GetString("ReceiptPath"),
                AdvanceTaxPercentage = reader.IsDBNull("AdvanceTaxPercentage") ? null : reader.GetFloat("AdvanceTaxPercentage"),
                AdvanceTaxCalculatedAmount = reader.IsDBNull("AdvanceTaxCalculatedAmount") ? null : reader.GetFloat("AdvanceTaxCalculatedAmount"),
                RetailCharges = reader.IsDBNull("RetailCharges") ? null : reader.GetFloat("RetailCharges"),
                RetailChargesType = reader.IsDBNull("RetailChargesType") ? null : reader.GetInt32("RetailChargesType"),
                GSTCharges = reader.IsDBNull("GSTCharges") ? null : reader.GetFloat("GSTCharges"),
                RetailChargesCalculatedAmount = reader.IsDBNull("RetailChargesCalculatedAmount") ? null : reader.GetFloat("RetailChargesCalculatedAmount"),
                GSTChargesCalculatedAmount = reader.IsDBNull("GSTChargesCalculatedAmount") ? null : reader.GetFloat("GSTChargesCalculatedAmount"),
                ManualPurchaseOrderNumber = reader.IsDBNull("ManualPurchaseOrderNumber") ? null : reader.GetString("ManualPurchaseOrderNumber"),
                TotalQuantity = reader.IsDBNull("TotalQuantity") ? null : reader.GetInt32("TotalQuantity")
            };
        }

        private static InventoryDetail MapToInventoryDetail(SqlDataReader reader)
        {
            return new InventoryDetail
            {
                Id = reader.GetInt32("Id"),
                InventoryId = reader.GetInt32("InventoryId"),
                ItemId = reader.IsDBNull("ItemId") ? null : reader.GetInt32("ItemId"),
                MedicineId = reader.IsDBNull("MedicineId") ? null : reader.GetInt32("MedicineId"),
                SubServiceId = reader.IsDBNull("SubServiceId") ? null : reader.GetInt32("SubServiceId"),
                ItemName = reader.IsDBNull("ItemName") ? null : reader.GetString("ItemName"),
                ManufacturerId = reader.IsDBNull("ManufacturerId") ? null : reader.GetInt32("ManufacturerId"),
                ManufacturerName = reader.IsDBNull("ManufacturerName") ? null : reader.GetString("ManufacturerName"),
                MfgDate = reader.IsDBNull("MfgDate") ? null : reader.GetDateTime("MfgDate"),
                ExpiryDate = reader.IsDBNull("ExpiryDate") ? null : reader.GetDateTime("ExpiryDate"),
                NoOfBoxes = reader.IsDBNull("NoOfBoxes") ? null : reader.GetInt32("NoOfBoxes"),
                NoOfPackets = reader.IsDBNull("NoOfPackets") ? null : reader.GetInt32("NoOfPackets"),
                ItemsPerPacket = reader.IsDBNull("ItemsPerPacket") ? null : reader.GetInt32("ItemsPerPacket"),
                TotalItems = reader.IsDBNull("TotalItems") ? null : reader.GetInt32("TotalItems"),
                PackQuantity = reader.IsDBNull("PackQuantity") ? null : reader.GetInt32("PackQuantity"),
                UnitBuyingPrice = reader.IsDBNull("UnitBuyingPrice") ? null : reader.GetFloat("UnitBuyingPrice"),
                TotalBuyingPrice = reader.IsDBNull("TotalBuyingPrice") ? null : reader.GetFloat("TotalBuyingPrice"),
                AdvanceTaxPercentage = reader.IsDBNull("AdvanceTaxPercentage") ? null : reader.GetFloat("AdvanceTaxPercentage"),
                AdvanceTaxAmount = reader.IsDBNull("AdvanceTaxAmount") ? null : reader.GetFloat("AdvanceTaxAmount"),
                Discount = reader.IsDBNull("Discount") ? null : reader.GetBoolean("Discount"),
                DiscountAmount = reader.IsDBNull("DiscountAmount") ? null : reader.GetFloat("DiscountAmount"),
                RetailCharges = reader.IsDBNull("RetailCharges") ? null : reader.GetBoolean("RetailCharges"),
                RetailChargesAmount = reader.IsDBNull("RetailChargesAmount") ? null : reader.GetFloat("RetailChargesAmount"),
                GSTCharges = reader.IsDBNull("GSTCharges") ? null : reader.GetBoolean("GSTCharges"),
                GSTChargesAmount = reader.IsDBNull("GSTChargesAmount") ? null : reader.GetFloat("GSTChargesAmount"),
                UnitSellingPrice = reader.IsDBNull("UnitSellingPrice") ? null : reader.GetFloat("UnitSellingPrice"),
                TotalSellingPrice = reader.IsDBNull("TotalSellingPrice") ? null : reader.GetFloat("TotalSellingPrice"),
                ProfitMarginPerItem = reader.IsDBNull("ProfitMarginPerItem") ? null : reader.GetFloat("ProfitMarginPerItem"),
                ProfitPerItem = reader.IsDBNull("ProfitPerItem") ? null : reader.GetFloat("ProfitPerItem")
            };
        }
    }
}
