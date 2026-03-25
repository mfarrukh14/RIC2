using System.Data;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    public class DemandRequestService : IDemandRequestService
    {
        private readonly string _connectionString;
        private readonly ILogger<DemandRequestService> _logger;

        public DemandRequestService(IConfiguration configuration, ILogger<DemandRequestService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<IReadOnlyList<DemandRequestSummary>> GetAllAsync(DemandRequestFilter filter)
        {
            var results = new List<DemandRequestSummary>();

            const string sql = @"
SELECT
    dr.DemandRequestId,
    dr.DRNo,
    dr.IndentNo,
    dr.DateFrom,
    dr.DateTo,
    dr.BranchId,
    b.Name AS RequestingBranchName,
    dr.RequestingStoreId,
    COALESCE(rs.StoreName, s.StoreName) AS RequestingStoreName,
    dr.RequestedStoreId,
    s.StoreName AS RequestedStoreName,
    dr.StockTypeId,
    st.StockTypeName,
    dr.Status,
    dr.Remarks,
    dr.CreatedOn,
    COUNT(dri.Id) AS ItemsCount,
    COALESCE(SUM(dri.RequestedQuantity), 0) AS TotalRequestedQuantity,
    STRING_AGG(COALESCE(i.Name, 'Unassigned Item'), ', ') AS ItemSummary
FROM dbo.DemandRequests dr
INNER JOIN dbo.Branches b ON b.Id = dr.BranchId
LEFT JOIN dbo.Stores rs ON rs.StoreId = dr.RequestingStoreId
INNER JOIN dbo.Stores s ON s.StoreId = dr.RequestedStoreId
LEFT JOIN dbo.StockTypes st ON st.StockTypeId = dr.StockTypeId
LEFT JOIN dbo.DemandRequestItems dri
    ON dri.DemandRequestId = dr.DemandRequestId
   AND dri.IsActive = 1
LEFT JOIN dbo.Items i ON i.Id = dri.ItemId
WHERE dr.IsActive = 1
  AND (@BranchId IS NULL OR dr.BranchId = @BranchId)
    AND (@RequestingStoreId IS NULL OR dr.RequestingStoreId = @RequestingStoreId)
  AND (@RequestedStoreId IS NULL OR dr.RequestedStoreId = @RequestedStoreId)
  AND (
        @StockTypeId IS NULL
        OR dr.StockTypeId = @StockTypeId
        OR EXISTS (
            SELECT 1
            FROM dbo.DemandRequestItems dri2
            WHERE dri2.DemandRequestId = dr.DemandRequestId
              AND dri2.IsActive = 1
              AND dri2.StockTypeId = @StockTypeId
        )
      )
  AND (@DateFrom IS NULL OR dr.DateTo >= @DateFrom)
  AND (@DateTo IS NULL OR dr.DateFrom <= @DateTo)
  AND (
        @Search IS NULL
        OR dr.DRNo LIKE '%' + @Search + '%'
        OR ISNULL(dr.IndentNo, '') LIKE '%' + @Search + '%'
        OR b.Name LIKE '%' + @Search + '%'
                OR ISNULL(rs.StoreName, '') LIKE '%' + @Search + '%'
        OR s.StoreName LIKE '%' + @Search + '%'
        OR ISNULL(st.StockTypeName, '') LIKE '%' + @Search + '%'
        OR dr.Status LIKE '%' + @Search + '%'
      )
GROUP BY
    dr.DemandRequestId,
    dr.DRNo,
    dr.IndentNo,
    dr.DateFrom,
    dr.DateTo,
    dr.BranchId,
    b.Name,
    dr.RequestingStoreId,
    rs.StoreName,
    dr.RequestedStoreId,
    s.StoreName,
    dr.StockTypeId,
    st.StockTypeName,
    dr.Status,
    dr.Remarks,
    dr.CreatedOn
ORDER BY dr.CreatedOn DESC;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand(sql, connection)
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
    dr.DemandRequestId,
    dr.DRNo,
    dr.IndentNo,
    dr.DateFrom,
    dr.DateTo,
    dr.BranchId,
    b.Name AS RequestingBranchName,
    dr.RequestingStoreId,
    COALESCE(rs.StoreName, s.StoreName) AS RequestingStoreName,
    dr.RequestedStoreId,
    s.StoreName AS RequestedStoreName,
    dr.StockTypeId,
    st.StockTypeName,
    dr.Status,
    dr.Remarks,
    dr.CreatedOn,
    (
        SELECT COUNT(*)
        FROM dbo.DemandRequestItems dri
        WHERE dri.DemandRequestId = dr.DemandRequestId
          AND dri.IsActive = 1
    ) AS ItemsCount,
    (
        SELECT COALESCE(SUM(dri.RequestedQuantity), 0)
        FROM dbo.DemandRequestItems dri
        WHERE dri.DemandRequestId = dr.DemandRequestId
          AND dri.IsActive = 1
        ) AS TotalRequestedQuantity,
        (
                SELECT STRING_AGG(COALESCE(i.Name, 'Unassigned Item'), ', ')
                FROM dbo.DemandRequestItems dri
                LEFT JOIN dbo.Items i ON i.Id = dri.ItemId
                WHERE dri.DemandRequestId = dr.DemandRequestId
                    AND dri.IsActive = 1
        ) AS ItemSummary
FROM dbo.DemandRequests dr
INNER JOIN dbo.Branches b ON b.Id = dr.BranchId
LEFT JOIN dbo.Stores rs ON rs.StoreId = dr.RequestingStoreId
INNER JOIN dbo.Stores s ON s.StoreId = dr.RequestedStoreId
LEFT JOIN dbo.StockTypes st ON st.StockTypeId = dr.StockTypeId
WHERE dr.DemandRequestId = @DemandRequestId
  AND dr.IsActive = 1;";

            const string itemsSql = @"
SELECT
    dri.Id,
    dri.DemandRequestId,
    dri.ItemId,
    i.Name AS ItemName,
    dri.RequestedQuantity,
    dri.ApprovedQuantity,
    dri.BranchId,
    b.Name AS BranchName,
    dri.MedicineId,
    dri.SubServiceId,
    dri.IsActive,
    dri.CreatedById,
    dri.CreatedOn,
    dri.ModifiedById,
    dri.ModifiedOn,
    dri.Remarks,
    dri.StockTypeId,
    st.StockTypeName,
    dri.IssuedQuantity,
    dri.IssuingQuantity,
    dri.RemainingQuantity
FROM dbo.DemandRequestItems dri
LEFT JOIN dbo.Items i ON i.Id = dri.ItemId
INNER JOIN dbo.Branches b ON b.Id = dri.BranchId
LEFT JOIN dbo.StockTypes st ON st.StockTypeId = dri.StockTypeId
WHERE dri.DemandRequestId = @DemandRequestId
  AND dri.IsActive = 1
ORDER BY dri.Id;";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                DemandRequestDetails? details = null;

                using (var headerCommand = new SqlCommand(headerSql, connection))
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

                using (var itemsCommand = new SqlCommand(itemsSql, connection))
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

        public async Task<DemandRequestDetails?> ReceiveAsync(int id, DemandRequestReceiveRequest request)
        {
            const string updateHeaderSql = @"
UPDATE dbo.DemandRequests
SET
    Status = 'Received',
    IndentNo = COALESCE(NULLIF(@IndentNo, ''), IndentNo),
    ModifiedById = 1,
    ModifiedOn = SYSUTCDATETIME()
WHERE DemandRequestId = @DemandRequestId
  AND IsActive = 1;";

            const string updateItemsSql = @"
UPDATE dbo.DemandRequestItems
SET
    RemainingQuantity = 0,
    ModifiedById = 1,
    ModifiedOn = SYSUTCDATETIME()
WHERE DemandRequestId = @DemandRequestId
  AND IsActive = 1;";

            const string insertLifeCycleSql = @"
INSERT INTO dbo.DemandRequestLifeCycles
(
    DemandRequestId,
    DemandRequestStatusId,
    UserId,
    ActionByName,
    CreatedOn
)
SELECT
    @DemandRequestId,
    drs.DemandRequestStatusId,
    NULL,
    'Mr. Jalil Ahmed',
    SYSUTCDATETIME()
FROM dbo.DemandRequestStatuses drs
WHERE drs.StatusName = 'Received';";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = await connection.BeginTransactionAsync();

                using var headerCommand = new SqlCommand(updateHeaderSql, connection, (SqlTransaction)transaction);
                headerCommand.Parameters.AddWithValue("@DemandRequestId", id);
                headerCommand.Parameters.AddWithValue("@IndentNo", (object?)request.IndentNo ?? DBNull.Value);
                var rowsAffected = await headerCommand.ExecuteNonQueryAsync();

                if (rowsAffected == 0)
                {
                    await transaction.RollbackAsync();
                    return null;
                }

                using var itemsCommand = new SqlCommand(updateItemsSql, connection, (SqlTransaction)transaction);
                itemsCommand.Parameters.AddWithValue("@DemandRequestId", id);
                await itemsCommand.ExecuteNonQueryAsync();

                using var lifeCycleCommand = new SqlCommand(insertLifeCycleSql, connection, (SqlTransaction)transaction);
                lifeCycleCommand.Parameters.AddWithValue("@DemandRequestId", id);
                await lifeCycleCommand.ExecuteNonQueryAsync();

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
    DRNo,
    IndentNo,
    DateFrom,
    DateTo,
    BranchId,
    RequestingStoreId,
    RequestedStoreId,
    StockTypeId,
    Status,
    Remarks,
    IsActive,
    CreatedById,
    CreatedOn
)
VALUES
(
    @DRNo,
    @IndentNo,
    @DateFrom,
    @DateTo,
    @BranchId,
    @RequestingStoreId,
    @RequestedStoreId,
    @StockTypeId,
    @Status,
    @Remarks,
    1,
    1,
    SYSUTCDATETIME()
);

SELECT CAST(SCOPE_IDENTITY() AS INT);";

            const string insertLifeCycleSql = @"
INSERT INTO dbo.DemandRequestLifeCycles
(
    DemandRequestId,
    DemandRequestStatusId,
    UserId,
    ActionByName,
    CreatedOn
)
SELECT
    @DemandRequestId,
    drs.DemandRequestStatusId,
    NULL,
    @ActionByName,
    SYSUTCDATETIME()
FROM dbo.DemandRequestStatuses drs
WHERE drs.StatusName = @StatusName;";

            const string insertItemSql = @"
INSERT INTO dbo.DemandRequestItems
(
    DemandRequestId,
    ItemId,
    RequestedQuantity,
    ApprovedQuantity,
    BranchId,
    MedicineId,
    SubServiceId,
    IsActive,
    CreatedById,
    CreatedOn,
    Remarks,
    StockTypeId,
    IssuedQuantity,
    IssuingQuantity,
    RemainingQuantity
)
VALUES
(
    @DemandRequestId,
    @ItemId,
    @RequestedQuantity,
    @ApprovedQuantity,
    @BranchId,
    @MedicineId,
    @SubServiceId,
    1,
    1,
    SYSUTCDATETIME(),
    @Remarks,
    @StockTypeId,
    @IssuedQuantity,
    @IssuingQuantity,
    @RemainingQuantity
);";

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = await connection.BeginTransactionAsync();

                int demandRequestId;

                using (var headerCommand = new SqlCommand(insertHeaderSql, connection, (SqlTransaction)transaction))
                {
                    var status = string.IsNullOrWhiteSpace(request.Status) ? "Pending" : request.Status.Trim();

                    headerCommand.Parameters.AddWithValue("@DRNo", drNo);
                    headerCommand.Parameters.AddWithValue("@IndentNo", indentNo);
                    headerCommand.Parameters.AddWithValue("@DateFrom", request.DateFrom);
                    headerCommand.Parameters.AddWithValue("@DateTo", request.DateTo);
                    headerCommand.Parameters.AddWithValue("@BranchId", request.BranchId);
                    headerCommand.Parameters.AddWithValue("@RequestingStoreId", (object?)(request.RequestingStoreId ?? request.RequestedStoreId) ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@RequestedStoreId", request.RequestedStoreId);
                    headerCommand.Parameters.AddWithValue("@StockTypeId", (object?)request.StockTypeId ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@Status", status);
                    headerCommand.Parameters.AddWithValue("@Remarks", (object?)request.Remarks ?? DBNull.Value);

                    demandRequestId = Convert.ToInt32(await headerCommand.ExecuteScalarAsync());

                    using var lifeCycleCommand = new SqlCommand(insertLifeCycleSql, connection, (SqlTransaction)transaction);
                    lifeCycleCommand.Parameters.AddWithValue("@DemandRequestId", demandRequestId);
                    lifeCycleCommand.Parameters.AddWithValue("@StatusName", status);
                    lifeCycleCommand.Parameters.AddWithValue("@ActionByName", "Miss Ruth Yaqoob");
                    await lifeCycleCommand.ExecuteNonQueryAsync();
                }

                foreach (var item in request.Items)
                {
                    using var itemCommand = new SqlCommand(insertItemSql, connection, (SqlTransaction)transaction);
                    var issuedQuantity = item.IssuedQuantity ?? 0;
                    var remainingQuantity = item.RemainingQuantity ?? Math.Max(item.RequestedQuantity - issuedQuantity, 0);
                    object stockTypeValue = item.StockTypeId.HasValue
                        ? item.StockTypeId.Value
                        : request.StockTypeId.HasValue
                            ? request.StockTypeId.Value
                            : DBNull.Value;

                    itemCommand.Parameters.AddWithValue("@DemandRequestId", demandRequestId);
                    itemCommand.Parameters.AddWithValue("@ItemId", (object?)item.ItemId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@RequestedQuantity", item.RequestedQuantity);
                    itemCommand.Parameters.AddWithValue("@ApprovedQuantity", (object?)item.ApprovedQuantity ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@BranchId", item.BranchId ?? request.BranchId);
                    itemCommand.Parameters.AddWithValue("@MedicineId", (object?)item.MedicineId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@SubServiceId", (object?)item.SubServiceId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@Remarks", (object?)item.Remarks ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@StockTypeId", stockTypeValue);
                    itemCommand.Parameters.AddWithValue("@IssuedQuantity", (object?)item.IssuedQuantity ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@IssuingQuantity", (object?)item.IssuingQuantity ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@RemainingQuantity", remainingQuantity);

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