using System.Data;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public class StockValueItemService : IStockValueItemService
    {
        private readonly string _connectionString;
        private readonly ILogger<StockValueItemService> _logger;

        public StockValueItemService(IConfiguration configuration, ILogger<StockValueItemService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IEnumerable<StockValueItem>> GetStockValueItemsAsync(StockValueSearchRequest request)
        {
            var items = new List<StockValueItem>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockValueItems_GetReport", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@StartDate", request.StartDate.HasValue ? (object)request.StartDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", request.EndDate.HasValue ? (object)request.EndDate.Value : DBNull.Value);
                command.Parameters.AddWithValue("@Store", string.IsNullOrEmpty(request.Store) ? (object)DBNull.Value : request.Store);
                command.Parameters.AddWithValue("@ItemType", string.IsNullOrEmpty(request.ItemType) ? (object)DBNull.Value : request.ItemType);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    items.Add(new StockValueItem
                    {
                        StoreName = reader.GetString(reader.GetOrdinal("StoreName")),
                        Name = reader.GetString(reader.GetOrdinal("Name")),
                        BatchNo = reader.GetString(reader.GetOrdinal("BatchNo")),
                        TotalItems = reader.GetInt32(reader.GetOrdinal("TotalItems")),
                        UnitPurchaseRate = reader.GetDecimal(reader.GetOrdinal("UnitPurchaseRate")),
                        TotalPurchaseRate = reader.GetDecimal(reader.GetOrdinal("TotalPurchaseRate")),
                        UnitSaleRate = reader.GetDecimal(reader.GetOrdinal("UnitSaleRate")),
                        TotalSaleRate = reader.GetDecimal(reader.GetOrdinal("TotalSaleRate"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock value items");
                throw;
            }

            return items;
        }

        public async Task<GRNReport> GetGRNReportByBatchAsync(StockValueDetailRequest request)
        {
            GRNReport report = new GRNReport();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("GRN_GetReportByBatch", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@BatchNo", request.BatchNo);
                command.Parameters.AddWithValue("@ItemName", request.ItemName);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                // First result set - GRN header info
                if (await reader.ReadAsync())
                {
                    report.InventoryNo = reader.IsDBNull(reader.GetOrdinal("InventoryNo")) ? "" : reader.GetString(reader.GetOrdinal("InventoryNo"));
                    report.EnteredBy = reader.IsDBNull(reader.GetOrdinal("EnteredBy")) ? "" : reader.GetString(reader.GetOrdinal("EnteredBy"));
                    report.DateAndTime = reader.GetDateTime(reader.GetOrdinal("DateAndTime"));
                    report.PONumber = reader.IsDBNull(reader.GetOrdinal("PONumber")) ? "" : reader.GetString(reader.GetOrdinal("PONumber"));
                    report.StockType = reader.IsDBNull(reader.GetOrdinal("StockType")) ? "" : reader.GetString(reader.GetOrdinal("StockType"));
                    report.StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? "" : reader.GetString(reader.GetOrdinal("StoreName"));
                    report.VendorName = reader.IsDBNull(reader.GetOrdinal("VendorName")) ? "" : reader.GetString(reader.GetOrdinal("VendorName"));
                    report.VendorAddress = reader.IsDBNull(reader.GetOrdinal("VendorAddress")) ? "" : reader.GetString(reader.GetOrdinal("VendorAddress"));
                    report.VendorEmail = reader.IsDBNull(reader.GetOrdinal("VendorEmail")) ? "" : reader.GetString(reader.GetOrdinal("VendorEmail"));
                    report.VendorContactNo = reader.IsDBNull(reader.GetOrdinal("VendorContactNo")) ? "" : reader.GetString(reader.GetOrdinal("VendorContactNo"));
                }

                // Second result set - GRN items
                if (await reader.NextResultAsync())
                {
                    int sr = 1;
                    while (await reader.ReadAsync())
                    {
                        report.Items.Add(new GRNReportItem
                        {
                            Sr = sr++,
                            Items = reader.GetString(reader.GetOrdinal("Items")),
                            Mfr = reader.IsDBNull(reader.GetOrdinal("Mfr")) ? "" : reader.GetString(reader.GetOrdinal("Mfr")),
                            MfgDate = reader.IsDBNull(reader.GetOrdinal("MfgDate")) ? null : reader.GetDateTime(reader.GetOrdinal("MfgDate")),
                            ExpDate = reader.IsDBNull(reader.GetOrdinal("ExpDate")) ? null : reader.GetDateTime(reader.GetOrdinal("ExpDate")),
                            BatchNo = reader.IsDBNull(reader.GetOrdinal("BatchNo")) ? null : reader.GetString(reader.GetOrdinal("BatchNo")),
                            Boxes = reader.IsDBNull(reader.GetOrdinal("Boxes")) ? null : reader.GetInt32(reader.GetOrdinal("Boxes")),
                            Packs = reader.IsDBNull(reader.GetOrdinal("Packs")) ? null : reader.GetInt32(reader.GetOrdinal("Packs")),
                            QtyPerPack = reader.IsDBNull(reader.GetOrdinal("QtyPerPack")) ? null : reader.GetInt32(reader.GetOrdinal("QtyPerPack")),
                            TotalQty = reader.GetInt32(reader.GetOrdinal("TotalQty")),
                            PackQty = reader.GetInt32(reader.GetOrdinal("PackQty")),
                            TotalPrice = reader.GetDecimal(reader.GetOrdinal("TotalPrice")),
                            UnitPrice = reader.GetDecimal(reader.GetOrdinal("UnitPrice")),
                            AdvanceTax = reader.GetDecimal(reader.GetOrdinal("AdvanceTax")),
                            AdvanceTaxAmount = reader.GetDecimal(reader.GetOrdinal("AdvanceTaxAmount")),
                            UnitSalePrice = reader.GetDecimal(reader.GetOrdinal("UnitSalePrice")),
                            RetailCharges = reader.GetDecimal(reader.GetOrdinal("RetailCharges")),
                            RetailChargesAmount = reader.GetDecimal(reader.GetOrdinal("RetailChargesAmount")),
                            GSTCharges = reader.GetDecimal(reader.GetOrdinal("GSTCharges")),
                            GSTChargesAmount = reader.GetDecimal(reader.GetOrdinal("GSTChargesAmount")),
                            TotalSalePrice = reader.GetDecimal(reader.GetOrdinal("TotalSalePrice")),
                            Margin = reader.GetDecimal(reader.GetOrdinal("Margin")),
                            Amount = reader.GetDecimal(reader.GetOrdinal("Amount")),
                            Discount = reader.GetDecimal(reader.GetOrdinal("Discount")),
                            Total = reader.GetDecimal(reader.GetOrdinal("Total"))
                        });
                    }
                }

                // Calculate totals
                report.SubTotal = report.Items.Sum(i => i.Amount);
                report.Discount = report.Items.Sum(i => i.Discount);
                report.Total = report.Items.Sum(i => i.Total);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving GRN report");
                throw;
            }

            return report;
        }
    }
}
