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

        public async Task<PagedResult<PurchaseOrderSummary>> GetAllAsync(PurchaseOrderFilter filter)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(filter.PageNumber, filter.PageSize);
            var results = new List<PurchaseOrderSummary>();
            var totalCount = 0;

            // Two-phase: filter/sort/page the header rows FIRST (cheap, no join
            // fan-out), then compute ItemsCount/ItemSummary via OUTER APPLY only for
            // the @PageSize rows on the page - a GROUP BY over the full joined set
            // would otherwise force evaluating every order's item list before OFFSET
            // could even apply (same convention as Stock_Search / StockAdjustment_GetAll).
            const string sql = @"
;WITH FilteredOrders AS (
    SELECT
        po.PurchaseOrderId,
        po.PONumber,
        po.ManualPONumber,
        po.StoreId,
        s.StoreName,
        po.VendorId,
        v.Name AS VendorName,
        v.Email AS VendorEmail,
        v.CNo AS VendorPhone,
        po.CreatedOn,
        po.POValidityDate,
        po.Status,
        po.RejectionRemarks,
        po.TotalQuantity,
        po.TotalAmount,
        po.Subject
    FROM dbo.PurchaseOrders po
    INNER JOIN dbo.PharmacyStores s ON s.StoreId = po.StoreId
    INNER JOIN dbo.Vendors v ON v.Id = po.VendorId
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
),
Paged AS (
    SELECT *, COUNT(*) OVER() AS TotalCount
    FROM FilteredOrders
    ORDER BY CreatedOn DESC
    OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY
)
SELECT
    Paged.*,
    ISNULL(agg.ItemsCount, 0) AS ItemsCount,
    agg.ItemSummary
FROM Paged
OUTER APPLY (
    SELECT
        COUNT(*) AS ItemsCount,
        STRING_AGG(COALESCE(i.Name, med.MedicineFullName, f.Name, 'Unassigned Item'), ', ') AS ItemSummary
    FROM dbo.PurchaseOrderItems poi
    LEFT JOIN dbo.Items i ON i.Id = poi.ItemId
    LEFT JOIN Pharmacy.Medicines med ON med.MedicineId = poi.MedicineId
    LEFT JOIN Account.Fees f ON f.Id = poi.SubServiceId
    WHERE poi.PurchaseOrderId = Paged.PurchaseOrderId
      AND poi.IsActive = 1
) agg
ORDER BY Paged.CreatedOn DESC;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection);
                command.Parameters.AddWithValue("@DateFrom", (object?)filter.DateFrom ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateTo", (object?)filter.DateTo ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorId", (object?)filter.VendorId ?? DBNull.Value);
                command.Parameters.AddWithValue("@Status", string.IsNullOrWhiteSpace(filter.Status) ? DBNull.Value : filter.Status.Trim());
                command.Parameters.AddWithValue("@Search", string.IsNullOrWhiteSpace(filter.Search) ? DBNull.Value : filter.Search.Trim());
                command.Parameters.AddWithValue("@Offset", (pageNumber - 1) * pageSize);
                command.Parameters.AddWithValue("@Take", pageSize);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    if (totalCount == 0)
                    {
                        totalCount = PaginationHelper.ReadTotalCount(reader);
                    }
                    results.Add(MapSummary(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase orders");
                throw;
            }

            return new PagedResult<PurchaseOrderSummary> { Items = results, TotalCount = totalCount, PageNumber = pageNumber, PageSize = pageSize };
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
    v.Email AS VendorEmail,
    v.CNo AS VendorPhone,
    po.CreatedOn,
    po.POValidityDate,
    po.Status,
    po.RejectionRemarks,
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
        SELECT STRING_AGG(COALESCE(i.Name, med.MedicineFullName, f.Name, 'Unassigned Item'), ', ')
        FROM dbo.PurchaseOrderItems poi
        LEFT JOIN dbo.Items i ON i.Id = poi.ItemId
        LEFT JOIN Pharmacy.Medicines med ON med.MedicineId = poi.MedicineId
        LEFT JOIN Account.Fees f ON f.Id = poi.SubServiceId
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
    poi.MedicineId,
    poi.SubServiceId,
    COALESCE(i.Name, med.MedicineFullName, f.Name) AS ItemName,
    i.Model AS ItemModel,
    poi.ItemType,
    it.Name AS ItemTypeName,
    poi.PacketQuantity,
    poi.UnitQuantity,
    poi.PacketPrice,
    poi.UnitPrice,
    poi.TotalPrice
FROM dbo.PurchaseOrderItems poi
LEFT JOIN dbo.Items i ON i.Id = poi.ItemId
LEFT JOIN dbo.ItemTypes it ON it.Id = i.ItemTypeId
LEFT JOIN Pharmacy.Medicines med ON med.MedicineId = poi.MedicineId
LEFT JOIN Account.Fees f ON f.Id = poi.SubServiceId
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
                            VendorEmail = summary.VendorEmail,
                            VendorPhone = summary.VendorPhone,
                            CreatedOn = summary.CreatedOn,
                            POValidityDate = summary.POValidityDate,
                            Status = summary.Status,
                            RejectionRemarks = summary.RejectionRemarks,
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

        public async Task<PurchaseOrderDetails> CreateAsync(PurchaseOrderCreateRequest request, int userId)
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
    @CreatedById,
    SYSUTCDATETIME()
);

