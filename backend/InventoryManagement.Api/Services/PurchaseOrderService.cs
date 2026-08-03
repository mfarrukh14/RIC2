using System.Data;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    public class PurchaseOrderService : IPurchaseOrderService
    {
        private readonly string _connectionString;
        private readonly ILogger<PurchaseOrderService> _logger;
        private readonly string _schemaPrefix;

        public PurchaseOrderService(IConfiguration configuration, ILogger<PurchaseOrderService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
            var builder = new SqlConnectionStringBuilder(_connectionString);
            _schemaPrefix = builder.InitialCatalog.StartsWith("HMS", StringComparison.OrdinalIgnoreCase) ? "Inv" : "dbo";
        }

        private string NormalizeSql(string sql) => sql.Replace("dbo.", $"{_schemaPrefix}.");

        public async Task<IReadOnlyList<PurchaseOrderSummary>> GetAllAsync(PurchaseOrderFilter filter)
        {
            var results = new List<PurchaseOrderSummary>();

            const string sql = @"
SELECT
    po.PurchaseOrderId,
    po.PONumber,
    po.ManualPONumber,
    po.StoreId,
    s.StoreName,
    po.VendorId,
    v.Name AS VendorName,
    po.CreatedOn,
    po.POValidityDate,
    po.Status,
    po.TotalQuantity,
    po.TotalAmount,
    po.Subject,
    COUNT(poi.Id) AS ItemsCount,
    STRING_AGG(COALESCE(i.Name, 'Unassigned Item'), ', ') AS ItemSummary
FROM dbo.PurchaseOrders po
INNER JOIN dbo.PharmacyStores s ON s.StoreId = po.StoreId
INNER JOIN dbo.Vendors v ON v.Id = po.VendorId
LEFT JOIN dbo.PurchaseOrderItems poi ON poi.PurchaseOrderId = po.PurchaseOrderId AND poi.IsActive = 1
LEFT JOIN dbo.Items i ON i.Id = poi.ItemId
WHERE po.IsActive = 1
  AND (@DateFrom IS NULL OR po.CreatedOn >= @DateFrom)
  AND (@DateTo IS NULL OR po.CreatedOn <= @DateTo)
  AND (@VendorId IS NULL OR po.VendorId = @VendorId)
  AND (@Status IS NULL OR po.Status = @Status)
  AND (
        @Search IS NULL
        OR po.PONumber LIKE '%' + @Search + '%'
        OR ISNULL(po.ManualPONumber, '') LIKE '%' + @Search + '%'
        OR v.Name LIKE '%' + @Search + '%'
        OR s.StoreName LIKE '%' + @Search + '%'
        OR po.Status LIKE '%' + @Search + '%'
      )
GROUP BY
    po.PurchaseOrderId,
    po.PONumber,
    po.ManualPONumber,
    po.StoreId,
    s.StoreName,
    po.VendorId,
    v.Name,
    po.CreatedOn,
    po.POValidityDate,
    po.Status,
    po.TotalQuantity,
    po.TotalAmount,
    po.Subject
ORDER BY po.CreatedOn DESC;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection);
                command.Parameters.AddWithValue("@DateFrom", (object?)filter.DateFrom ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateTo", (object?)filter.DateTo ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorId", (object?)filter.VendorId ?? DBNull.Value);
                command.Parameters.AddWithValue("@Status", string.IsNullOrWhiteSpace(filter.Status) ? DBNull.Value : filter.Status.Trim());
                command.Parameters.AddWithValue("@Search", string.IsNullOrWhiteSpace(filter.Search) ? DBNull.Value : filter.Search.Trim());

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    results.Add(MapSummary(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase orders");
                throw;
            }

            return results;
        }

        public async Task<PurchaseOrderDetails?> GetByIdAsync(int id)
        {
            const string headerSql = @"
SELECT
    po.PurchaseOrderId,
    po.PONumber,
    po.ManualPONumber,
    po.StoreId,
    s.StoreName,
    po.VendorId,
    v.Name AS VendorName,
    po.CreatedOn,
    po.POValidityDate,
    po.Status,
    po.TotalQuantity,
    po.TotalAmount,
    po.Subject,
    po.Instructions,
    po.TermsAndConditions,
    (
        SELECT COUNT(*)
        FROM dbo.PurchaseOrderItems poi
        WHERE poi.PurchaseOrderId = po.PurchaseOrderId
          AND poi.IsActive = 1
    ) AS ItemsCount,
    (
        SELECT STRING_AGG(COALESCE(i.Name, 'Unassigned Item'), ', ')
        FROM dbo.PurchaseOrderItems poi
        LEFT JOIN dbo.Items i ON i.Id = poi.ItemId
        WHERE poi.PurchaseOrderId = po.PurchaseOrderId
          AND poi.IsActive = 1
    ) AS ItemSummary
FROM dbo.PurchaseOrders po
INNER JOIN dbo.PharmacyStores s ON s.StoreId = po.StoreId
INNER JOIN dbo.Vendors v ON v.Id = po.VendorId
WHERE po.PurchaseOrderId = @PurchaseOrderId
  AND po.IsActive = 1;";

            const string itemsSql = @"
SELECT
    poi.Id,
    poi.PurchaseOrderId,
    poi.ItemId,
    i.Name AS ItemName,
    i.Model AS ItemModel,
    it.Name AS ItemTypeName,
    poi.PacketQuantity,
    poi.UnitQuantity,
    poi.PacketPrice,
    poi.UnitPrice,
    poi.TotalPrice
FROM dbo.PurchaseOrderItems poi
LEFT JOIN dbo.Items i ON i.Id = poi.ItemId
LEFT JOIN dbo.ItemTypes it ON it.Id = i.ItemTypeId
WHERE poi.PurchaseOrderId = @PurchaseOrderId
  AND poi.IsActive = 1
ORDER BY poi.Id;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                PurchaseOrderDetails? details = null;

                using (var headerCommand = new SqlCommand(NormalizeSql(headerSql), connection))
                {
                    headerCommand.Parameters.AddWithValue("@PurchaseOrderId", id);
                    using var reader = await headerCommand.ExecuteReaderAsync();

                    if (await reader.ReadAsync())
                    {
                        var summary = MapSummary(reader);
                        details = new PurchaseOrderDetails
                        {
                            PurchaseOrderId = summary.PurchaseOrderId,
                            PONumber = summary.PONumber,
                            ManualPONumber = summary.ManualPONumber,
                            StoreId = summary.StoreId,
                            StoreName = summary.StoreName,
                            VendorId = summary.VendorId,
                            VendorName = summary.VendorName,
                            CreatedOn = summary.CreatedOn,
                            POValidityDate = summary.POValidityDate,
                            Status = summary.Status,
                            ItemsCount = summary.ItemsCount,
                            TotalQuantity = summary.TotalQuantity,
                            TotalAmount = summary.TotalAmount,
                            ItemSummary = summary.ItemSummary,
                            Subject = summary.Subject,
                            Instructions = reader.IsDBNull(reader.GetOrdinal("Instructions")) ? null : reader.GetString(reader.GetOrdinal("Instructions")),
                            TermsAndConditions = reader.IsDBNull(reader.GetOrdinal("TermsAndConditions")) ? null : reader.GetString(reader.GetOrdinal("TermsAndConditions"))
                        };
                    }
                }

                if (details == null)
                {
                    return null;
                }

                using (var itemsCommand = new SqlCommand(NormalizeSql(itemsSql), connection))
                {
                    itemsCommand.Parameters.AddWithValue("@PurchaseOrderId", id);
                    using var reader = await itemsCommand.ExecuteReaderAsync();
                    while (await reader.ReadAsync())
                    {
                        details.Items.Add(MapItem(reader));
                    }
                }

                return details;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase order with ID {PurchaseOrderId}", id);
                throw;
            }
        }

        public async Task<PurchaseOrderDetails> CreateAsync(PurchaseOrderCreateRequest request)
        {
            var now = DateTime.UtcNow;
            var suffix = Guid.NewGuid().ToString("N")[..6].ToUpperInvariant();
            var poNumber = $"PO-{now:yyyyMMddHHmmss}-{suffix}";
            var totalQuantity = request.Items.Sum(item => item.UnitQuantity);
            var totalAmount = request.Items.Sum(item => item.UnitQuantity * item.UnitPrice);

            const string insertHeaderSql = @"
INSERT INTO dbo.PurchaseOrders
(
    PONumber,
    ManualPONumber,
    StoreId,
    VendorId,
    POValidityDate,
    Subject,
    Instructions,
    TermsAndConditions,
    Status,
    TotalQuantity,
    TotalAmount,
    IsActive,
    CreatedById,
    CreatedOn
)
VALUES
(
    @PONumber,
    @ManualPONumber,
    @StoreId,
    @VendorId,
    @POValidityDate,
    @Subject,
    @Instructions,
    @TermsAndConditions,
    'Pending',
    @TotalQuantity,
    @TotalAmount,
    1,
    1,
    SYSUTCDATETIME()
);

SELECT CAST(SCOPE_IDENTITY() AS INT);";

            const string insertItemSql = @"
INSERT INTO dbo.PurchaseOrderItems
(
    PurchaseOrderId,
    ItemId,
    ItemType,
    PacketQuantity,
    UnitQuantity,
    PacketPrice,
    UnitPrice,
    TotalPrice,
    IsActive,
    CreatedById,
    CreatedOn
)
VALUES
(
    @PurchaseOrderId,
    @ItemId,
    @ItemType,
    @PacketQuantity,
    @UnitQuantity,
    @PacketPrice,
    @UnitPrice,
    @TotalPrice,
    1,
    1,
    SYSUTCDATETIME()
);";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = await connection.BeginTransactionAsync();

                int purchaseOrderId;
                using (var headerCommand = new SqlCommand(NormalizeSql(insertHeaderSql), connection, (SqlTransaction)transaction))
                {
                    headerCommand.Parameters.AddWithValue("@PONumber", poNumber);
                    headerCommand.Parameters.AddWithValue("@ManualPONumber", (object?)request.ManualPONumber ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@StoreId", request.StoreId);
                    headerCommand.Parameters.AddWithValue("@VendorId", request.VendorId);
                    headerCommand.Parameters.AddWithValue("@POValidityDate", (object?)request.POValidityDate ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@Subject", (object?)request.Subject ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@Instructions", (object?)request.Instructions ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@TermsAndConditions", (object?)request.TermsAndConditions ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@TotalQuantity", totalQuantity);
                    headerCommand.Parameters.AddWithValue("@TotalAmount", totalAmount);

                    purchaseOrderId = Convert.ToInt32(await headerCommand.ExecuteScalarAsync());
                }

                foreach (var item in request.Items)
                {
                    using var itemCommand = new SqlCommand(NormalizeSql(insertItemSql), connection, (SqlTransaction)transaction);
                    itemCommand.Parameters.AddWithValue("@PurchaseOrderId", purchaseOrderId);
                    itemCommand.Parameters.AddWithValue("@ItemId", item.ItemId);
                    itemCommand.Parameters.AddWithValue("@ItemType", (object?)item.ItemType ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@PacketQuantity", (object?)item.PacketQuantity ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@UnitQuantity", item.UnitQuantity);
                    itemCommand.Parameters.AddWithValue("@PacketPrice", (object?)item.PacketPrice ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@UnitPrice", item.UnitPrice);
                    itemCommand.Parameters.AddWithValue("@TotalPrice", item.UnitQuantity * item.UnitPrice);
                    await itemCommand.ExecuteNonQueryAsync();
                }

                await transaction.CommitAsync();

                return await GetByIdAsync(purchaseOrderId)
                    ?? throw new InvalidOperationException("Purchase order was created but could not be retrieved.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase order");
                throw;
            }
        }

        private static PurchaseOrderSummary MapSummary(SqlDataReader reader)
        {
            return new PurchaseOrderSummary
            {
                PurchaseOrderId = reader.GetInt32(reader.GetOrdinal("PurchaseOrderId")),
                PONumber = reader.GetString(reader.GetOrdinal("PONumber")),
                ManualPONumber = reader.IsDBNull(reader.GetOrdinal("ManualPONumber")) ? null : reader.GetString(reader.GetOrdinal("ManualPONumber")),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.GetString(reader.GetOrdinal("StoreName")),
                VendorId = reader.GetInt32(reader.GetOrdinal("VendorId")),
                VendorName = reader.GetString(reader.GetOrdinal("VendorName")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                POValidityDate = reader.IsDBNull(reader.GetOrdinal("POValidityDate")) ? null : reader.GetDateTime(reader.GetOrdinal("POValidityDate")),
                Status = reader.GetString(reader.GetOrdinal("Status")),
                ItemsCount = reader.GetInt32(reader.GetOrdinal("ItemsCount")),
                TotalQuantity = reader.GetDecimal(reader.GetOrdinal("TotalQuantity")),
                TotalAmount = reader.GetDecimal(reader.GetOrdinal("TotalAmount")),
                ItemSummary = reader.IsDBNull(reader.GetOrdinal("ItemSummary")) ? null : reader.GetString(reader.GetOrdinal("ItemSummary")),
                Subject = reader.IsDBNull(reader.GetOrdinal("Subject")) ? null : reader.GetString(reader.GetOrdinal("Subject"))
            };
        }

        private static PurchaseOrderItem MapItem(SqlDataReader reader)
        {
            return new PurchaseOrderItem
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                PurchaseOrderId = reader.GetInt32(reader.GetOrdinal("PurchaseOrderId")),
                ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? "Unassigned Item" : reader.GetString(reader.GetOrdinal("ItemName")),
                ItemModel = reader.IsDBNull(reader.GetOrdinal("ItemModel")) ? null : reader.GetString(reader.GetOrdinal("ItemModel")),
                ItemTypeName = reader.IsDBNull(reader.GetOrdinal("ItemTypeName")) ? null : reader.GetString(reader.GetOrdinal("ItemTypeName")),
                PacketQuantity = reader.IsDBNull(reader.GetOrdinal("PacketQuantity")) ? null : reader.GetDecimal(reader.GetOrdinal("PacketQuantity")),
                UnitQuantity = reader.GetDecimal(reader.GetOrdinal("UnitQuantity")),
                PacketPrice = reader.IsDBNull(reader.GetOrdinal("PacketPrice")) ? null : reader.GetDecimal(reader.GetOrdinal("PacketPrice")),
                UnitPrice = reader.GetDecimal(reader.GetOrdinal("UnitPrice")),
                TotalPrice = reader.GetDecimal(reader.GetOrdinal("TotalPrice"))
            };
        }
    }
}