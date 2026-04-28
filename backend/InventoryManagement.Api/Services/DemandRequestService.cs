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

        public DemandRequestService(IConfiguration configuration, ILogger<DemandRequestService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
            var builder = new SqlConnectionStringBuilder(_connectionString);
            _schemaPrefix = builder.InitialCatalog.Equals("HMS", StringComparison.OrdinalIgnoreCase) ? "Inv" : "dbo";
        }

        private string NormalizeSql(string sql) => sql.Replace("dbo.", $"{_schemaPrefix}.");

        public async Task<IReadOnlyList<DemandRequestSummary>> GetAllAsync(DemandRequestFilter filter)
        {
            var results = new List<DemandRequestSummary>();

            const string sql = @"
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
    COUNT(dri.Id) AS ItemsCount,
    COALESCE(SUM(dri.RequestedQuantity), 0) AS TotalRequestedQuantity,
    STRING_AGG(COALESCE(i.Name, 'Unassigned Item'), ', ') AS ItemSummary
FROM dbo.DemandRequests dr
INNER JOIN dbo.Branches b ON b.Id = dr.BranchId
LEFT JOIN dbo.Stores rs ON rs.StoreId = dr.RequestingStoreId
INNER JOIN dbo.Stores s ON s.StoreId = dr.RequestedToStoreId
LEFT JOIN dbo.StockTypes st ON st.Id = dr.StockTypeId
LEFT JOIN dbo.DemandRequestStatuses drs ON drs.Id = dr.DemandRequestStatusId
LEFT JOIN dbo.DemandRequestItems dri
    ON dri.DemandRequestId = dr.Id
   AND dri.IsActive = 1
LEFT JOIN dbo.Items i ON i.Id = dri.ItemId
WHERE dr.IsActive = 1
  AND (@BranchId IS NULL OR dr.BranchId = @BranchId)
  AND (@RequestingStoreId IS NULL OR dr.RequestingStoreId = @RequestingStoreId)
  AND (@RequestedStoreId IS NULL OR dr.RequestedToStoreId = @RequestedStoreId)
  AND (@StockTypeId IS NULL OR dr.StockTypeId = @StockTypeId)
  AND (@DateFrom IS NULL OR COALESCE(dr.ModifiedOn, dr.CreatedOn) >= @DateFrom)
  AND (@DateTo IS NULL OR dr.CreatedOn <= @DateTo)
  AND (
        @Search IS NULL
        OR dr.DemandRequestNumber LIKE '%' + @Search + '%'
        OR ISNULL(dr.IndentNumber, '') LIKE '%' + @Search + '%'
        OR b.Name LIKE '%' + @Search + '%'
        OR ISNULL(rs.StoreName, '') LIKE '%' + @Search + '%'
        OR s.StoreName LIKE '%' + @Search + '%'
        OR ISNULL(st.Name, '') LIKE '%' + @Search + '%'
        OR drs.Name LIKE '%' + @Search + '%'
      )
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
    dr.DemandNotes
ORDER BY dr.CreatedOn DESC;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection)
                {
                    CommandType = CommandType.Text
                };

                command.Parameters.AddWithValue("@BranchId", (object?)filter.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@RequestingStoreId", (object?)filter.RequestingStoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@RequestedStoreId", (object?)filter.RequestedStoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StockTypeId", (object?)filter.StockTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateFrom", (object?)filter.DateFrom ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateTo", (object?)filter.DateTo ?? DBNull.Value);
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
                _logger.LogError(ex, "Error retrieving demand requests");
                throw;
            }

            return results;
        }

        public async Task<DemandRequestDetails?> GetByIdAsync(int id)
        {
            const string headerSql = @"
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
LEFT JOIN dbo.Stores rs ON rs.StoreId = dr.RequestingStoreId
INNER JOIN dbo.Stores s ON s.StoreId = dr.RequestedToStoreId
LEFT JOIN dbo.StockTypes st ON st.Id = dr.StockTypeId
LEFT JOIN dbo.DemandRequestStatuses drs ON drs.Id = dr.DemandRequestStatusId
WHERE dr.Id = @DemandRequestId
  AND dr.IsActive = 1;";

            const string itemsSql = @"
SELECT
    dri.Id,
    dri.DemandRequestId,
    dri.ItemId,
    i.Name AS ItemName,
    dri.RequestedQuantity,
    dri.ApprovedQuantity,
    dr.BranchId,
    b.Name AS BranchName,
    CAST(NULL AS INT) AS MedicineId,
    CAST(NULL AS INT) AS SubServiceId,
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
    CAST(CASE WHEN dri.RequestedQuantity - ISNULL(dri.IssuedQuantity, 0) > 0
              THEN dri.RequestedQuantity - ISNULL(dri.IssuedQuantity, 0) ELSE 0 END AS INT) AS RemainingQuantity
FROM dbo.DemandRequestItems dri
LEFT JOIN dbo.Items i ON i.Id = dri.ItemId
INNER JOIN dbo.DemandRequests dr ON dr.Id = dri.DemandRequestId
INNER JOIN dbo.Branches b ON b.Id = dr.BranchId
LEFT JOIN dbo.StockTypes st ON st.Id = dr.StockTypeId
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
                            CreatedOn = summary.CreatedOn
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

            // DemandRequestLifeCycles table does not exist in HMS - return empty list
            if (_schemaPrefix == "Inv")
            {
                return results;
            }

            const string sql = @"
SELECT
    drlc.Id,
    drlc.DemandRequestId,
    drlc.DemandRequestStatusId,
    drs.StatusName,
    drlc.UserId,
    COALESCE(drlc.ActionByName, CONCAT('User #', drlc.UserId), 'System') AS ActionBy,
    drlc.CreatedOn
FROM dbo.DemandRequestLifeCycles drlc
INNER JOIN dbo.DemandRequestStatuses drs ON drs.DemandRequestStatusId = drlc.DemandRequestStatusId
WHERE drlc.DemandRequestId = @DemandRequestId
ORDER BY drlc.CreatedOn DESC, drlc.Id DESC;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(NormalizeSql(sql), connection)
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

        public async Task<DemandRequestDetails?> ReceiveAsync(int id, DemandRequestReceiveRequest request)
        {
            const string updateHeaderSql = @"
UPDATE dbo.DemandRequests
SET
    DemandRequestStatusId = (SELECT TOP 1 Id FROM dbo.DemandRequestStatuses WHERE Name = 'Received'),
    IndentNumber = COALESCE(NULLIF(@IndentNo, ''), IndentNumber),
    ReceivedDate = SYSUTCDATETIME(),
    ModifiedById = 1,
    ModifiedOn = SYSUTCDATETIME()
WHERE Id = @DemandRequestId
  AND IsActive = 1;";

            const string updateItemsSql = @"
UPDATE dbo.DemandRequestItems
SET
    ReceivedQuantity = COALESCE(IssuedQuantity, RequestedQuantity)
WHERE DemandRequestId = @DemandRequestId
  AND IsActive = 1;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = await connection.BeginTransactionAsync();

                using var headerCommand = new SqlCommand(NormalizeSql(updateHeaderSql), connection, (SqlTransaction)transaction);
                headerCommand.Parameters.AddWithValue("@DemandRequestId", id);
                headerCommand.Parameters.AddWithValue("@IndentNo", (object?)request.IndentNo ?? DBNull.Value);
                var rowsAffected = await headerCommand.ExecuteNonQueryAsync();

                if (rowsAffected == 0)
                {
                    await transaction.RollbackAsync();
                    return null;
                }

                using var itemsCommand = new SqlCommand(NormalizeSql(updateItemsSql), connection, (SqlTransaction)transaction);
                itemsCommand.Parameters.AddWithValue("@DemandRequestId", id);
                await itemsCommand.ExecuteNonQueryAsync();

                await transaction.CommitAsync();
                return await GetByIdAsync(id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error receiving demand request with ID {DemandRequestId}", id);
                throw;
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
    CreatedOn
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
    SYSUTCDATETIME()
);

SELECT CAST(SCOPE_IDENTITY() AS INT);";

            const string insertItemSql = @"
INSERT INTO dbo.DemandRequestItems
(
    DemandRequestId,
    ItemId,
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
                    itemCommand.Parameters.AddWithValue("@RequestedQuantity", item.RequestedQuantity);
                    itemCommand.Parameters.AddWithValue("@ApprovedQuantity", (object?)item.ApprovedQuantity ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@IssuedQuantity", (object?)item.IssuedQuantity ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@Remarks", (object?)item.Remarks ?? DBNull.Value);

                    await itemCommand.ExecuteNonQueryAsync();
                }

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
                RequestedStoreId = reader.GetInt32(reader.GetOrdinal("RequestedStoreId")),
                RequestedStoreName = reader.GetString(reader.GetOrdinal("RequestedStoreName")),
                StockTypeId = reader.IsDBNull(reader.GetOrdinal("StockTypeId")) ? null : reader.GetInt32(reader.GetOrdinal("StockTypeId")),
                StockTypeName = reader.IsDBNull(reader.GetOrdinal("StockTypeName")) ? null : reader.GetString(reader.GetOrdinal("StockTypeName")),
                ItemsCount = reader.GetInt32(reader.GetOrdinal("ItemsCount")),
                TotalRequestedQuantity = reader.GetInt32(reader.GetOrdinal("TotalRequestedQuantity")),
                ItemSummary = reader.IsDBNull(reader.GetOrdinal("ItemSummary")) ? null : reader.GetString(reader.GetOrdinal("ItemSummary")),
                Status = reader.GetString(reader.GetOrdinal("Status")),
                Remarks = reader.IsDBNull(reader.GetOrdinal("Remarks")) ? null : reader.GetString(reader.GetOrdinal("Remarks")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn"))
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
                RemainingQuantity = reader.IsDBNull(reader.GetOrdinal("RemainingQuantity")) ? null : reader.GetInt32(reader.GetOrdinal("RemainingQuantity"))
            };
        }
    }
}