SELECT CAST(SCOPE_IDENTITY() AS INT);";

            const string insertItemSql = @"
INSERT INTO dbo.PurchaseOrderItems
(
    PurchaseOrderId,
    ItemId,
    MedicineId,
    SubServiceId,
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
    @MedicineId,
    @SubServiceId,
    @ItemType,
    @PacketQuantity,
    @UnitQuantity,
    @PacketPrice,
    @UnitPrice,
    @TotalPrice,
    1,
    @CreatedById,
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
                    headerCommand.Parameters.AddWithValue("@CreatedById", userId);

                    purchaseOrderId = Convert.ToInt32(await headerCommand.ExecuteScalarAsync());
                }

                foreach (var item in request.Items)
                {
                    using var itemCommand = new SqlCommand(NormalizeSql(insertItemSql), connection, (SqlTransaction)transaction);
                    itemCommand.Parameters.AddWithValue("@PurchaseOrderId", purchaseOrderId);
                    itemCommand.Parameters.AddWithValue("@ItemId", (object?)item.ItemId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@MedicineId", (object?)item.MedicineId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@SubServiceId", (object?)item.SubServiceId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@ItemType", (object?)item.ItemType ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@PacketQuantity", (object?)item.PacketQuantity ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@UnitQuantity", item.UnitQuantity);
                    itemCommand.Parameters.AddWithValue("@PacketPrice", (object?)item.PacketPrice ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@UnitPrice", item.UnitPrice);
                    itemCommand.Parameters.AddWithValue("@TotalPrice", item.UnitQuantity * item.UnitPrice);
                    itemCommand.Parameters.AddWithValue("@CreatedById", userId);
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

        // Reconciles the item list by hard-replacing all item rows (delete then
        // re-insert) rather than diffing in place - the Edit UI only lets a user
        // edit an existing row's price/qty or remove+add rows, never "change this
        // row's item in place", so there is no in-place item-identity update to
        // preserve. Before replacing, the previous rows are captured so the
        // add/remove delta can be written to PurchaseOrderItemLog (the "View Log"
        // feature) - an item present before and after (same ItemId/MedicineId/
        // SubServiceId) is a price/qty edit and is NOT logged, only genuine
        // additions/removals are, matching what the Edit UI can actually do.
        public async Task<bool> UpdateAsync(int id, PurchaseOrderUpdateRequest request, int userId)
        {
            var totalQuantity = request.Items.Sum(item => item.UnitQuantity);
            var totalAmount = request.Items.Sum(item => item.UnitQuantity * item.UnitPrice);

            const string updateHeaderSql = @"
UPDATE dbo.PurchaseOrders
SET
    StoreId = @StoreId,
    VendorId = @VendorId,
    ManualPONumber = @ManualPONumber,
    POValidityDate = @POValidityDate,
    Subject = @Subject,
    Instructions = @Instructions,
    TermsAndConditions = @TermsAndConditions,
    TotalQuantity = @TotalQuantity,
    TotalAmount = @TotalAmount,
    ModifiedById = @ModifiedById,
    ModifiedOn = SYSUTCDATETIME()
WHERE PurchaseOrderId = @PurchaseOrderId
  AND IsActive = 1;";

            const string existingItemsSql = @"
SELECT
    poi.ItemId, poi.MedicineId, poi.SubServiceId, poi.ItemType,
    COALESCE(i.Name, med.MedicineFullName, f.Name, 'Unassigned Item') AS ItemName
FROM dbo.PurchaseOrderItems poi
LEFT JOIN dbo.Items i ON i.Id = poi.ItemId
LEFT JOIN Pharmacy.Medicines med ON med.MedicineId = poi.MedicineId
LEFT JOIN Account.Fees f ON f.Id = poi.SubServiceId
WHERE poi.PurchaseOrderId = @PurchaseOrderId
  AND poi.IsActive = 1;";

            const string deleteItemsSql = "DELETE FROM dbo.PurchaseOrderItems WHERE PurchaseOrderId = @PurchaseOrderId;";

            const string insertItemSql = @"
INSERT INTO dbo.PurchaseOrderItems
(
    PurchaseOrderId, ItemId, MedicineId, SubServiceId, ItemType,
    PacketQuantity, UnitQuantity, PacketPrice, UnitPrice, TotalPrice,
    IsActive, CreatedById, CreatedOn
)
VALUES
(
    @PurchaseOrderId, @ItemId, @MedicineId, @SubServiceId, @ItemType,
    @PacketQuantity, @UnitQuantity, @PacketPrice, @UnitPrice, @TotalPrice,
    1, @CreatedById, SYSUTCDATETIME()
);";

            const string resolveItemNameSql = @"
SELECT COALESCE(i.Name, med.MedicineFullName, f.Name, 'Unassigned Item') AS ItemName
FROM (SELECT 1 AS X) anchor
LEFT JOIN dbo.Items i ON i.Id = @ItemId
LEFT JOIN Pharmacy.Medicines med ON med.MedicineId = @MedicineId
LEFT JOIN Account.Fees f ON f.Id = @SubServiceId;";

            const string insertLogSql = @"
INSERT INTO dbo.PurchaseOrderItemLog (PurchaseOrderId, ItemType, PreviousItemName, CurrentItemName, CreatedOn, ModifiedById)
VALUES (@PurchaseOrderId, @ItemType, @PreviousItemName, @CurrentItemName, SYSUTCDATETIME(), @ModifiedById);";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = await connection.BeginTransactionAsync();

                var oldItems = new List<(int? ItemId, int? MedicineId, int? SubServiceId, string? ItemType, string ItemName)>();
                using (var command = new SqlCommand(NormalizeSql(existingItemsSql), connection, (SqlTransaction)transaction))
                {
                    command.Parameters.AddWithValue("@PurchaseOrderId", id);
                    using var reader = await command.ExecuteReaderAsync();
                    while (await reader.ReadAsync())
                    {
                        oldItems.Add((
                            reader.IsDBNull(reader.GetOrdinal("ItemId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemId")),
                            reader.IsDBNull(reader.GetOrdinal("MedicineId")) ? null : reader.GetInt32(reader.GetOrdinal("MedicineId")),
                            reader.IsDBNull(reader.GetOrdinal("SubServiceId")) ? null : reader.GetInt32(reader.GetOrdinal("SubServiceId")),
                            reader.IsDBNull(reader.GetOrdinal("ItemType")) ? null : reader.GetString(reader.GetOrdinal("ItemType")),
                            reader.GetString(reader.GetOrdinal("ItemName"))
                        ));
                    }
                }

                bool SameIdentity(int? aItem, int? aMed, int? aSub, PurchaseOrderCreateItem b) =>
                    aItem == b.ItemId && aMed == b.MedicineId && aSub == b.SubServiceId;

                var removedItems = oldItems.Where(o => !request.Items.Any(n => SameIdentity(o.ItemId, o.MedicineId, o.SubServiceId, n))).ToList();
                var addedItems = request.Items.Where(n => !oldItems.Any(o => SameIdentity(o.ItemId, o.MedicineId, o.SubServiceId, n))).ToList();

                using (var command = new SqlCommand(NormalizeSql(updateHeaderSql), connection, (SqlTransaction)transaction))
                {
                    command.Parameters.AddWithValue("@PurchaseOrderId", id);
                    command.Parameters.AddWithValue("@StoreId", request.StoreId);
                    command.Parameters.AddWithValue("@VendorId", request.VendorId);
                    command.Parameters.AddWithValue("@ManualPONumber", (object?)request.ManualPONumber ?? DBNull.Value);
                    command.Parameters.AddWithValue("@POValidityDate", (object?)request.POValidityDate ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Subject", (object?)request.Subject ?? DBNull.Value);
                    command.Parameters.AddWithValue("@Instructions", (object?)request.Instructions ?? DBNull.Value);
                    command.Parameters.AddWithValue("@TermsAndConditions", (object?)request.TermsAndConditions ?? DBNull.Value);
                    command.Parameters.AddWithValue("@TotalQuantity", totalQuantity);
                    command.Parameters.AddWithValue("@TotalAmount", totalAmount);
                    command.Parameters.AddWithValue("@ModifiedById", userId);

                    var affected = await command.ExecuteNonQueryAsync();
                    if (affected == 0)
                    {
                        await transaction.RollbackAsync();
                        return false;
                    }
                }

                using (var command = new SqlCommand(NormalizeSql(deleteItemsSql), connection, (SqlTransaction)transaction))
                {
                    command.Parameters.AddWithValue("@PurchaseOrderId", id);
                    await command.ExecuteNonQueryAsync();
                }

                foreach (var item in request.Items)
                {
                    using var command = new SqlCommand(NormalizeSql(insertItemSql), connection, (SqlTransaction)transaction);
                    command.Parameters.AddWithValue("@PurchaseOrderId", id);
                    command.Parameters.AddWithValue("@ItemId", (object?)item.ItemId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@MedicineId", (object?)item.MedicineId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@SubServiceId", (object?)item.SubServiceId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@ItemType", (object?)item.ItemType ?? DBNull.Value);
                    command.Parameters.AddWithValue("@PacketQuantity", (object?)item.PacketQuantity ?? DBNull.Value);
                    command.Parameters.AddWithValue("@UnitQuantity", item.UnitQuantity);
                    command.Parameters.AddWithValue("@PacketPrice", (object?)item.PacketPrice ?? DBNull.Value);
                    command.Parameters.AddWithValue("@UnitPrice", item.UnitPrice);
                    command.Parameters.AddWithValue("@TotalPrice", item.UnitQuantity * item.UnitPrice);
                    command.Parameters.AddWithValue("@CreatedById", userId);
                    await command.ExecuteNonQueryAsync();
                }

                foreach (var removed in removedItems)
                {
                    using var command = new SqlCommand(NormalizeSql(insertLogSql), connection, (SqlTransaction)transaction);
                    command.Parameters.AddWithValue("@PurchaseOrderId", id);
                    command.Parameters.AddWithValue("@ItemType", (object?)removed.ItemType ?? DBNull.Value);
                    command.Parameters.AddWithValue("@PreviousItemName", removed.ItemName);
                    command.Parameters.AddWithValue("@CurrentItemName", DBNull.Value);
                    command.Parameters.AddWithValue("@ModifiedById", userId);
                    await command.ExecuteNonQueryAsync();
                }

                foreach (var added in addedItems)
                {
                    string addedName = "Unassigned Item";
                    using (var nameCommand = new SqlCommand(NormalizeSql(resolveItemNameSql), connection, (SqlTransaction)transaction))
                    {
                        nameCommand.Parameters.AddWithValue("@ItemId", (object?)added.ItemId ?? DBNull.Value);
                        nameCommand.Parameters.AddWithValue("@MedicineId", (object?)added.MedicineId ?? DBNull.Value);
                        nameCommand.Parameters.AddWithValue("@SubServiceId", (object?)added.SubServiceId ?? DBNull.Value);
                        var result = await nameCommand.ExecuteScalarAsync();
                        if (result != null && result != DBNull.Value)
                        {
                            addedName = (string)result;
                        }
                    }

                    using var command = new SqlCommand(NormalizeSql(insertLogSql), connection, (SqlTransaction)transaction);
                    command.Parameters.AddWithValue("@PurchaseOrderId", id);
                    command.Parameters.AddWithValue("@ItemType", (object?)added.ItemType ?? DBNull.Value);
                    command.Parameters.AddWithValue("@PreviousItemName", DBNull.Value);
                    command.Parameters.AddWithValue("@CurrentItemName", addedName);
                    command.Parameters.AddWithValue("@ModifiedById", userId);
                    await command.ExecuteNonQueryAsync();
                }

                await transaction.CommitAsync();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating purchase order with ID {PurchaseOrderId}", id);
                throw;
            }
        }

        public async Task<bool> RejectAsync(int id, string remarks, int userId)
        {
            const string updateSql = @"
UPDATE dbo.PurchaseOrders
SET Status = 'Rejected',
    RejectionRemarks = @Remarks,
    ModifiedById = @ModifiedById,
    ModifiedOn = SYSUTCDATETIME()
WHERE PurchaseOrderId = @PurchaseOrderId
  AND IsActive = 1;";

            const string insertStatusSql = @"
INSERT INTO dbo.PurchaseOrderStatus (PurchaseOrderId, Status, Notes, CreatedById, CreatedOn)
VALUES (@PurchaseOrderId, 'Rejected', @Remarks, @CreatedById, SYSUTCDATETIME());";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = await connection.BeginTransactionAsync();

                int affected;
                using (var command = new SqlCommand(NormalizeSql(updateSql), connection, (SqlTransaction)transaction))
                {
                    command.Parameters.AddWithValue("@PurchaseOrderId", id);
                    command.Parameters.AddWithValue("@Remarks", remarks);
                    command.Parameters.AddWithValue("@ModifiedById", userId);
                    affected = await command.ExecuteNonQueryAsync();
                }

                if (affected == 0)
                {
                    await transaction.RollbackAsync();
                    return false;
                }

                using (var command = new SqlCommand(NormalizeSql(insertStatusSql), connection, (SqlTransaction)transaction))
                {
                    command.Parameters.AddWithValue("@PurchaseOrderId", id);
                    command.Parameters.AddWithValue("@Remarks", remarks);
                    command.Parameters.AddWithValue("@CreatedById", userId);
                    await command.ExecuteNonQueryAsync();
                }

                await transaction.CommitAsync();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error rejecting purchase order with ID {PurchaseOrderId}", id);
                throw;
            }
        }

        public async Task<List<PurchaseOrderItemLogEntry>> GetItemLogAsync(int id)
        {
            const string sql = @"
SELECT
    l.Id, l.PurchaseOrderId, l.ItemType, l.PreviousItemName, l.CurrentItemName, l.CreatedOn,
    ISNULL(e.FullName, NULLIF(LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, ''))), '')) AS ModifiedByName
FROM dbo.PurchaseOrderItemLog l
LEFT JOIN Users u ON u.UserID = l.ModifiedById
LEFT JOIN Employee e ON e.EmpID = u.EmpID
WHERE l.PurchaseOrderId = @PurchaseOrderId
ORDER BY l.CreatedOn DESC;";

            var results = new List<PurchaseOrderItemLogEntry>();
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection);
                command.Parameters.AddWithValue("@PurchaseOrderId", id);
                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    results.Add(new PurchaseOrderItemLogEntry
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        PurchaseOrderId = reader.GetInt32(reader.GetOrdinal("PurchaseOrderId")),
                        ItemType = reader.IsDBNull(reader.GetOrdinal("ItemType")) ? null : reader.GetString(reader.GetOrdinal("ItemType")),
                        PreviousItemName = reader.IsDBNull(reader.GetOrdinal("PreviousItemName")) ? null : reader.GetString(reader.GetOrdinal("PreviousItemName")),
                        CurrentItemName = reader.IsDBNull(reader.GetOrdinal("CurrentItemName")) ? null : reader.GetString(reader.GetOrdinal("CurrentItemName")),
                        CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                        ModifiedByName = reader.IsDBNull(reader.GetOrdinal("ModifiedByName")) ? null : reader.GetString(reader.GetOrdinal("ModifiedByName"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving item log for purchase order {PurchaseOrderId}", id);
                throw;
            }

            return results;
        }

        public async Task<List<PurchaseOrderAttachment>> GetAttachmentsAsync(int id)
        {
            const string sql = @"
SELECT
    a.Id, a.PurchaseOrderId, a.Title, a.FileName, a.FileUrl, a.CreatedOn,
    ISNULL(e.FullName, NULLIF(LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, ''))), '')) AS UploadedByName
