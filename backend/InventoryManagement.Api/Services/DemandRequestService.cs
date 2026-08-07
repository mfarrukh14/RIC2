using System.Data;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    public class DemandRequestService : IDemandRequestService
    {
        private readonly string _connectionString;
        private readonly ILogger<DemandRequestService> _logger;
        private readonly string _schemaPrefix;
        // Inv.Stores is a small, disconnected legacy table (3 rows: Main Warehouse/OT
        // Store/ER Store) - completely different from Inv.PharmacyStores, the real store
        // list every dropdown in this app (including "Store Request To" here) is built
        // from. Joining against Inv.Stores meant any store outside that tiny legacy set
        // (i.e. almost every real store) made GetByIdAsync's INNER JOIN return nothing,
        // surfacing as "created but could not be retrieved" right after a successful insert.
        private readonly string _storesTable;
        // Pharmacy.PharmacyMedicinesStocks is the live, actively-maintained stock ledger
        // (the real HMS pharmacy operations update it) - NOT Inv.Stocks, which turned out
        // to be a one-time migrated snapshot this app's own features had been reading/
        // writing in isolation ever since, and had already diverged significantly (44% of
        // overlapping rows disagreed on quantity - see Stock_Procedures.sql header for the
        // full investigation). Unlike Inv.Stocks it has no BranchId/IsActive columns, and
        // its product-key columns are ItemId/BranchMedicineId/BranchSubServiceId (not
        // ItemId/MedicineId/SubServiceId) - see the SQL blocks below for how each is
        // adapted. dbo.Stocks (legacy schema) isn't wired up anywhere else in this file,
        // but the fallback keeps the dbo code path internally consistent.
        private readonly string _stocksTable;

        public DemandRequestService(IConfiguration configuration, ILogger<DemandRequestService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
            var builder = new SqlConnectionStringBuilder(_connectionString);
            _schemaPrefix = builder.InitialCatalog.StartsWith("HMS", StringComparison.OrdinalIgnoreCase) ? "Inv" : "dbo";
            _storesTable = _schemaPrefix == "Inv" ? "Inv.PharmacyStores" : "dbo.Stores";
            _stocksTable = _schemaPrefix == "Inv" ? "Pharmacy.PharmacyMedicinesStocks" : "dbo.Stocks";
        }

        private string NormalizeSql(string sql) => sql.Replace("dbo.", $"{_schemaPrefix}.");

        public async Task<PagedResult<DemandRequestSummary>> GetAllAsync(DemandRequestFilter filter)
        {
            var pageNumber = filter.PageNumber < 1 ? 1 : filter.PageNumber;
            var pageSize = filter.PageSize < 1 ? 5 : Math.Min(filter.PageSize, 100);
            var offset = (pageNumber - 1) * pageSize;

            // Filtering/joins shared by both the count and the page-of-ids query. Deliberately
            // does NOT touch DemandRequestItems/Items - those are only joined afterwards, and
            // only for the (at most pageSize) rows that make it onto the current page, so the
            // heavy per-item GROUP BY/STRING_AGG never runs over the full 58,000+ row table.
            string filteredIdsCte = $@"
    SELECT dr.Id, dr.CreatedOn
    FROM dbo.DemandRequests dr
    INNER JOIN dbo.Branches b ON b.Id = dr.BranchId
    LEFT JOIN {_storesTable} rs ON rs.StoreId = dr.RequestingStoreId
    LEFT JOIN {_storesTable} s ON s.StoreId = dr.RequestedToStoreId
    LEFT JOIN dbo.StockTypes st ON st.Id = dr.StockTypeId
    LEFT JOIN dbo.DemandRequestStatuses drs ON drs.Id = dr.DemandRequestStatusId
    WHERE dr.IsActive = 1
      AND (@BranchId IS NULL OR dr.BranchId = @BranchId)
      AND (@RequestingStoreId IS NULL OR dr.RequestingStoreId = @RequestingStoreId)
      AND (@RequestedStoreId IS NULL OR dr.RequestedToStoreId = @RequestedStoreId)
      AND (@StockTypeId IS NULL OR dr.StockTypeId = @StockTypeId)
      AND (@DateFrom IS NULL OR COALESCE(dr.ModifiedOn, dr.CreatedOn) >= @DateFrom)
      AND (@DateTo IS NULL OR dr.CreatedOn <= @DateTo)
      AND (@Statuses IS NULL OR drs.Name IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@Statuses, ',')))
      AND (
            @Search IS NULL
            OR dr.DemandRequestNumber LIKE '%' + @Search + '%'
            OR ISNULL(dr.IndentNumber, '') LIKE '%' + @Search + '%'
            OR b.Name LIKE '%' + @Search + '%'
            OR ISNULL(rs.StoreName, '') LIKE '%' + @Search + '%'
            OR s.StoreName LIKE '%' + @Search + '%'
            OR ISNULL(st.Name, '') LIKE '%' + @Search + '%'
            OR drs.Name LIKE '%' + @Search + '%'
          )";

            string countSql = NormalizeSql($"SELECT COUNT(*) FROM ({filteredIdsCte}) AS FilteredRequests;");

            string pageIdsSql = NormalizeSql($@"
SELECT Id FROM ({filteredIdsCte}) AS FilteredRequests
ORDER BY CreatedOn DESC, Id DESC
OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;");

            var result = new PagedResult<DemandRequestSummary>
            {
                PageNumber = pageNumber,
                PageSize = pageSize
            };

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                void AddFilterParameters(SqlCommand cmd)
                {
                    cmd.Parameters.AddWithValue("@BranchId", (object?)filter.BranchId ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@RequestingStoreId", (object?)filter.RequestingStoreId ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@RequestedStoreId", (object?)filter.RequestedStoreId ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@StockTypeId", (object?)filter.StockTypeId ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@DateFrom", (object?)filter.DateFrom ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@DateTo", (object?)filter.DateTo ?? DBNull.Value);
                    cmd.Parameters.AddWithValue("@Statuses", string.IsNullOrWhiteSpace(filter.Statuses) ? DBNull.Value : filter.Statuses.Trim());
                    cmd.Parameters.AddWithValue("@Search", string.IsNullOrWhiteSpace(filter.Search) ? DBNull.Value : filter.Search.Trim());
                }

                using (var countCommand = new SqlCommand(countSql, connection))
                {
                    AddFilterParameters(countCommand);
                    result.TotalCount = Convert.ToInt32(await countCommand.ExecuteScalarAsync());
                }

                var pageIds = new List<int>();
                using (var idsCommand = new SqlCommand(pageIdsSql, connection))
                {
                    AddFilterParameters(idsCommand);
                    idsCommand.Parameters.AddWithValue("@Offset", offset);
                    idsCommand.Parameters.AddWithValue("@PageSize", pageSize);

                    using var idsReader = await idsCommand.ExecuteReaderAsync();
                    while (await idsReader.ReadAsync())
                    {
                        pageIds.Add(idsReader.GetInt32(0));
                    }
                }

                if (pageIds.Count == 0)
                {
                    result.Items = Array.Empty<DemandRequestSummary>();
                    return result;
                }

                var idParamNames = pageIds.Select((_, index) => $"@Id{index}").ToList();
                string detailsSql = NormalizeSql($@"
SELECT
    dr.Id AS DemandRequestId,
    dr.DemandRequestNumber AS DRNo,
    dr.IndentNumber AS IndentNo,
    dr.CreatedOn AS DateFrom,
    COALESCE(dr.ModifiedOn, dr.CreatedOn) AS DateTo,
    dr.BranchId,
    b.Name AS RequestingBranchName,
    dr.RequestingStoreId,
    COALESCE(rs.StoreName, s.StoreName) AS RequestingStoreName,
    dr.RequestedToStoreId AS RequestedStoreId,
    s.StoreName AS RequestedStoreName,
    dr.StockTypeId,
    st.Name AS StockTypeName,
    COALESCE(drs.Name, 'Unknown') AS Status,
    dr.DemandNotes AS Remarks,
    dr.CreatedOn,
    ISNULL(e.FullName, NULLIF(LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, ''))), '')) AS RequestedByName,
    dr.ApprovedDate,
    dr.IssuedDate,
    dr.DriverName,
    dr.VehicleNumber,
    dr.ContactNumber,
    dr.Detail,
    COUNT(dri.Id) AS ItemsCount,
    COALESCE(SUM(dri.RequestedQuantity), 0) AS TotalRequestedQuantity,
    STRING_AGG(COALESCE(i.Name, 'Unassigned Item'), ', ') AS ItemSummary
