using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public class GRNService : IGRNService
    {
        private readonly string _connectionString;
        private readonly ILogger<GRNService> _logger;

        public GRNService(IConfiguration configuration, ILogger<GRNService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<List<GRN>> GetAllAsync()
        {
            var grns = new List<GRN>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("GRN_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    grns.Add(new GRN
                    {
                        Id = reader.GetInt32("Id"),
                        PurchaseOrderId = reader.GetInt32("PurchaseOrderId"),
                        PONumber = reader.IsDBNull("PONumber") ? null : reader.GetString("PONumber"),
                        InvoiceNo = reader.IsDBNull("InvoiceNo") ? null : reader.GetString("InvoiceNo"),
                        StockTypeId = reader.IsDBNull("StockTypeId") ? null : reader.GetInt32("StockTypeId"),
                        StockTypeName = reader.IsDBNull("StockTypeName") ? null : reader.GetString("StockTypeName"),
                        DateAndTime = reader.IsDBNull("DateAndTime") ? null : reader.GetDateTime("DateAndTime"),
                        IsActive = reader.GetBoolean("IsActive"),
                        CreatedOn = reader.IsDBNull("CreatedOn") ? null : reader.GetDateTime("CreatedOn")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all GRNs");
                throw;
            }

            return grns;
        }

        public async Task<GRN?> GetByIdAsync(int id)
        {
            GRN? grn = null;

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("GRN_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    grn = new GRN
                    {
                        Id = reader.GetInt32("Id"),
                        PurchaseOrderId = reader.GetInt32("PurchaseOrderId"),
                        PONumber = reader.IsDBNull("PONumber") ? null : reader.GetString("PONumber"),
                        VendorId = reader.IsDBNull("VendorId") ? null : reader.GetInt32("VendorId"),
                        VendorName = reader.IsDBNull("VendorName") ? null : reader.GetString("VendorName"),
                        InvoiceNo = reader.IsDBNull("InvoiceNo") ? null : reader.GetString("InvoiceNo"),
                        StockTypeId = reader.IsDBNull("StockTypeId") ? null : reader.GetInt32("StockTypeId"),
                        StockTypeName = reader.IsDBNull("StockTypeName") ? null : reader.GetString("StockTypeName"),
                        DateAndTime = reader.IsDBNull("DateAndTime") ? null : reader.GetDateTime("DateAndTime"),
                        VendorInvoiceNo = reader.IsDBNull("VendorInvoiceNo") ? null : reader.GetString("VendorInvoiceNo"),
                        VendorInvoiceDate = reader.IsDBNull("VendorInvoiceDate") ? null : reader.GetDateTime("VendorInvoiceDate"),
                        IsActive = reader.GetBoolean("IsActive"),
                        CreatedById = reader.IsDBNull("CreatedById") ? null : reader.GetInt32("CreatedById"),
                        CreatedOn = reader.IsDBNull("CreatedOn") ? null : reader.GetDateTime("CreatedOn"),
                        ModifiedById = reader.IsDBNull("ModifiedById") ? null : reader.GetInt32("ModifiedById"),
                        ModifiedOn = reader.IsDBNull("ModifiedOn") ? null : reader.GetDateTime("ModifiedOn")
                    };
                }

                // Read items
                if (await reader.NextResultAsync() && grn != null)
                {
                    while (await reader.ReadAsync())
                    {
                        grn.Items.Add(MapToGRNItem(reader));
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving GRN with ID {Id}", id);
                throw;
            }

            return grn;
        }

        public async Task<POForGRN?> GetPODetailsAsync(int purchaseOrderId)
        {
            POForGRN? po = null;

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("GRN_GetPODetails", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };
                command.Parameters.AddWithValue("@PurchaseOrderId", purchaseOrderId);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    po = new POForGRN
                    {
                        Id = reader.GetInt32("Id"),
                        PONumber = reader.GetString("PONumber"),
                        VendorId = reader.GetInt32("VendorId"),
                        VendorName = reader.GetString("VendorName"),
                        DateAndTime = reader.IsDBNull("DateAndTime") ? null : reader.GetDateTime("DateAndTime"),
                        Status = reader.IsDBNull("Status") ? null : reader.GetString("Status")
                    };
                }

                // Read PO items
                if (await reader.NextResultAsync() && po != null)
                {
                    while (await reader.ReadAsync())
                    {
                        po.Items.Add(new POItemForGRN
                        {
                            Id = reader.GetInt32("Id"),
                            PurchaseOrderId = reader.GetInt32("PurchaseOrderId"),
                            ItemId = reader.GetInt32("ItemId"),
                            ItemName = reader.GetString("ItemName"),
                            OrderedQuantity = reader.GetInt32("OrderedQuantity"),
                            ReceivedQuantity = reader.GetInt32("ReceivedQuantity"),
                            RemainingQuantity = reader.GetInt32("RemainingQuantity"),
                            Rate = reader.IsDBNull("Rate") ? null : reader.GetDecimal("Rate"),
                            TotalAmount = reader.IsDBNull("TotalAmount") ? null : reader.GetDecimal("TotalAmount")
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving PO details with ID {PurchaseOrderId}", purchaseOrderId);
                throw;
            }

            return po;
        }

        public async Task<GRN> CreateAsync(GRNCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                // Create GRN header
                using var command = new SqlCommand("GRN_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@PONumber", request.PONumber);
                command.Parameters.AddWithValue("@VendorId", request.VendorId);
                command.Parameters.AddWithValue("@InvoiceNo", (object?)request.InvoiceNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@StockTypeId", (object?)request.StockTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateAndTime", (object?)request.DateAndTime ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorInvoiceNo", (object?)request.VendorInvoiceNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorInvoiceDate", (object?)request.VendorInvoiceDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@CreatedById", 1); // TODO: Get from current user

                var grnId = Convert.ToInt32(await command.ExecuteScalarAsync());

                // Create GRN items
                foreach (var item in request.Items)
                {
                    using var itemCommand = new SqlCommand("GRNItem_Insert", connection)
                    {
                        CommandType = CommandType.StoredProcedure
                    };

                    AddGRNItemParameters(itemCommand, grnId, item);
                    await itemCommand.ExecuteScalarAsync();
                }

                return await GetByIdAsync(grnId) ?? throw new Exception("Failed to retrieve created GRN");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating GRN");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, GRNUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("GRN_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@InvoiceNo", (object?)request.InvoiceNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@PONumber", (object?)request.PONumber ?? DBNull.Value);
                command.Parameters.AddWithValue("@StockTypeId", (object?)request.StockTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateAndTime", (object?)request.DateAndTime ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorInvoiceNo", (object?)request.VendorInvoiceNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorInvoiceDate", (object?)request.VendorInvoiceDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                await connection.OpenAsync();
                var affectedRows = await command.ExecuteScalarAsync();
                return Convert.ToInt32(affectedRows) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating GRN with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("GRN_Delete", connection)
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
                _logger.LogError(ex, "Error deleting GRN with ID {Id}", id);
                throw;
            }
        }

        public async Task<GRNLookupData> GetLookupDataAsync()
        {
            var lookupData = new GRNLookupData();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("GRN_GetLookupData", connection)
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
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving GRN lookup data");
                throw;
            }

            return lookupData;
        }

        private static GRNItem MapToGRNItem(SqlDataReader reader)
        {
            return new GRNItem
            {
                Id = reader.GetInt32("Id"),
                GRNId = reader.GetInt32("GRNId"),
                ItemId = reader.GetInt32("ItemId"),
                ItemName = reader.IsDBNull("ItemName") ? null : reader.GetString("ItemName"),
                ManufacturerId = reader.IsDBNull("ManufacturerId") ? null : reader.GetInt32("ManufacturerId"),
                ManufacturerName = reader.IsDBNull("ManufacturerName") ? null : reader.GetString("ManufacturerName"),
                MfgDate = reader.IsDBNull("MfgDate") ? null : reader.GetDateTime("MfgDate"),
                ExpiryDate = reader.IsDBNull("ExpiryDate") ? null : reader.GetDateTime("ExpiryDate"),
                RegistrationNumber = reader.IsDBNull("RegistrationNumber") ? null : reader.GetString("RegistrationNumber"),
                LotNo = reader.IsDBNull("LotNo") ? null : reader.GetString("LotNo"),
                BatchNo = reader.IsDBNull("BatchNo") ? null : reader.GetString("BatchNo"),
                NoOfBoxes = reader.IsDBNull("NoOfBoxes") ? null : reader.GetInt32("NoOfBoxes"),
                NoOfPackets = reader.IsDBNull("NoOfPackets") ? null : reader.GetInt32("NoOfPackets"),
                ItemPerPacket = reader.IsDBNull("ItemPerPacket") ? null : reader.GetInt32("ItemPerPacket"),
                TotalItem = reader.IsDBNull("TotalItem") ? null : reader.GetInt32("TotalItem"),
                PackQuantity = reader.IsDBNull("PackQuantity") ? null : reader.GetInt32("PackQuantity"),
                ReceivedQuantity = reader.IsDBNull("ReceivedQuantity") ? null : reader.GetInt32("ReceivedQuantity"),
                RemainingQuantity = reader.IsDBNull("RemainingQuantity") ? null : reader.GetInt32("RemainingQuantity"),
                TotalBuyingPrice = reader.IsDBNull("TotalBuyingPrice") ? null : reader.GetDecimal("TotalBuyingPrice"),
                UnitBuyingPrice = reader.IsDBNull("UnitBuyingPrice") ? null : reader.GetDecimal("UnitBuyingPrice"),
                AdvanceTaxPercentage = reader.IsDBNull("AdvanceTaxPercentage") ? null : reader.GetDecimal("AdvanceTaxPercentage"),
                AdvanceTaxAmount = reader.IsDBNull("AdvanceTaxAmount") ? null : reader.GetDecimal("AdvanceTaxAmount"),
                Discount = reader.IsDBNull("Discount") ? false : reader.GetBoolean("Discount"),
                DiscountAmount = reader.IsDBNull("DiscountAmount") ? null : reader.GetDecimal("DiscountAmount"),
                RetailCharges = reader.IsDBNull("RetailCharges") ? false : reader.GetBoolean("RetailCharges"),
                RetailChargesAmount = reader.IsDBNull("RetailChargesAmount") ? null : reader.GetDecimal("RetailChargesAmount"),
                GSTCharges = reader.IsDBNull("GSTCharges") ? false : reader.GetBoolean("GSTCharges"),
                GSTChargesAmount = reader.IsDBNull("GSTChargesAmount") ? null : reader.GetDecimal("GSTChargesAmount"),
                UnitSellingPrice = reader.IsDBNull("UnitSellingPrice") ? null : reader.GetDecimal("UnitSellingPrice"),
                TotalSellingPrice = reader.IsDBNull("TotalSellingPrice") ? null : reader.GetDecimal("TotalSellingPrice"),
                ProfitMarginPerItem = reader.IsDBNull("ProfitMarginPerItem") ? null : reader.GetDecimal("ProfitMarginPerItem"),
                ProfitPerItem = reader.IsDBNull("ProfitPerItem") ? null : reader.GetDecimal("ProfitPerItem")
            };
        }

        private static void AddGRNItemParameters(SqlCommand command, int grnId, GRNItemRequest item)
        {
            command.Parameters.AddWithValue("@GRNId", grnId);
            command.Parameters.AddWithValue("@ItemId", item.ItemId);
            command.Parameters.AddWithValue("@ManufacturerId", (object?)item.ManufacturerId ?? DBNull.Value);
            command.Parameters.AddWithValue("@MfgDate", (object?)item.MfgDate ?? DBNull.Value);
            command.Parameters.AddWithValue("@ExpiryDate", (object?)item.ExpiryDate ?? DBNull.Value);
            command.Parameters.AddWithValue("@RegistrationNumber", (object?)item.RegistrationNumber ?? DBNull.Value);
            command.Parameters.AddWithValue("@LotNo", (object?)item.LotNo ?? DBNull.Value);
            command.Parameters.AddWithValue("@BatchNo", (object?)item.BatchNo ?? DBNull.Value);
            command.Parameters.AddWithValue("@NoOfBoxes", (object?)item.NoOfBoxes ?? DBNull.Value);
            command.Parameters.AddWithValue("@NoOfPackets", (object?)item.NoOfPackets ?? DBNull.Value);
            command.Parameters.AddWithValue("@ItemPerPacket", (object?)item.ItemPerPacket ?? DBNull.Value);
            command.Parameters.AddWithValue("@TotalItem", (object?)item.TotalItem ?? DBNull.Value);
            command.Parameters.AddWithValue("@PackQuantity", (object?)item.PackQuantity ?? DBNull.Value);
            command.Parameters.AddWithValue("@ReceivedQuantity", (object?)item.ReceivedQuantity ?? DBNull.Value);
            command.Parameters.AddWithValue("@RemainingQuantity", (object?)item.RemainingQuantity ?? DBNull.Value);
            command.Parameters.AddWithValue("@TotalBuyingPrice", (object?)item.TotalBuyingPrice ?? DBNull.Value);
            command.Parameters.AddWithValue("@UnitBuyingPrice", (object?)item.UnitBuyingPrice ?? DBNull.Value);
            command.Parameters.AddWithValue("@AdvanceTaxPercentage", (object?)item.AdvanceTaxPercentage ?? DBNull.Value);
            command.Parameters.AddWithValue("@AdvanceTaxAmount", (object?)item.AdvanceTaxAmount ?? DBNull.Value);
            command.Parameters.AddWithValue("@Discount", item.Discount);
            command.Parameters.AddWithValue("@DiscountAmount", (object?)item.DiscountAmount ?? DBNull.Value);
            command.Parameters.AddWithValue("@RetailCharges", item.RetailCharges);
            command.Parameters.AddWithValue("@RetailChargesAmount", (object?)item.RetailChargesAmount ?? DBNull.Value);
            command.Parameters.AddWithValue("@GSTCharges", item.GSTCharges);
            command.Parameters.AddWithValue("@GSTChargesAmount", (object?)item.GSTChargesAmount ?? DBNull.Value);
            command.Parameters.AddWithValue("@UnitSellingPrice", (object?)item.UnitSellingPrice ?? DBNull.Value);
            command.Parameters.AddWithValue("@TotalSellingPrice", (object?)item.TotalSellingPrice ?? DBNull.Value);
            command.Parameters.AddWithValue("@ProfitMarginPerItem", (object?)item.ProfitMarginPerItem ?? DBNull.Value);
            command.Parameters.AddWithValue("@ProfitPerItem", (object?)item.ProfitPerItem ?? DBNull.Value);
        }
    }
}