FROM dbo.PurchaseOrderAttachments a
LEFT JOIN Users u ON u.UserID = a.UploadedById
LEFT JOIN Employee e ON e.EmpID = u.EmpID
WHERE a.PurchaseOrderId = @PurchaseOrderId
ORDER BY a.CreatedOn DESC;";

            var results = new List<PurchaseOrderAttachment>();
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection);
                command.Parameters.AddWithValue("@PurchaseOrderId", id);
                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    results.Add(MapAttachment(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving attachments for purchase order {PurchaseOrderId}", id);
                throw;
            }

            return results;
        }

        public async Task<PurchaseOrderAttachment> AddAttachmentAsync(int id, string? title, string fileName, string fileUrl, int userId)
        {
            const string insertSql = @"
INSERT INTO dbo.PurchaseOrderAttachments (PurchaseOrderId, Title, FileName, FileUrl, UploadedById, CreatedOn)
VALUES (@PurchaseOrderId, @Title, @FileName, @FileUrl, @UploadedById, SYSUTCDATETIME());
SELECT CAST(SCOPE_IDENTITY() AS INT);";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(insertSql), connection);
                command.Parameters.AddWithValue("@PurchaseOrderId", id);
                command.Parameters.AddWithValue("@Title", (object?)title ?? DBNull.Value);
                command.Parameters.AddWithValue("@FileName", fileName);
                command.Parameters.AddWithValue("@FileUrl", fileUrl);
                command.Parameters.AddWithValue("@UploadedById", userId);

                await connection.OpenAsync();
                var newId = Convert.ToInt32(await command.ExecuteScalarAsync());

                return await GetAttachmentAsync(newId)
                    ?? throw new InvalidOperationException("Attachment was created but could not be retrieved.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error adding attachment to purchase order {PurchaseOrderId}", id);
                throw;
            }
        }

        public async Task<PurchaseOrderAttachment?> GetAttachmentAsync(int attachmentId)
        {
            const string sql = @"
SELECT
    a.Id, a.PurchaseOrderId, a.Title, a.FileName, a.FileUrl, a.CreatedOn,
    ISNULL(e.FullName, NULLIF(LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, ''))), '')) AS UploadedByName