FROM dbo.DemandRequests dr
INNER JOIN dbo.Branches b ON b.Id = dr.BranchId
LEFT JOIN {_storesTable} rs ON rs.StoreId = dr.RequestingStoreId
LEFT JOIN {_storesTable} s ON s.StoreId = dr.RequestedToStoreId
LEFT JOIN dbo.StockTypes st ON st.Id = dr.StockTypeId
LEFT JOIN dbo.DemandRequestStatuses drs ON drs.Id = dr.DemandRequestStatusId
LEFT JOIN Users u ON u.UserID = dr.CreatedById
LEFT JOIN Employee e ON e.EmpID = u.EmpID
LEFT JOIN dbo.DemandRequestItems dri
    ON dri.DemandRequestId = dr.Id
   AND dri.IsActive = 1
LEFT JOIN dbo.Items i ON i.Id = dri.ItemId
WHERE dr.Id IN ({string.Join(",", idParamNames)})
GROUP BY
    dr.Id,
    dr.DemandRequestNumber,
    dr.IndentNumber,
    dr.CreatedOn,
    dr.ModifiedOn,
    dr.BranchId,
    b.Name,
    dr.RequestingStoreId,
    rs.StoreName,
    dr.RequestedToStoreId,
    s.StoreName,
    dr.StockTypeId,
    st.Name,
    drs.Name,
    dr.DemandNotes,
    e.FullName,
    e.FirstName,
    e.LastName,
    dr.ApprovedDate,
    dr.IssuedDate,
    dr.DriverName,
    dr.VehicleNumber,
    dr.ContactNumber,
    dr.Detail
ORDER BY dr.CreatedOn DESC, dr.Id DESC;");

                var items = new List<DemandRequestSummary>();
                using (var detailsCommand = new SqlCommand(detailsSql, connection))
                {
                    for (int i = 0; i < pageIds.Count; i++)
                    {
                        detailsCommand.Parameters.AddWithValue(idParamNames[i], pageIds[i]);
                    }

                    using var reader = await detailsCommand.ExecuteReaderAsync();
                    while (await reader.ReadAsync())
                    {
                        items.Add(MapSummary(reader));
                    }
                }

                result.Items = items;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand requests");
                throw;
            }

            return result;
        }

        public async Task<DemandRequestDetails?> GetByIdAsync(int id)
        {
            string headerSql = $@"
SELECT
    dr.Id AS DemandRequestId,
    dr.DemandRequestNumber AS DRNo,
    dr.IndentNumber AS IndentNo,
    dr.CreatedOn AS DateFrom,
    COALESCE(dr.ModifiedOn, dr.CreatedOn) AS DateTo,
    dr.BranchId,
    b.Name AS RequestingBranchName,
    dr.RequestingStoreId,
    COALESCE(rs.StoreName, s.StoreName) AS RequestingStoreName,
    dr.RequestedToStoreId AS RequestedStoreId,
    s.StoreName AS RequestedStoreName,
    dr.StockTypeId,
    st.Name AS StockTypeName,
    COALESCE(drs.Name, 'Unknown') AS Status,
    dr.DemandNotes AS Remarks,
    dr.CreatedOn,
    ISNULL(e.FullName, NULLIF(LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, ''))), '')) AS RequestedByName,
    dr.ApprovedDate,
    dr.IssuedDate,
    dr.DriverName,
    dr.VehicleNumber,
    dr.ContactNumber,
    dr.Detail,
    (
        SELECT COUNT(*)
        FROM dbo.DemandRequestItems dri
        WHERE dri.DemandRequestId = dr.Id
          AND dri.IsActive = 1
    ) AS ItemsCount,
    (
        SELECT COALESCE(SUM(dri.RequestedQuantity), 0)
        FROM dbo.DemandRequestItems dri
        WHERE dri.DemandRequestId = dr.Id
          AND dri.IsActive = 1
        ) AS TotalRequestedQuantity,
        (
                SELECT STRING_AGG(COALESCE(i2.Name, 'Unassigned Item'), ', ')
                FROM dbo.DemandRequestItems dri2
                LEFT JOIN dbo.Items i2 ON i2.Id = dri2.ItemId
                WHERE dri2.DemandRequestId = dr.Id
                    AND dri2.IsActive = 1
        ) AS ItemSummary
FROM dbo.DemandRequests dr
INNER JOIN dbo.Branches b ON b.Id = dr.BranchId
LEFT JOIN {_storesTable} rs ON rs.StoreId = dr.RequestingStoreId
LEFT JOIN {_storesTable} s ON s.StoreId = dr.RequestedToStoreId
LEFT JOIN dbo.StockTypes st ON st.Id = dr.StockTypeId
LEFT JOIN dbo.DemandRequestStatuses drs ON drs.Id = dr.DemandRequestStatusId
LEFT JOIN Users u ON u.UserID = dr.CreatedById
LEFT JOIN Employee e ON e.EmpID = u.EmpID
WHERE dr.Id = @DemandRequestId
  AND dr.IsActive = 1;";

            string itemsSql = $@"
SELECT
    dri.Id,
    dri.DemandRequestId,
    dri.ItemId,
    COALESCE(i.Name, med.MedicineFullName, f.Name) AS ItemName,
    dri.RequestedQuantity,
    dri.ApprovedQuantity,
    dr.BranchId,
    b.Name AS BranchName,
    dri.MedicineId,
    dri.SubServiceId,
    dri.IsActive,
    CAST(NULL AS INT) AS CreatedById,
    dri.CreatedOn,
    CAST(NULL AS INT) AS ModifiedById,
    CAST(NULL AS DATETIME) AS ModifiedOn,
    dri.Notes AS Remarks,
    dr.StockTypeId,
    st.Name AS StockTypeName,
    dri.IssuedQuantity,
    CAST(0 AS INT) AS IssuingQuantity,
    -- Pending balance is against the APPROVED quantity, not the originally requested one -
    -- once a demand is approved for less than what was asked, what's still owed is measured
    -- against what was actually approved (matches old system's SP_DemandRequest_GetDemandRequest).
    CAST(CASE WHEN ISNULL(dri.ApprovedQuantity, dri.RequestedQuantity) - ISNULL(dri.IssuedQuantity, 0) > 0
              THEN ISNULL(dri.ApprovedQuantity, dri.RequestedQuantity) - ISNULL(dri.IssuedQuantity, 0) ELSE 0 END AS INT) AS RemainingQuantity,
    ISNULL(reqStock.TotalItemsInStock, 0) AS AvailableQuantityInRequestingStore,
    ISNULL(destStock.TotalItemsInStock, 0) AS AvailableQuantityInRequestedStore
FROM dbo.DemandRequestItems dri
LEFT JOIN dbo.Items i ON i.Id = dri.ItemId
LEFT JOIN Pharmacy.Medicines med ON med.MedicineId = dri.MedicineId
LEFT JOIN Account.Fees f ON f.Id = dri.SubServiceId
INNER JOIN dbo.DemandRequests dr ON dr.Id = dri.DemandRequestId
INNER JOIN dbo.Branches b ON b.Id = dr.BranchId
LEFT JOIN dbo.StockTypes st ON st.Id = dr.StockTypeId
LEFT JOIN {_stocksTable} reqStock ON reqStock.StoreId = dr.RequestingStoreId
    AND ((dri.ItemId IS NOT NULL AND reqStock.ItemId = dri.ItemId) OR (dri.MedicineId IS NOT NULL AND reqStock.BranchMedicineId = dri.MedicineId) OR (dri.SubServiceId IS NOT NULL AND reqStock.BranchSubServiceId = dri.SubServiceId))
LEFT JOIN {_stocksTable} destStock ON destStock.StoreId = dr.RequestedToStoreId
    AND ((dri.ItemId IS NOT NULL AND destStock.ItemId = dri.ItemId) OR (dri.MedicineId IS NOT NULL AND destStock.BranchMedicineId = dri.MedicineId) OR (dri.SubServiceId IS NOT NULL AND destStock.BranchSubServiceId = dri.SubServiceId))
WHERE dri.DemandRequestId = @DemandRequestId
  AND dri.IsActive = 1
ORDER BY dri.Id;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                DemandRequestDetails? details = null;

                using (var headerCommand = new SqlCommand(NormalizeSql(headerSql), connection))
                {
                    headerCommand.Parameters.AddWithValue("@DemandRequestId", id);
                    using var reader = await headerCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        var summary = MapSummary(reader);
                        details = new DemandRequestDetails
                        {
                            DemandRequestId = summary.DemandRequestId,
                            DRNo = summary.DRNo,
                            IndentNo = summary.IndentNo,
                            DateFrom = summary.DateFrom,
                            DateTo = summary.DateTo,
                            BranchId = summary.BranchId,
                            RequestingBranchName = summary.RequestingBranchName,
                            RequestingStoreId = summary.RequestingStoreId,
                            RequestingStoreName = summary.RequestingStoreName,
                            RequestedStoreId = summary.RequestedStoreId,
                            RequestedStoreName = summary.RequestedStoreName,
                            StockTypeId = summary.StockTypeId,
                            StockTypeName = summary.StockTypeName,
                            ItemsCount = summary.ItemsCount,
                            TotalRequestedQuantity = summary.TotalRequestedQuantity,
                            ItemSummary = summary.ItemSummary,
                            Status = summary.Status,
                            Remarks = summary.Remarks,
                            CreatedOn = summary.CreatedOn,
                            RequestedByName = summary.RequestedByName,
                            ApprovedDate = summary.ApprovedDate,
                            IssuedDate = summary.IssuedDate,
                            DriverName = summary.DriverName,
                            VehicleNumber = summary.VehicleNumber,
                            ContactNumber = summary.ContactNumber,
                            Detail = summary.Detail
                        };
                    }
                }

                if (details == null)
                {
                    return null;
                }

                using (var itemsCommand = new SqlCommand(NormalizeSql(itemsSql), connection))
                {
                    itemsCommand.Parameters.AddWithValue("@DemandRequestId", id);
                    using var itemsReader = await itemsCommand.ExecuteReaderAsync();
                    while (await itemsReader.ReadAsync())
                    {
                        details.Items.Add(MapItem(itemsReader));
                    }
                }

                return details;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand request with ID {DemandRequestId}", id);
                throw;
            }
        }

        public async Task<IReadOnlyList<DemandRequestLifeCycleEntry>> GetLifeCycleAsync(int id)
        {
            var results = new List<DemandRequestLifeCycleEntry>();

            string statusColumn = _schemaPrefix == "Inv" ? "Name" : "StatusName";
            string statusIdColumn = _schemaPrefix == "Inv" ? "Id" : "DemandRequestStatusId";
            string sql = NormalizeSql($@"
SELECT
    drlc.Id,
    drlc.DemandRequestId,
    drlc.DemandRequestStatusId,
    drs.{statusColumn} AS StatusName,
    drlc.ToUserId AS UserId,
    COALESCE(ISNULL(e.FullName, NULLIF(LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, ''))), '')), CONCAT('User #', drlc.ToUserId), 'System') AS ActionBy,
    drlc.CreatedOn
FROM dbo.DemandRequestLifeCycles drlc
INNER JOIN dbo.DemandRequestStatuses drs ON drs.{statusIdColumn} = drlc.DemandRequestStatusId
LEFT JOIN Users u ON u.UserID = drlc.ToUserId
LEFT JOIN Employee e ON e.EmpID = u.EmpID
WHERE drlc.DemandRequestId = @DemandRequestId
ORDER BY drlc.CreatedOn DESC, drlc.Id DESC;");

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(sql, connection)
                {
                    CommandType = CommandType.Text
                };

                command.Parameters.AddWithValue("@DemandRequestId", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    results.Add(new DemandRequestLifeCycleEntry
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        DemandRequestId = reader.GetInt32(reader.GetOrdinal("DemandRequestId")),
                        DemandRequestStatusId = reader.GetInt32(reader.GetOrdinal("DemandRequestStatusId")),
                        Status = reader.GetString(reader.GetOrdinal("StatusName")),
                        UserId = reader.IsDBNull(reader.GetOrdinal("UserId")) ? null : reader.GetInt32(reader.GetOrdinal("UserId")),
                        ActionBy = reader.GetString(reader.GetOrdinal("ActionBy")),
                        CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand request life cycle for ID {DemandRequestId}", id);
                throw;
            }

            return results;
        }

        // Logs a row into DemandRequestLifeCycles for the given status transition. FromUserId
        // is left null (this app's demand actions aren't threaded with a real actingUserId
        // param yet - CreatedById/ModifiedById are hardcoded to 1 elsewhere in this file for
        // the same reason). ToUserId is the user the demand's status is now attributed to.
        private static async Task InsertLifeCycleAsync(SqlConnection connection, SqlTransaction? transaction, int demandRequestId, string statusName, int toUserId, string schemaPrefix)
        {
            // Inv (live HMS) uses DemandRequestStatuses.Name; the dbo fallback schema (never
            // actually deployed anywhere - see CreateDemandRequestsTables.sql) uses StatusName.
            string schema = schemaPrefix == "Inv" ? "Inv" : "dbo";
            string statusColumn = schemaPrefix == "Inv" ? "Name" : "StatusName";
            string statusIdColumn = schemaPrefix == "Inv" ? "Id" : "DemandRequestStatusId";
            string sql = $@"
INSERT INTO {schema}.DemandRequestLifeCycles (DemandRequestId, DemandRequestStatusId, FromUserId, ToUserId, CreatedOn)
SELECT @DemandRequestId, drs.{statusIdColumn}, @ToUserId, @ToUserId, GETDATE()
FROM {schema}.DemandRequestStatuses drs
WHERE drs.{statusColumn} = @StatusName;";

            using var command = transaction == null
                ? new SqlCommand(sql, connection)
                : new SqlCommand(sql, connection, transaction);
            command.Parameters.AddWithValue("@DemandRequestId", demandRequestId);
            command.Parameters.AddWithValue("@ToUserId", toUserId);
            command.Parameters.AddWithValue("@StatusName", statusName);
            await command.ExecuteNonQueryAsync();
        }

        // Records one row per item touched by a dispatch or receive action, capturing the
        // delta quantity for that specific action plus the resulting cumulative
        // Issued/Received/Remaining quantities - mirrors the legacy system's
        // DemandRequestItemLogs, since DemandRequestItems itself only ever holds the
        // current running totals and would otherwise lose the per-visit history once a
        // second partial dispatch/receive overwrites them.
        private static async Task InsertItemLogAsync(SqlConnection connection, SqlTransaction transaction, int demandRequestId, int demandRequestItemId, int? itemId, string actionType, int quantity, int? issuedQuantity, int? receivedQuantity, int? remainingQuantity, string schemaPrefix)
        {
            string schema = schemaPrefix == "Inv" ? "Inv" : "dbo";
            string sql = $@"
INSERT INTO {schema}.DemandRequestItemLogs
    (DemandRequestId, DemandRequestItemId, ItemId, ActionType, Quantity, IssuedQuantity, ReceivedQuantity, RemainingQuantity, CreatedById, CreatedOn)
VALUES
    (@DemandRequestId, @DemandRequestItemId, @ItemId, @ActionType, @Quantity, @IssuedQuantity, @ReceivedQuantity, @RemainingQuantity, @CreatedById, GETDATE());";

            using var command = new SqlCommand(sql, connection, transaction);
            command.Parameters.AddWithValue("@DemandRequestId", demandRequestId);
            command.Parameters.AddWithValue("@DemandRequestItemId", demandRequestItemId);
            command.Parameters.AddWithValue("@ItemId", (object?)itemId ?? DBNull.Value);
            command.Parameters.AddWithValue("@ActionType", actionType);
            command.Parameters.AddWithValue("@Quantity", quantity);
            command.Parameters.AddWithValue("@IssuedQuantity", (object?)issuedQuantity ?? DBNull.Value);
            command.Parameters.AddWithValue("@ReceivedQuantity", (object?)receivedQuantity ?? DBNull.Value);
            command.Parameters.AddWithValue("@RemainingQuantity", (object?)remainingQuantity ?? DBNull.Value);
            command.Parameters.AddWithValue("@CreatedById", 1);
            await command.ExecuteNonQueryAsync();
        }

        public async Task<IReadOnlyList<DemandRequestItemLogEntry>> GetItemLogsAsync(int id)
        {
            var results = new List<DemandRequestItemLogEntry>();

            string sql = NormalizeSql(@"
SELECT
    l.Id,
    l.DemandRequestId,
    l.DemandRequestItemId,
    l.ItemId,
    i.Name AS ItemName,
    l.ActionType,
    l.Quantity,
    l.IssuedQuantity,
    l.ReceivedQuantity,
    l.RemainingQuantity,
    ISNULL(e.FullName, NULLIF(LTRIM(RTRIM(ISNULL(e.FirstName, '') + ' ' + ISNULL(e.LastName, ''))), '')) AS ActionBy,
    l.CreatedOn
FROM dbo.DemandRequestItemLogs l
LEFT JOIN dbo.Items i ON i.Id = l.ItemId
LEFT JOIN Users u ON u.UserID = l.CreatedById
LEFT JOIN Employee e ON e.EmpID = u.EmpID
WHERE l.DemandRequestId = @DemandRequestId
ORDER BY l.CreatedOn DESC, l.Id DESC;");

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(sql, connection) { CommandType = CommandType.Text };
                command.Parameters.AddWithValue("@DemandRequestId", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    results.Add(new DemandRequestItemLogEntry
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        DemandRequestId = reader.GetInt32(reader.GetOrdinal("DemandRequestId")),
                        DemandRequestItemId = reader.GetInt32(reader.GetOrdinal("DemandRequestItemId")),
                        ItemId = reader.IsDBNull(reader.GetOrdinal("ItemId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemId")),
                        ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? null : reader.GetString(reader.GetOrdinal("ItemName")),
                        ActionType = reader.GetString(reader.GetOrdinal("ActionType")),
                        Quantity = reader.GetInt32(reader.GetOrdinal("Quantity")),
                        IssuedQuantity = reader.IsDBNull(reader.GetOrdinal("IssuedQuantity")) ? null : reader.GetInt32(reader.GetOrdinal("IssuedQuantity")),
                        ReceivedQuantity = reader.IsDBNull(reader.GetOrdinal("ReceivedQuantity")) ? null : reader.GetInt32(reader.GetOrdinal("ReceivedQuantity")),
                        RemainingQuantity = reader.IsDBNull(reader.GetOrdinal("RemainingQuantity")) ? null : reader.GetInt32(reader.GetOrdinal("RemainingQuantity")),
                        ActionBy = reader.IsDBNull(reader.GetOrdinal("ActionBy")) ? null : reader.GetString(reader.GetOrdinal("ActionBy")),
                        CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand request item logs for ID {DemandRequestId}", id);
                throw;
            }

            return results;
        }

        public async Task<DemandRequestDetails?> ReceiveAsync(int id, DemandRequestReceiveRequest request)
        {
            string headerLookupSql = NormalizeSql(@"
SELECT dr.RequestingStoreId, dr.BranchId, drs.Name
FROM dbo.DemandRequests dr
LEFT JOIN dbo.DemandRequestStatuses drs ON drs.Id = dr.DemandRequestStatusId
WHERE dr.Id = @DemandRequestId AND dr.IsActive = 1;");

            // Only the delta since the last receive is credited - IssuedQuantity accumulates
            // across dispatch trips, so re-receiving after a later partial dispatch must not
            // re-credit stock that already landed here on a prior receive.
            string itemsLookupSql = NormalizeSql(@"
SELECT Id, ItemId, MedicineId, SubServiceId, ISNULL(IssuedQuantity, 0) - ISNULL(ReceivedQuantity, 0) AS DeltaQuantity,
    ISNULL(IssuedQuantity, 0) AS IssuedQuantity,
    ISNULL(ApprovedQuantity, RequestedQuantity) - ISNULL(IssuedQuantity, 0) AS RemainingQuantity
FROM dbo.DemandRequestItems
WHERE DemandRequestId = @DemandRequestId AND IsActive = 1
    AND (ItemId IS NOT NULL OR MedicineId IS NOT NULL OR SubServiceId IS NOT NULL);");

            string updateItemsSql = NormalizeSql(@"
UPDATE dbo.DemandRequestItems
SET
    ReceivedQuantity = ISNULL(IssuedQuantity, 0)
WHERE DemandRequestId = @DemandRequestId
  AND IsActive = 1;");

            string remainingCountSql = NormalizeSql(@"
SELECT COUNT(*)
FROM dbo.DemandRequestItems
WHERE DemandRequestId = @DemandRequestId
  AND IsActive = 1
  AND ISNULL(IssuedQuantity, 0) < ISNULL(ApprovedQuantity, RequestedQuantity);");

            string updateHeaderSql = NormalizeSql(@"
UPDATE dbo.DemandRequests
SET
    DemandRequestStatusId = (SELECT TOP 1 Id FROM dbo.DemandRequestStatuses WHERE Name = @StatusName),
    IndentNumber = COALESCE(NULLIF(@IndentNo, ''), IndentNumber),
    ReceivedDate = SYSUTCDATETIME(),
    DriverName = COALESCE(@DriverName, DriverName),
    VehicleNumber = COALESCE(@VehicleNumber, VehicleNumber),
    ContactNumber = COALESCE(@ContactNumber, ContactNumber),
    Detail = COALESCE(@Detail, Detail),
    ModifiedById = 1,
    ModifiedOn = SYSUTCDATETIME()
WHERE Id = @DemandRequestId
  AND IsActive = 1;");

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = await connection.BeginTransactionAsync();

                // Read first, act after the block closes - SqlConnection refuses a second
                // operation (like RollbackAsync) while a SqlDataReader from it is still open.
                int? requestingStoreId = null;
                int? branchId = null;
                string? currentStatus = null;
                using (var headerLookupCommand = new SqlCommand(headerLookupSql, connection, (SqlTransaction)transaction))
                {
                    headerLookupCommand.Parameters.AddWithValue("@DemandRequestId", id);
                    using var reader = await headerLookupCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        requestingStoreId = reader.IsDBNull(0) ? null : reader.GetInt32(0);
                        branchId = reader.GetInt32(1);
                        currentStatus = reader.IsDBNull(2) ? null : reader.GetString(2);
                    }
                }

                if (branchId == null)
                {
                    await transaction.RollbackAsync();
                    return null;
                }

                if (!string.Equals(currentStatus, "Issued", StringComparison.OrdinalIgnoreCase)
                    && !string.Equals(currentStatus, "Partial Issued", StringComparison.OrdinalIgnoreCase))
                {
                    await transaction.RollbackAsync();
                    throw new InvalidOperationException($"Cannot receive this demand - it has not been dispatched yet (current status: {currentStatus ?? "Unknown"}).");
                }

                // This is where the stock actually lands in the requesting store's balance -
                // dispatch only ever deducted it from the requested (source) store.
                if (requestingStoreId.HasValue)
                {
                    var itemsToReceive = new List<(int DemandRequestItemId, ProductKey Product, int Quantity, int IssuedQuantity, int RemainingQuantity)>();
                    using (var itemsLookupCommand = new SqlCommand(itemsLookupSql, connection, (SqlTransaction)transaction))
                    {
                        itemsLookupCommand.Parameters.AddWithValue("@DemandRequestId", id);
                        using var reader = await itemsLookupCommand.ExecuteReaderAsync();
                        while (await reader.ReadAsync())
                        {
                            var product = new ProductKey(
                                reader.IsDBNull(1) ? null : reader.GetInt32(1),
                                reader.IsDBNull(2) ? null : reader.GetInt32(2),
                                reader.IsDBNull(3) ? null : reader.GetInt32(3));
                            itemsToReceive.Add((reader.GetInt32(0), product, reader.GetInt32(4), reader.GetInt32(5), reader.GetInt32(6)));
                        }
                    }

                    foreach (var item in itemsToReceive)
                    {
                        if (item.Quantity <= 0)
                        {
                            continue;
                        }

                        await AddStockAsync(connection, (SqlTransaction)transaction, item.Product, requestingStoreId.Value, branchId.Value, item.Quantity);
                        await InsertItemLogAsync(connection, (SqlTransaction)transaction, id, item.DemandRequestItemId, item.Product.ItemId,
                            "Receive", item.Quantity, item.IssuedQuantity, item.IssuedQuantity, item.RemainingQuantity, _schemaPrefix);
                    }
                }

                using (var itemsCommand = new SqlCommand(updateItemsSql, connection, (SqlTransaction)transaction))
                {
                    itemsCommand.Parameters.AddWithValue("@DemandRequestId", id);
                    await itemsCommand.ExecuteNonQueryAsync();
                }

                int remainingItemCount;
                using (var remainingCommand = new SqlCommand(remainingCountSql, connection, (SqlTransaction)transaction))
                {
                    remainingCommand.Parameters.AddWithValue("@DemandRequestId", id);
                    remainingItemCount = Convert.ToInt32(await remainingCommand.ExecuteScalarAsync());
                }

                // Only fully closes out once nothing remains to dispatch - if some approved
                // quantity hasn't been issued yet, the demand stays Partial Issued so it can
                // still be dispatched (and received again) further.
                string resultingStatus = remainingItemCount == 0 ? "Received" : "Partial Issued";

                using (var headerCommand = new SqlCommand(updateHeaderSql, connection, (SqlTransaction)transaction))
                {
                    headerCommand.Parameters.AddWithValue("@DemandRequestId", id);
                    headerCommand.Parameters.AddWithValue("@StatusName", resultingStatus);
                    headerCommand.Parameters.AddWithValue("@IndentNo", (object?)request.IndentNo ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@DriverName", (object?)request.DriverName ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@VehicleNumber", (object?)request.VehicleNumber ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@ContactNumber", (object?)request.ContactNumber ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@Detail", (object?)request.Detail ?? DBNull.Value);
                    var rowsAffected = await headerCommand.ExecuteNonQueryAsync();

                    if (rowsAffected == 0)
                    {
                        await transaction.RollbackAsync();
                        return null;
                    }
                }

                if (resultingStatus == "Received")
                {
                    await InsertLifeCycleAsync(connection, (SqlTransaction)transaction, id, "Received", toUserId: 1, _schemaPrefix);
                }

                await transaction.CommitAsync();
                return await GetByIdAsync(id);
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error receiving demand request with ID {DemandRequestId}", id);
                throw;
            }
        }

        public async Task<DemandRequestDetails?> UpdateAsync(int id, DemandRequestUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = await connection.BeginTransactionAsync();

                var rowsAffected = await UpdateHeaderAsync(connection, (SqlTransaction)transaction, id, request);
                if (rowsAffected == 0)
                {
                    await transaction.RollbackAsync();
                    return null;
                }

                await SaveItemsAsync(connection, (SqlTransaction)transaction, id, request.Items);

                await transaction.CommitAsync();
                return await GetByIdAsync(id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating demand request with ID {DemandRequestId}", id);
                throw;
            }
        }

        // Approving a demand only records the approved quantities and moves the status to
        // "Approved" - it does NOT touch stock and does NOT issue anything yet. This mirrors
        // the old system's SP_DemandRequest_IssueStockApprovedDemand, which requires a demand
        // to already be sitting in "Approved" status before stock can be issued against it as
        // a distinct, later action (DispatchAsync below). Previously this method jumped
        // straight to "Issued" and deducted stock in the same step, which meant a demand
        // skipped the Approved stage entirely and appeared in Receive Stock before anyone had
        // actually dispatched it.
        public async Task<DemandRequestDetails?> ApproveAsync(int id, DemandRequestUpdateRequest request)
        {
            string approveHeaderSql = NormalizeSql(@"
UPDATE dbo.DemandRequests
SET
    DemandRequestStatusId = (SELECT TOP 1 Id FROM dbo.DemandRequestStatuses WHERE Name = 'Approved'),
    IndentNumber = COALESCE(NULLIF(@IndentNo, ''), IndentNumber),
    DemandNotes = COALESCE(@DemandNotes, DemandNotes),
    ApprovedDate = SYSUTCDATETIME(),
    ModifiedById = 1,
    ModifiedOn = SYSUTCDATETIME()
WHERE Id = @DemandRequestId
  AND IsActive = 1;");

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = await connection.BeginTransactionAsync();

                await SaveItemsAsync(connection, (SqlTransaction)transaction, id, request.Items);

                using var headerCommand = new SqlCommand(approveHeaderSql, connection, (SqlTransaction)transaction);
                headerCommand.Parameters.AddWithValue("@DemandRequestId", id);
                headerCommand.Parameters.AddWithValue("@IndentNo", (object?)request.IndentNo ?? DBNull.Value);
                headerCommand.Parameters.AddWithValue("@DemandNotes", (object?)request.DemandNotes ?? DBNull.Value);
                var rowsAffected = await headerCommand.ExecuteNonQueryAsync();

                if (rowsAffected == 0)
                {
                    await transaction.RollbackAsync();
                    return null;
                }

                await InsertLifeCycleAsync(connection, (SqlTransaction)transaction, id, "Approved", toUserId: 1, _schemaPrefix);

                await transaction.CommitAsync();
                return await GetByIdAsync(id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error approving demand request with ID {DemandRequestId}", id);
                throw;
            }
        }

        // Issues stock for a demand that's already Approved (or already Partial Issued, so a
        // remaining balance can be dispatched in a later trip) - the real, separate "dispatch"
        // step (matches the old system's SP_DemandRequest_IssueStockApprovedDemand, which
        // refuses to run unless the demand is in one of those statuses). Deducts each issued
        // item's quantity from the Requested (source) Store right now; it does NOT land in
        // the Requesting Store's balance yet - that only happens once someone on the
        // receiving end confirms receipt (ReceiveAsync), so stock sits "in transit" between
        // dispatch and receive, same as a real goods-in-transit workflow. Supports partial
        // dispatch: IssuedQuantity accumulates across calls, and the header only moves to
        // "Issued" once every item's IssuedQuantity has caught up to its ApprovedQuantity -
        // otherwise it lands on "Partial Issued" so the remainder can be dispatched later.
        public async Task<DemandRequestDetails?> DispatchAsync(int id, DemandRequestDispatchRequest request)
        {
            string headerLookupSql = NormalizeSql(@"
SELECT dr.RequestedToStoreId, drs.Name
FROM dbo.DemandRequests dr
LEFT JOIN dbo.DemandRequestStatuses drs ON drs.Id = dr.DemandRequestStatusId
WHERE dr.Id = @DemandRequestId AND dr.IsActive = 1;");

            string itemsLookupSql = NormalizeSql(@"
SELECT dri.Id, dri.ItemId, dri.MedicineId, dri.SubServiceId, COALESCE(i.Name, med.MedicineFullName, f.Name),
    ISNULL(dri.ApprovedQuantity, dri.RequestedQuantity) - ISNULL(dri.IssuedQuantity, 0) AS Remaining,
    ISNULL(dri.ApprovedQuantity, dri.RequestedQuantity) AS Approved
FROM dbo.DemandRequestItems dri
LEFT JOIN dbo.Items i ON i.Id = dri.ItemId
LEFT JOIN Pharmacy.Medicines med ON med.MedicineId = dri.MedicineId
LEFT JOIN Account.Fees f ON f.Id = dri.SubServiceId
WHERE dri.DemandRequestId = @DemandRequestId AND dri.IsActive = 1;");

            string updateItemIssuedSql = NormalizeSql("UPDATE dbo.DemandRequestItems SET IssuedQuantity = ISNULL(IssuedQuantity, 0) + @Qty WHERE Id = @Id;");

            string remainingCountSql = NormalizeSql(@"
SELECT COUNT(*)
FROM dbo.DemandRequestItems
WHERE DemandRequestId = @DemandRequestId
  AND IsActive = 1
  AND ISNULL(IssuedQuantity, 0) < ISNULL(ApprovedQuantity, RequestedQuantity);");

            string dispatchHeaderSql = NormalizeSql(@"
UPDATE dbo.DemandRequests
SET
    DemandRequestStatusId = (SELECT TOP 1 Id FROM dbo.DemandRequestStatuses WHERE Name = @StatusName),
    IssuedDate = SYSUTCDATETIME(),
    DriverName = COALESCE(@DriverName, DriverName),
    VehicleNumber = COALESCE(@VehicleNumber, VehicleNumber),
    ContactNumber = COALESCE(@ContactNumber, ContactNumber),
    Detail = COALESCE(@Detail, Detail),
    ModifiedById = 1,
    ModifiedOn = SYSUTCDATETIME()
WHERE Id = @DemandRequestId
  AND IsActive = 1
  AND DemandRequestStatusId IN (
        SELECT Id FROM dbo.DemandRequestStatuses WHERE Name IN ('Approved', 'Partial Issued')
      );");

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = await connection.BeginTransactionAsync();

                // Read everything needed first and let the reader/command close before doing
                // anything else on the connection (rollback included) - SqlConnection refuses
                // a second operation (like RollbackAsync) while a SqlDataReader from it is
                // still open, throwing "There is already an open DataReader..." instead of
                // whatever error should actually surface.
                int? requestedToStoreId = null;
                string? currentStatus = null;
                using (var headerLookupCommand = new SqlCommand(headerLookupSql, connection, (SqlTransaction)transaction))
                {
                    headerLookupCommand.Parameters.AddWithValue("@DemandRequestId", id);
                    using var reader = await headerLookupCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        requestedToStoreId = reader.GetInt32(0);
                        currentStatus = reader.IsDBNull(1) ? null : reader.GetString(1);
                    }
                }

                if (requestedToStoreId == null)
                {
                    await transaction.RollbackAsync();
                    return null;
                }

                if (!string.Equals(currentStatus, "Approved", StringComparison.OrdinalIgnoreCase)
                    && !string.Equals(currentStatus, "Partial Issued", StringComparison.OrdinalIgnoreCase))
                {
                    await transaction.RollbackAsync();
                    throw new InvalidOperationException($"Cannot dispatch this demand - it must be Approved first (current status: {currentStatus ?? "Unknown"}).");
                }

                var remainingByItemId = new Dictionary<int, (ProductKey Product, string ItemName, int Remaining, int Approved)>();
                using (var itemsLookupCommand = new SqlCommand(itemsLookupSql, connection, (SqlTransaction)transaction))
                {
                    itemsLookupCommand.Parameters.AddWithValue("@DemandRequestId", id);
                    using var reader = await itemsLookupCommand.ExecuteReaderAsync();
                    while (await reader.ReadAsync())
                    {
                        var product = new ProductKey(
                            reader.IsDBNull(1) ? null : reader.GetInt32(1),
                            reader.IsDBNull(2) ? null : reader.GetInt32(2),
                            reader.IsDBNull(3) ? null : reader.GetInt32(3));
                        remainingByItemId[reader.GetInt32(0)] = (
                            product,
                            reader.IsDBNull(4) ? "Unassigned Item" : reader.GetString(4),
                            reader.IsDBNull(5) ? 0 : reader.GetInt32(5),
                            reader.IsDBNull(6) ? 0 : reader.GetInt32(6));
                    }
                }

                var toDispatch = (request.Items ?? new List<DemandRequestDispatchItem>())
                    .Where(i => i.IssuingQuantity > 0)
                    .ToList();

                if (toDispatch.Count == 0)
                {
                    await transaction.RollbackAsync();
                    throw new InvalidOperationException("Nothing to dispatch - enter an issuing quantity for at least one item.");
                }

                foreach (var dispatchItem in toDispatch)
                {
                    if (!remainingByItemId.TryGetValue(dispatchItem.Id, out var itemInfo)
                        || (itemInfo.Product.ItemId == null && itemInfo.Product.MedicineId == null && itemInfo.Product.SubServiceId == null))
                    {
                        continue;
                    }

                    if (dispatchItem.IssuingQuantity > itemInfo.Remaining)
                    {
                        await transaction.RollbackAsync();
                        throw new InvalidOperationException($"Cannot dispatch {dispatchItem.IssuingQuantity} unit(s) of '{itemInfo.ItemName}' - only {itemInfo.Remaining} remain to be issued.");
                    }

                    await RemoveStockAsync(connection, (SqlTransaction)transaction, itemInfo.Product, itemInfo.ItemName, requestedToStoreId.Value, dispatchItem.IssuingQuantity);

                    using var updateItemCommand = new SqlCommand(updateItemIssuedSql, connection, (SqlTransaction)transaction);
                    updateItemCommand.Parameters.AddWithValue("@Id", dispatchItem.Id);
                    updateItemCommand.Parameters.AddWithValue("@Qty", dispatchItem.IssuingQuantity);
                    await updateItemCommand.ExecuteNonQueryAsync();

                    int newRemaining = itemInfo.Remaining - dispatchItem.IssuingQuantity;
                    int newIssued = itemInfo.Approved - newRemaining;
                    await InsertItemLogAsync(connection, (SqlTransaction)transaction, id, dispatchItem.Id, itemInfo.Product.ItemId,
                        "Dispatch", dispatchItem.IssuingQuantity, newIssued, null, newRemaining, _schemaPrefix);
                }

                int remainingItemCount;
                using (var remainingCommand = new SqlCommand(remainingCountSql, connection, (SqlTransaction)transaction))
                {
                    remainingCommand.Parameters.AddWithValue("@DemandRequestId", id);
                    remainingItemCount = Convert.ToInt32(await remainingCommand.ExecuteScalarAsync());
                }

                string resultingStatus = remainingItemCount == 0 ? "Issued" : "Partial Issued";

                using (var headerCommand = new SqlCommand(dispatchHeaderSql, connection, (SqlTransaction)transaction))
                {
                    headerCommand.Parameters.AddWithValue("@DemandRequestId", id);
                    headerCommand.Parameters.AddWithValue("@StatusName", resultingStatus);
                    headerCommand.Parameters.AddWithValue("@DriverName", (object?)request.DriverName ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@VehicleNumber", (object?)request.VehicleNumber ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@ContactNumber", (object?)request.ContactNumber ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@Detail", (object?)request.Detail ?? DBNull.Value);
                    var rowsAffected = await headerCommand.ExecuteNonQueryAsync();
                    if (rowsAffected == 0)
                    {
                        await transaction.RollbackAsync();
                        return null;
                    }
                }

                await InsertLifeCycleAsync(connection, (SqlTransaction)transaction, id, resultingStatus, toUserId: 1, _schemaPrefix);

                await transaction.CommitAsync();
                return await GetByIdAsync(id);
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error dispatching demand request with ID {DemandRequestId}", id);
                throw;
            }
        }

        public async Task<DemandRequestDetails?> RejectAsync(int id, DemandRequestRejectRequest request)
        {
            string rejectHeaderSql = NormalizeSql(@"
UPDATE dbo.DemandRequests
SET
    DemandRequestStatusId = (SELECT TOP 1 Id FROM dbo.DemandRequestStatuses WHERE Name = 'Rejected'),
    DemandNotes = COALESCE(@Remarks, DemandNotes),
    RejectedDate = SYSUTCDATETIME(),
    ModifiedById = 1,
    ModifiedOn = SYSUTCDATETIME()
WHERE Id = @DemandRequestId
  AND IsActive = 1;");

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(rejectHeaderSql, connection);
                command.Parameters.AddWithValue("@DemandRequestId", id);
                command.Parameters.AddWithValue("@Remarks", (object?)request.Remarks ?? DBNull.Value);

                await connection.OpenAsync();
                var rowsAffected = await command.ExecuteNonQueryAsync();

                if (rowsAffected == 0)
                {
                    return null;
                }

                await InsertLifeCycleAsync(connection, null, id, "Rejected", toUserId: 1, _schemaPrefix);

                return await GetByIdAsync(id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error rejecting demand request with ID {DemandRequestId}", id);
                throw;
            }
        }

        private async Task<int> UpdateHeaderAsync(SqlConnection connection, SqlTransaction transaction, int id, DemandRequestUpdateRequest request)
        {
            string updateHeaderSql = NormalizeSql(@"
UPDATE dbo.DemandRequests
SET
    IndentNumber = COALESCE(NULLIF(@IndentNo, ''), IndentNumber),
    DemandNotes = COALESCE(@DemandNotes, DemandNotes),
    ModifiedById = 1,
    ModifiedOn = SYSUTCDATETIME()
WHERE Id = @DemandRequestId
  AND IsActive = 1;");

            using var command = new SqlCommand(updateHeaderSql, connection, transaction);
            command.Parameters.AddWithValue("@DemandRequestId", id);
            command.Parameters.AddWithValue("@IndentNo", (object?)request.IndentNo ?? DBNull.Value);
            command.Parameters.AddWithValue("@DemandNotes", (object?)request.DemandNotes ?? DBNull.Value);
            return await command.ExecuteNonQueryAsync();
        }


        // Deducts stock from a store at issue time, guarding against issuing more than is
        // actually on hand there (mirrors TransferInventory_Insert's same check for regular
        // inter-store transfers). Throwing InvalidOperationException here rolls back the
        // whole approval transaction and surfaces a friendly message via the controller.
        private async Task RemoveStockAsync(SqlConnection connection, SqlTransaction transaction, ProductKey product, string itemName, int storeId, int quantity)
        {
            string selectSql = $"SELECT ISNULL(TotalItemsInStock, 0) FROM {_stocksTable} WHERE StoreId = @StoreId AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId));";
            int available;
            using (var selectCommand = new SqlCommand(selectSql, connection, transaction))
            {
                product.AddParameters(selectCommand);
                selectCommand.Parameters.AddWithValue("@StoreId", storeId);
                var result = await selectCommand.ExecuteScalarAsync();
                available = result == null || result == DBNull.Value ? 0 : Convert.ToInt32(result);
            }

            if (available < quantity)
            {
                throw new InvalidOperationException($"Cannot issue {quantity} unit(s) of '{itemName}' - only {available} available in the requested store.");
            }

            string updateSql = $@"
UPDATE {_stocksTable}
SET TotalItemsInStock = TotalItemsInStock - @Quantity, ModifiedOn = GETDATE()
WHERE StoreId = @StoreId AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId));";

            using var updateCommand = new SqlCommand(updateSql, connection, transaction);
            product.AddParameters(updateCommand);
            updateCommand.Parameters.AddWithValue("@StoreId", storeId);
            updateCommand.Parameters.AddWithValue("@Quantity", quantity);
            await updateCommand.ExecuteNonQueryAsync();
        }

        // Credits stock into a store at receive time - upserts since the destination store
        // may never have held this item before (same pattern TransferInventory_Insert uses
        // for a brand-new destination row). No BranchId column on
        // Pharmacy.PharmacyMedicinesStocks - branch is only reachable via the store, so
        // @BranchId is accepted for call-site compatibility but not written anywhere.
        private async Task AddStockAsync(SqlConnection connection, SqlTransaction transaction, ProductKey product, int storeId, int branchId, int quantity)
        {
            string upsertSql = $@"
IF EXISTS (SELECT 1 FROM {_stocksTable} WHERE StoreId = @StoreId AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId)))
    UPDATE {_stocksTable}
    SET TotalItemsInStock = ISNULL(TotalItemsInStock, 0) + @Quantity, ModifiedOn = GETDATE()
    WHERE StoreId = @StoreId AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId));
ELSE
    INSERT INTO {_stocksTable} (ItemId, BranchMedicineId, BranchSubServiceId, TotalItemsInStock, MinimumPanicLevel, TotalItemsInTransition, TypeBit, StoreId, CreatedBy, CreatedOn)
    VALUES (@ItemId, @MedicineId, @SubServiceId, @Quantity, 0, 0,
        CASE WHEN @ItemId IS NOT NULL THEN 15 WHEN @MedicineId IS NOT NULL THEN 4 WHEN @SubServiceId IS NOT NULL THEN 5 ELSE NULL END,
        @StoreId, 1, GETDATE());";

            using var command = new SqlCommand(upsertSql, connection, transaction);
            product.AddParameters(command);
            command.Parameters.AddWithValue("@StoreId", storeId);
            command.Parameters.AddWithValue("@BranchId", branchId);
            command.Parameters.AddWithValue("@Quantity", quantity);
            await command.ExecuteNonQueryAsync();
        }

        // Existing item rows (Id > 0) get their approved quantity/remarks updated in place.
        // Rows with no Id are new lines added via the "Item" picker in the Update Demand
        // modal, so they're inserted fresh against this demand request. IssuedQuantity is
        // NOT touched here - it's only ever set by DispatchAsync, once a separate dispatch
        // action actually issues the approved stock.
        private async Task SaveItemsAsync(SqlConnection connection, SqlTransaction transaction, int demandRequestId, List<DemandRequestUpdateItem> items)
        {
            if (items == null || items.Count == 0)
            {
                return;
            }

            string updateItemSql = NormalizeSql(@"UPDATE dbo.DemandRequestItems
SET ApprovedQuantity = @ApprovedQuantity, Notes = @Remarks
WHERE Id = @Id AND DemandRequestId = @DemandRequestId AND IsActive = 1;");

            string insertItemSql = NormalizeSql(@"INSERT INTO dbo.DemandRequestItems (DemandRequestId, ItemId, MedicineId, SubServiceId, RequestedQuantity, ApprovedQuantity, Notes, IsActive, CreatedOn)
VALUES (@DemandRequestId, @ItemId, @MedicineId, @SubServiceId, @RequestedQuantity, @ApprovedQuantity, @Remarks, 1, SYSUTCDATETIME());");

            foreach (var item in items)
            {
                if (item.Id.HasValue && item.Id.Value > 0)
                {
                    using var command = new SqlCommand(updateItemSql, connection, transaction);
                    command.Parameters.AddWithValue("@Id", item.Id.Value);
                    command.Parameters.AddWithValue("@DemandRequestId", demandRequestId);
                    command.Parameters.AddWithValue("@ApprovedQuantity", item.ApprovedQuantity);
                    command.Parameters.AddWithValue("@Remarks", (object?)item.Remarks ?? DBNull.Value);
                    await command.ExecuteNonQueryAsync();
                }
                else
                {
                    if ((item.ItemId == null && item.MedicineId == null && item.SubServiceId == null) || item.RequestedQuantity <= 0)
                    {
                        continue;
                    }

                    using var command = new SqlCommand(insertItemSql, connection, transaction);
                    command.Parameters.AddWithValue("@DemandRequestId", demandRequestId);
                    command.Parameters.AddWithValue("@ItemId", (object?)item.ItemId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@MedicineId", (object?)item.MedicineId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@SubServiceId", (object?)item.SubServiceId ?? DBNull.Value);
                    command.Parameters.AddWithValue("@RequestedQuantity", item.RequestedQuantity);
                    command.Parameters.AddWithValue("@ApprovedQuantity", item.ApprovedQuantity);
                    command.Parameters.AddWithValue("@Remarks", (object?)item.Remarks ?? DBNull.Value);
                    await command.ExecuteNonQueryAsync();
                }
            }
        }

        public async Task<DemandRequestDetails> CreateAsync(DemandRequestCreateRequest request)
        {
            var now = DateTime.UtcNow;
            var suffix = Guid.NewGuid().ToString("N")[..6].ToUpperInvariant();
            var drNo = string.IsNullOrWhiteSpace(request.DRNo) ? $"DR-{now:yyyyMMddHHmmss}-{suffix}" : request.DRNo.Trim();
            var indentNo = string.IsNullOrWhiteSpace(request.IndentNo) ? $"IND-{now:yyyyMMddHHmmss}-{suffix}" : request.IndentNo.Trim();

            const string insertHeaderSql = @"
INSERT INTO dbo.DemandRequests
(
    DemandRequestNumber,
    IndentNumber,
    BranchId,
    RequestingStoreId,
    RequestedToStoreId,
    StockTypeId,
    DemandRequestStatusId,
    DemandNotes,
    IsActive,
    CreatedById,
    CreatedOn,
    ModifiedById,
    ModifiedOn
)
VALUES
(
    @DRNo,
    @IndentNo,
    @BranchId,
    @RequestingStoreId,
    @RequestedStoreId,
    @StockTypeId,
    COALESCE((SELECT TOP 1 Id FROM dbo.DemandRequestStatuses WHERE Name = @Status), 1),
    @Remarks,
    1,
    1,
    SYSUTCDATETIME(),
    NULL,
    SYSUTCDATETIME()
);

SELECT CAST(SCOPE_IDENTITY() AS INT);";

            const string insertItemSql = @"
INSERT INTO dbo.DemandRequestItems
(
    DemandRequestId,
    ItemId,
    MedicineId,
    SubServiceId,
    RequestedQuantity,
    ApprovedQuantity,
    IssuedQuantity,
    Notes,
    IsActive,
    CreatedOn
)
VALUES
(
    @DemandRequestId,
    @ItemId,
    @MedicineId,
    @SubServiceId,
    @RequestedQuantity,
    @ApprovedQuantity,
    @IssuedQuantity,
    @Remarks,
    1,
    SYSUTCDATETIME()
);";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = await connection.BeginTransactionAsync();

                int demandRequestId;

                using (var headerCommand = new SqlCommand(NormalizeSql(insertHeaderSql), connection, (SqlTransaction)transaction))
                {
                    var status = string.IsNullOrWhiteSpace(request.Status) ? "Pending" : request.Status.Trim();

                    headerCommand.Parameters.AddWithValue("@DRNo", drNo);
                    headerCommand.Parameters.AddWithValue("@IndentNo", indentNo);
                    headerCommand.Parameters.AddWithValue("@BranchId", request.BranchId);
                    headerCommand.Parameters.AddWithValue("@RequestingStoreId", (object?)(request.RequestingStoreId ?? request.RequestedStoreId) ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@RequestedStoreId", request.RequestedStoreId);
                    headerCommand.Parameters.AddWithValue("@StockTypeId", (object?)request.StockTypeId ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@Status", status);
                    headerCommand.Parameters.AddWithValue("@Remarks", (object?)request.Remarks ?? DBNull.Value);

                    demandRequestId = Convert.ToInt32(await headerCommand.ExecuteScalarAsync());
                }

                foreach (var item in request.Items)
                {
                    using var itemCommand = new SqlCommand(NormalizeSql(insertItemSql), connection, (SqlTransaction)transaction);

                    itemCommand.Parameters.AddWithValue("@DemandRequestId", demandRequestId);
                    itemCommand.Parameters.AddWithValue("@ItemId", (object?)item.ItemId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@MedicineId", (object?)item.MedicineId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@SubServiceId", (object?)item.SubServiceId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@RequestedQuantity", item.RequestedQuantity);
                    itemCommand.Parameters.AddWithValue("@ApprovedQuantity", (object?)item.ApprovedQuantity ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@IssuedQuantity", (object?)item.IssuedQuantity ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@Remarks", (object?)item.Remarks ?? DBNull.Value);

                    await itemCommand.ExecuteNonQueryAsync();
                }

                var createdStatus = string.IsNullOrWhiteSpace(request.Status) ? "Pending" : request.Status.Trim();
                await InsertLifeCycleAsync(connection, (SqlTransaction)transaction, demandRequestId, createdStatus, toUserId: 1, _schemaPrefix);

                await transaction.CommitAsync();

                return await GetByIdAsync(demandRequestId)
                    ?? throw new InvalidOperationException("Demand request was created but could not be retrieved.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating demand request");
                throw;
            }
        }

        private static DemandRequestSummary MapSummary(SqlDataReader reader)
        {
            return new DemandRequestSummary
            {
                DemandRequestId = reader.GetInt32(reader.GetOrdinal("DemandRequestId")),
                DRNo = reader.GetString(reader.GetOrdinal("DRNo")),
                IndentNo = reader.IsDBNull(reader.GetOrdinal("IndentNo")) ? null : reader.GetString(reader.GetOrdinal("IndentNo")),
                DateFrom = reader.GetDateTime(reader.GetOrdinal("DateFrom")),
                DateTo = reader.GetDateTime(reader.GetOrdinal("DateTo")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                RequestingBranchName = reader.GetString(reader.GetOrdinal("RequestingBranchName")),
                RequestingStoreId = reader.IsDBNull(reader.GetOrdinal("RequestingStoreId")) ? null : reader.GetInt32(reader.GetOrdinal("RequestingStoreId")),
                RequestingStoreName = reader.IsDBNull(reader.GetOrdinal("RequestingStoreName")) ? null : reader.GetString(reader.GetOrdinal("RequestingStoreName")),
                // RequestedToStoreId frequently has no matching row in the PharmacyStores view
                // (~58% of live DemandRequests rows) - the store it points at may have been
                // deactivated/renumbered on the HMS side since the demand was created. Must
                // degrade gracefully here rather than throw, or any page containing one of
                // these rows 500s outright.
                RequestedStoreId = reader.IsDBNull(reader.GetOrdinal("RequestedStoreId")) ? 0 : reader.GetInt32(reader.GetOrdinal("RequestedStoreId")),
                RequestedStoreName = reader.IsDBNull(reader.GetOrdinal("RequestedStoreName")) ? "Unknown Store" : reader.GetString(reader.GetOrdinal("RequestedStoreName")),
                StockTypeId = reader.IsDBNull(reader.GetOrdinal("StockTypeId")) ? null : reader.GetInt32(reader.GetOrdinal("StockTypeId")),
                StockTypeName = reader.IsDBNull(reader.GetOrdinal("StockTypeName")) ? null : reader.GetString(reader.GetOrdinal("StockTypeName")),
                ItemsCount = reader.GetInt32(reader.GetOrdinal("ItemsCount")),
                TotalRequestedQuantity = reader.GetInt32(reader.GetOrdinal("TotalRequestedQuantity")),
                ItemSummary = reader.IsDBNull(reader.GetOrdinal("ItemSummary")) ? null : reader.GetString(reader.GetOrdinal("ItemSummary")),
                Status = reader.GetString(reader.GetOrdinal("Status")),
                Remarks = reader.IsDBNull(reader.GetOrdinal("Remarks")) ? null : reader.GetString(reader.GetOrdinal("Remarks")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                RequestedByName = reader.IsDBNull(reader.GetOrdinal("RequestedByName")) ? null : reader.GetString(reader.GetOrdinal("RequestedByName")),
                ApprovedDate = reader.IsDBNull(reader.GetOrdinal("ApprovedDate")) ? null : reader.GetDateTime(reader.GetOrdinal("ApprovedDate")),
                IssuedDate = reader.IsDBNull(reader.GetOrdinal("IssuedDate")) ? null : reader.GetDateTime(reader.GetOrdinal("IssuedDate")),
                DriverName = reader.IsDBNull(reader.GetOrdinal("DriverName")) ? null : reader.GetString(reader.GetOrdinal("DriverName")),
                VehicleNumber = reader.IsDBNull(reader.GetOrdinal("VehicleNumber")) ? null : reader.GetString(reader.GetOrdinal("VehicleNumber")),
                ContactNumber = reader.IsDBNull(reader.GetOrdinal("ContactNumber")) ? null : reader.GetString(reader.GetOrdinal("ContactNumber")),
                Detail = reader.IsDBNull(reader.GetOrdinal("Detail")) ? null : reader.GetString(reader.GetOrdinal("Detail"))
            };
        }

        private static DemandRequestItem MapItem(SqlDataReader reader)
        {
            return new DemandRequestItem
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                DemandRequestId = reader.GetInt32(reader.GetOrdinal("DemandRequestId")),
                ItemId = reader.IsDBNull(reader.GetOrdinal("ItemId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? null : reader.GetString(reader.GetOrdinal("ItemName")),
                RequestedQuantity = reader.GetInt32(reader.GetOrdinal("RequestedQuantity")),
                ApprovedQuantity = reader.IsDBNull(reader.GetOrdinal("ApprovedQuantity")) ? null : reader.GetInt32(reader.GetOrdinal("ApprovedQuantity")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                BranchName = reader.IsDBNull(reader.GetOrdinal("BranchName")) ? null : reader.GetString(reader.GetOrdinal("BranchName")),
                MedicineId = reader.IsDBNull(reader.GetOrdinal("MedicineId")) ? null : reader.GetInt32(reader.GetOrdinal("MedicineId")),
                SubServiceId = reader.IsDBNull(reader.GetOrdinal("SubServiceId")) ? null : reader.GetInt32(reader.GetOrdinal("SubServiceId")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                Remarks = reader.IsDBNull(reader.GetOrdinal("Remarks")) ? null : reader.GetString(reader.GetOrdinal("Remarks")),
                StockTypeId = reader.IsDBNull(reader.GetOrdinal("StockTypeId")) ? null : reader.GetInt32(reader.GetOrdinal("StockTypeId")),
                StockTypeName = reader.IsDBNull(reader.GetOrdinal("StockTypeName")) ? null : reader.GetString(reader.GetOrdinal("StockTypeName")),
                IssuedQuantity = reader.IsDBNull(reader.GetOrdinal("IssuedQuantity")) ? null : reader.GetInt32(reader.GetOrdinal("IssuedQuantity")),
                IssuingQuantity = reader.IsDBNull(reader.GetOrdinal("IssuingQuantity")) ? null : reader.GetInt32(reader.GetOrdinal("IssuingQuantity")),
                RemainingQuantity = reader.IsDBNull(reader.GetOrdinal("RemainingQuantity")) ? null : reader.GetInt32(reader.GetOrdinal("RemainingQuantity")),
                AvailableQuantityInRequestingStore = reader.GetDecimal(reader.GetOrdinal("AvailableQuantityInRequestingStore")),
                AvailableQuantityInRequestedStore = reader.GetDecimal(reader.GetOrdinal("AvailableQuantityInRequestedStore"))
            };
        }
    }
}