FROM dbo.PurchaseOrderAttachments a
LEFT JOIN Users u ON u.UserID = a.UploadedById
LEFT JOIN Employee e ON e.EmpID = u.EmpID
WHERE a.Id = @Id;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection);
                command.Parameters.AddWithValue("@Id", attachmentId);
                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                return await reader.ReadAsync() ? MapAttachment(reader) : null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving attachment {AttachmentId}", attachmentId);
                throw;
            }
        }

        public async Task<bool> DeleteAttachmentAsync(int attachmentId)
        {
            const string sql = "DELETE FROM dbo.PurchaseOrderAttachments WHERE Id = @Id;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection);
                command.Parameters.AddWithValue("@Id", attachmentId);
                await connection.OpenAsync();
                var affected = await command.ExecuteNonQueryAsync();
                return affected > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting attachment {AttachmentId}", attachmentId);
                throw;
            }
        }

        private static PurchaseOrderAttachment MapAttachment(SqlDataReader reader)
        {
            return new PurchaseOrderAttachment
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                PurchaseOrderId = reader.GetInt32(reader.GetOrdinal("PurchaseOrderId")),
                Title = reader.IsDBNull(reader.GetOrdinal("Title")) ? null : reader.GetString(reader.GetOrdinal("Title")),
                FileName = reader.GetString(reader.GetOrdinal("FileName")),
                FileUrl = reader.GetString(reader.GetOrdinal("FileUrl")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                UploadedByName = reader.IsDBNull(reader.GetOrdinal("UploadedByName")) ? null : reader.GetString(reader.GetOrdinal("UploadedByName"))
            };
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
                VendorEmail = reader.IsDBNull(reader.GetOrdinal("VendorEmail")) ? null : reader.GetString(reader.GetOrdinal("VendorEmail")),
                VendorPhone = reader.IsDBNull(reader.GetOrdinal("VendorPhone")) ? null : reader.GetString(reader.GetOrdinal("VendorPhone")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                POValidityDate = reader.IsDBNull(reader.GetOrdinal("POValidityDate")) ? null : reader.GetDateTime(reader.GetOrdinal("POValidityDate")),
                Status = reader.GetString(reader.GetOrdinal("Status")),
                RejectionRemarks = reader.IsDBNull(reader.GetOrdinal("RejectionRemarks")) ? null : reader.GetString(reader.GetOrdinal("RejectionRemarks")),
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
                ItemId = reader.IsDBNull(reader.GetOrdinal("ItemId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemId")),
                MedicineId = reader.IsDBNull(reader.GetOrdinal("MedicineId")) ? null : reader.GetInt32(reader.GetOrdinal("MedicineId")),
                SubServiceId = reader.IsDBNull(reader.GetOrdinal("SubServiceId")) ? null : reader.GetInt32(reader.GetOrdinal("SubServiceId")),
                ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? "Unassigned Item" : reader.GetString(reader.GetOrdinal("ItemName")),
                ItemModel = reader.IsDBNull(reader.GetOrdinal("ItemModel")) ? null : reader.GetString(reader.GetOrdinal("ItemModel")),
                ItemType = reader.IsDBNull(reader.GetOrdinal("ItemType")) ? null : reader.GetString(reader.GetOrdinal("ItemType")),
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