using System.Data;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    // Ported from the old iHealthCure system's PurchaseRequisitions module (see
    // backend/Database/Tables/CreatePurchaseRequisitionTables.sql for the schema
    // rationale). Uses raw parameterized SQL against Inv.* rather than stored
    // procedures, matching DemandRequestService - the closest existing precedent
    // for a request/workflow entity in this codebase.
    public class PurchaseRequisitionService : IPurchaseRequisitionService
    {
        private readonly string _connectionString;
        private readonly ILogger<PurchaseRequisitionService> _logger;

        public PurchaseRequisitionService(IConfiguration configuration, ILogger<PurchaseRequisitionService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        private const string HeaderSelect = @"
SELECT
    pr.Id,
    pr.PRNumber,
    pr.DemandRequestId,
    pr.DemandNo,
    pr.BranchId,
    pr.StoreId,
    s.StoreName,
    pr.DepartmentId,
    d.Name AS DepartmentName,
    pr.FinancialYearId,
    fy.Name AS FinancialYearName,
    pr.DistributionPlan,
    pr.Priority,
    pr.DateRequiredBy,
    pr.PRType,
    pr.VendorId,
    v.Name AS VendorName,
    pr.SuggestedProcurementMethod,
    pr.Subject,
    pr.ScopeOfWork,
    pr.Instructions,
    pr.Remarks,
    pr.GoodsDeliveredContactPerson,
    pr.GoodsDeliveredCellNumber,
    pr.GoodsDeliveredEmail,
    pr.GoodsDeliveredTelephone,
    pr.GoodsDeliveredFaxNo,
    pr.GoodsDeliveryAddress,
    pr.TermsAndConditions,
    pr.IsTechnicalReviewed,
    pr.TechnicalReviewRemarks,
    pr.TotalEstimatedCost,
    pr.PurchaseRequisitionStatusId,
    prs.Name AS StatusName,
    prs.Category AS StatusCategory,
    pr.AssignedToId,
    ISNULL(ae.FullName, NULLIF(LTRIM(RTRIM(ISNULL(ae.FirstName, '') + ' ' + ISNULL(ae.LastName, ''))), '')) AS AssignedToName,
    pr.CreatedOn,
    pr.ModifiedOn
FROM Inv.PurchaseRequisitions pr
INNER JOIN Inv.PurchaseRequisitionStatus prs ON prs.Id = pr.PurchaseRequisitionStatusId
LEFT JOIN Inv.PharmacyStores s ON s.StoreId = pr.StoreId
LEFT JOIN dbo.Departments d ON d.DID = pr.DepartmentId
LEFT JOIN Inv.FinancialYears fy ON fy.Id = pr.FinancialYearId
LEFT JOIN Inv.Vendors v ON v.Id = pr.VendorId
LEFT JOIN Users au ON au.UserID = pr.AssignedToId
LEFT JOIN Employee ae ON ae.EmpID = au.EmpID
";

        public async Task<PagedResult<PurchaseRequisitionListItem>> GetAllAsync(PurchaseRequisitionFilter filter)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(filter.PageNumber, filter.PageSize);
            var results = new List<PurchaseRequisitionListItem>();
            var totalCount = 0;

            string sql = ";WITH PRList AS (" + HeaderSelect + @"
WHERE pr.IsActive = 1
  AND (@BranchId IS NULL OR pr.BranchId = @BranchId)
  AND (@StatusCategory IS NULL OR prs.Category = @StatusCategory)
  AND (
        @Search IS NULL
        OR pr.PRNumber LIKE '%' + @Search + '%'
        OR ISNULL(d.Name, '') LIKE '%' + @Search + '%'
        OR ISNULL(v.Name, '') LIKE '%' + @Search + '%'
        OR ISNULL(pr.Subject, '') LIKE '%' + @Search + '%'
      )
)
SELECT *, COUNT(*) OVER() AS TotalCount
FROM PRList
ORDER BY ModifiedOn DESC
OFFSET @Offset ROWS FETCH NEXT @Take ROWS ONLY;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@BranchId", (object?)filter.BranchId ?? DBNull.Value);
            command.Parameters.AddWithValue("@StatusCategory", (object?)filter.StatusCategory ?? DBNull.Value);
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
                results.Add(new PurchaseRequisitionListItem
                {
                    Id = reader.GetInt32(reader.GetOrdinal("Id")),
                    PRNumber = reader.GetString(reader.GetOrdinal("PRNumber")),
                    DepartmentName = reader.IsDBNull(reader.GetOrdinal("DepartmentName")) ? null : reader.GetString(reader.GetOrdinal("DepartmentName")),
                    VendorName = reader.IsDBNull(reader.GetOrdinal("VendorName")) ? null : reader.GetString(reader.GetOrdinal("VendorName")),
                    Priority = reader.GetInt32(reader.GetOrdinal("Priority")),
                    PriorityName = reader.GetInt32(reader.GetOrdinal("Priority")) == 2 ? "Urgent" : "Routine",
                    TotalEstimatedCost = reader.GetDecimal(reader.GetOrdinal("TotalEstimatedCost")),
                    DateRequiredBy = reader.IsDBNull(reader.GetOrdinal("DateRequiredBy")) ? null : reader.GetDateTime(reader.GetOrdinal("DateRequiredBy")),
                    IsTechnicalReviewed = reader.GetBoolean(reader.GetOrdinal("IsTechnicalReviewed")),
                    AssignedToName = reader.IsDBNull(reader.GetOrdinal("AssignedToName")) ? null : reader.GetString(reader.GetOrdinal("AssignedToName")),
                    ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? reader.GetDateTime(reader.GetOrdinal("CreatedOn")) : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                    StatusName = reader.GetString(reader.GetOrdinal("StatusName")),
                    StatusCategory = reader.GetString(reader.GetOrdinal("StatusCategory"))
                });
            }

            return new PagedResult<PurchaseRequisitionListItem> { Items = results, TotalCount = totalCount, PageNumber = pageNumber, PageSize = pageSize };
        }

        public async Task<PurchaseRequisitionDetails?> GetByIdAsync(int id)
        {
            string headerSql = HeaderSelect + " WHERE pr.Id = @Id AND pr.IsActive = 1;";

            const string itemsSql = @"
SELECT
    pri.Id,
    pri.ItemId,
    pri.MedicineId,
    pri.SubServiceId,
    COALESCE(i.Name, med.MedicineFullName, f.Name) AS ItemName,
    pri.Quantity,
    pri.UnitEstimatedCost,
    pri.TotalEstimatedCost,
    pri.BudgetHeadId,
    ISNULL(bh.ObjectCode + ' - ', '') + ISNULL(bh.ObjectClassification, '') AS BudgetHeadName,
    pri.AvailableBudget,
    pri.BudgetRestriction,
    pri.Remarks
FROM Inv.PurchaseRequisitionItems pri
LEFT JOIN Inv.Items i ON i.Id = pri.ItemId
LEFT JOIN Pharmacy.Medicines med ON med.MedicineId = pri.MedicineId
LEFT JOIN Account.Fees f ON f.Id = pri.SubServiceId
LEFT JOIN Inv.BudgetHeads bh ON bh.Id = pri.BudgetHeadId
WHERE pri.PurchaseRequisitionId = @Id AND (pri.IsDeleted = 0 OR pri.IsDeleted IS NULL)
ORDER BY pri.Id;";

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            PurchaseRequisitionDetails? details = null;

            using (var headerCommand = new SqlCommand(headerSql, connection))
            {
                headerCommand.Parameters.AddWithValue("@Id", id);
                using var reader = await headerCommand.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    details = MapDetails(reader);
                }
            }

            if (details == null)
            {
                return null;
            }

            using (var itemsCommand = new SqlCommand(itemsSql, connection))
            {
                itemsCommand.Parameters.AddWithValue("@Id", id);
                using var itemsReader = await itemsCommand.ExecuteReaderAsync();
                while (await itemsReader.ReadAsync())
                {
                    details.Items.Add(new PurchaseRequisitionItemModel
                    {
                        Id = itemsReader.GetInt32(itemsReader.GetOrdinal("Id")),
                        ItemId = itemsReader.IsDBNull(itemsReader.GetOrdinal("ItemId")) ? null : itemsReader.GetInt32(itemsReader.GetOrdinal("ItemId")),
                        MedicineId = itemsReader.IsDBNull(itemsReader.GetOrdinal("MedicineId")) ? null : itemsReader.GetInt32(itemsReader.GetOrdinal("MedicineId")),
                        SubServiceId = itemsReader.IsDBNull(itemsReader.GetOrdinal("SubServiceId")) ? null : itemsReader.GetInt32(itemsReader.GetOrdinal("SubServiceId")),
                        ItemName = itemsReader.IsDBNull(itemsReader.GetOrdinal("ItemName")) ? null : itemsReader.GetString(itemsReader.GetOrdinal("ItemName")),
                        Quantity = itemsReader.GetInt32(itemsReader.GetOrdinal("Quantity")),
                        UnitEstimatedCost = itemsReader.GetDecimal(itemsReader.GetOrdinal("UnitEstimatedCost")),
                        TotalEstimatedCost = itemsReader.GetDecimal(itemsReader.GetOrdinal("TotalEstimatedCost")),
                        BudgetHeadId = itemsReader.IsDBNull(itemsReader.GetOrdinal("BudgetHeadId")) ? null : itemsReader.GetInt32(itemsReader.GetOrdinal("BudgetHeadId")),
                        BudgetHeadName = itemsReader.IsDBNull(itemsReader.GetOrdinal("BudgetHeadName")) ? null : itemsReader.GetString(itemsReader.GetOrdinal("BudgetHeadName")),
                        AvailableBudget = itemsReader.IsDBNull(itemsReader.GetOrdinal("AvailableBudget")) ? null : itemsReader.GetDecimal(itemsReader.GetOrdinal("AvailableBudget")),
                        BudgetRestriction = itemsReader.IsDBNull(itemsReader.GetOrdinal("BudgetRestriction")) ? null : itemsReader.GetString(itemsReader.GetOrdinal("BudgetRestriction")),
                        Remarks = itemsReader.IsDBNull(itemsReader.GetOrdinal("Remarks")) ? null : itemsReader.GetString(itemsReader.GetOrdinal("Remarks"))
                    });
                }
            }

            return details;
        }

        public async Task<PurchaseRequisitionDetails> CreateAsync(PurchaseRequisitionCreateRequest request, int userId)
        {
            var now = DateTime.UtcNow;
            var suffix = Guid.NewGuid().ToString("N")[..6].ToUpperInvariant();
            var prNumber = $"PR-{now:yyyyMMddHHmmss}-{suffix}";
            var isForwarded = request.ForwardToUserId.HasValue && request.ForwardToUserId.Value > 0;
            var initialStatus = isForwarded ? "Forward" : "Pending";

            const string insertHeaderSql = @"
INSERT INTO Inv.PurchaseRequisitions
(
    PRNumber, DemandRequestId, DemandNo, BranchId, StoreId, DepartmentId, FinancialYearId,
    DistributionPlan, Priority, DateRequiredBy, PRType, VendorId, SuggestedProcurementMethod,
    Subject, ScopeOfWork, Instructions, Remarks, GoodsDeliveredContactPerson, GoodsDeliveredCellNumber,
    GoodsDeliveredEmail, GoodsDeliveredTelephone, GoodsDeliveredFaxNo, GoodsDeliveryAddress,
    TermsAndConditions, PurchaseRequisitionStatusId, AssignedToId, IsActive, CreatedById, CreatedOn, ModifiedOn
)
VALUES
(
    @PRNumber, @DemandRequestId, @DemandNo, @BranchId, @StoreId, @DepartmentId, @FinancialYearId,
    @DistributionPlan, @Priority, @DateRequiredBy, @PRType, @VendorId, @SuggestedProcurementMethod,
    @Subject, @ScopeOfWork, @Instructions, @Remarks, @GoodsDeliveredContactPerson, @GoodsDeliveredCellNumber,
    @GoodsDeliveredEmail, @GoodsDeliveredTelephone, @GoodsDeliveredFaxNo, @GoodsDeliveryAddress,
    @TermsAndConditions,
    (SELECT TOP 1 Id FROM Inv.PurchaseRequisitionStatus WHERE Name = @StatusName),
    @AssignedToId, 1, @CreatedById, GETDATE(), GETDATE()
);
SELECT CAST(SCOPE_IDENTITY() AS INT);";

            const string insertItemSql = @"
INSERT INTO Inv.PurchaseRequisitionItems
(PurchaseRequisitionId, ItemId, MedicineId, SubServiceId, Quantity, UnitEstimatedCost, TotalEstimatedCost, BudgetHeadId, AvailableBudget, BudgetRestriction, Remarks, IsActive, CreatedById, CreatedOn)
VALUES
(@PurchaseRequisitionId, @ItemId, @MedicineId, @SubServiceId, @Quantity, @UnitEstimatedCost, @TotalEstimatedCost, @BudgetHeadId, @AvailableBudget, @BudgetRestriction, @Remarks, 1, @CreatedById, GETDATE());";

            const string updateTotalSql = @"
UPDATE Inv.PurchaseRequisitions
SET TotalEstimatedCost = (SELECT ISNULL(SUM(TotalEstimatedCost), 0) FROM Inv.PurchaseRequisitionItems WHERE PurchaseRequisitionId = @Id AND (IsDeleted = 0 OR IsDeleted IS NULL)),
    TotalBudget = (SELECT ISNULL(SUM(TotalEstimatedCost), 0) FROM Inv.PurchaseRequisitionItems WHERE PurchaseRequisitionId = @Id AND (IsDeleted = 0 OR IsDeleted IS NULL))
WHERE Id = @Id;";

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();
            using var transaction = (SqlTransaction)await connection.BeginTransactionAsync();

            try
            {
                int purchaseRequisitionId;
                using (var headerCommand = new SqlCommand(insertHeaderSql, connection, transaction))
                {
                    headerCommand.Parameters.AddWithValue("@PRNumber", prNumber);
                    headerCommand.Parameters.AddWithValue("@DemandRequestId", (object?)request.DemandRequestId ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@DemandNo", (object?)request.DemandNo ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@BranchId", request.BranchId);
                    headerCommand.Parameters.AddWithValue("@StoreId", (object?)request.StoreId ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@DepartmentId", (object?)request.DepartmentId ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@FinancialYearId", (object?)request.FinancialYearId ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@DistributionPlan", (object?)request.DistributionPlan ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@Priority", request.Priority);
                    headerCommand.Parameters.AddWithValue("@DateRequiredBy", (object?)request.DateRequiredBy ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@PRType", request.PRType);
                    headerCommand.Parameters.AddWithValue("@VendorId", (object?)request.VendorId ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@SuggestedProcurementMethod", (object?)request.SuggestedProcurementMethod ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@Subject", (object?)request.Subject ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@ScopeOfWork", (object?)request.ScopeOfWork ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@Instructions", (object?)request.Instructions ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@Remarks", (object?)request.Remarks ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@GoodsDeliveredContactPerson", (object?)request.GoodsDeliveredContactPerson ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@GoodsDeliveredCellNumber", (object?)request.GoodsDeliveredCellNumber ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@GoodsDeliveredEmail", (object?)request.GoodsDeliveredEmail ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@GoodsDeliveredTelephone", (object?)request.GoodsDeliveredTelephone ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@GoodsDeliveredFaxNo", (object?)request.GoodsDeliveredFaxNo ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@GoodsDeliveryAddress", (object?)request.GoodsDeliveryAddress ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@TermsAndConditions", (object?)request.TermsAndConditions ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@StatusName", initialStatus);
                    headerCommand.Parameters.AddWithValue("@AssignedToId", (object?)request.ForwardToUserId ?? DBNull.Value);
                    headerCommand.Parameters.AddWithValue("@CreatedById", userId);

                    purchaseRequisitionId = Convert.ToInt32(await headerCommand.ExecuteScalarAsync());
                }

                foreach (var item in request.Items)
                {
                    if (item.Quantity <= 0)
                    {
                        continue;
                    }

                    using var itemCommand = new SqlCommand(insertItemSql, connection, transaction);
                    itemCommand.Parameters.AddWithValue("@PurchaseRequisitionId", purchaseRequisitionId);
                    itemCommand.Parameters.AddWithValue("@ItemId", (object?)item.ItemId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@MedicineId", (object?)item.MedicineId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@SubServiceId", (object?)item.SubServiceId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@Quantity", item.Quantity);
                    itemCommand.Parameters.AddWithValue("@UnitEstimatedCost", item.UnitEstimatedCost);
                    itemCommand.Parameters.AddWithValue("@TotalEstimatedCost", item.UnitEstimatedCost * item.Quantity);
                    itemCommand.Parameters.AddWithValue("@BudgetHeadId", (object?)item.BudgetHeadId ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@AvailableBudget", (object?)item.AvailableBudget ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@BudgetRestriction", (object?)item.BudgetRestriction ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@Remarks", (object?)item.Remarks ?? DBNull.Value);
                    itemCommand.Parameters.AddWithValue("@CreatedById", userId);
                    await itemCommand.ExecuteNonQueryAsync();
                }

                using (var totalCommand = new SqlCommand(updateTotalSql, connection, transaction))
                {
                    totalCommand.Parameters.AddWithValue("@Id", purchaseRequisitionId);
                    await totalCommand.ExecuteNonQueryAsync();
                }

                await InsertLifeCycleAsync(connection, transaction, purchaseRequisitionId, initialStatus, userId, isForwarded ? request.ForwardToUserId : userId, request.ForwardRemarks);

                await transaction.CommitAsync();

                return await GetByIdAsync(purchaseRequisitionId)
                    ?? throw new InvalidOperationException("Purchase requisition was created but could not be retrieved.");
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "Error creating purchase requisition");
                throw;
            }
        }

        public async Task<PurchaseRequisitionDetails?> ForwardAsync(int id, PurchaseRequisitionForwardRequest request, int userId)
        {
            const string updateSql = @"
UPDATE Inv.PurchaseRequisitions
SET AssignedToId = @ToUserId,
    PurchaseRequisitionStatusId = (SELECT TOP 1 Id FROM Inv.PurchaseRequisitionStatus WHERE Name = 'Forward'),
    ModifiedById = @UserId,
    ModifiedOn = GETDATE()
WHERE Id = @Id AND IsActive = 1;";

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();
            using var transaction = (SqlTransaction)await connection.BeginTransactionAsync();

            try
            {
                using (var command = new SqlCommand(updateSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@Id", id);
                    command.Parameters.AddWithValue("@ToUserId", request.ToUserId);
                    command.Parameters.AddWithValue("@UserId", userId);
                    var rows = await command.ExecuteNonQueryAsync();
                    if (rows == 0)
                    {
                        await transaction.RollbackAsync();
                        return null;
                    }
                }

                await InsertLifeCycleAsync(connection, transaction, id, "Forward", userId, request.ToUserId, request.Remarks);

                await transaction.CommitAsync();
                return await GetByIdAsync(id);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "Error forwarding purchase requisition {Id}", id);
                throw;
            }
        }

        public async Task<PurchaseRequisitionDetails?> ChangeStatusAsync(int id, PurchaseRequisitionStatusChangeRequest request, int userId)
        {
            var isClosed = request.Status.Equals("Closed", StringComparison.OrdinalIgnoreCase)
                || request.Status.Equals("Rejected", StringComparison.OrdinalIgnoreCase)
                || request.Status.Equals("Cancelled", StringComparison.OrdinalIgnoreCase);

            const string updateSql = @"
UPDATE Inv.PurchaseRequisitions
SET PurchaseRequisitionStatusId = (SELECT TOP 1 Id FROM Inv.PurchaseRequisitionStatus WHERE Name = @StatusName),
    IsClosed = @IsClosed,
    Remarks = COALESCE(@Remarks, Remarks),
    ModifiedById = @UserId,
    ModifiedOn = GETDATE()
WHERE Id = @Id AND IsActive = 1;";

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();
            using var transaction = (SqlTransaction)await connection.BeginTransactionAsync();

            try
            {
                using (var command = new SqlCommand(updateSql, connection, transaction))
                {
                    command.Parameters.AddWithValue("@Id", id);
                    command.Parameters.AddWithValue("@StatusName", request.Status);
                    command.Parameters.AddWithValue("@IsClosed", isClosed);
                    command.Parameters.AddWithValue("@Remarks", (object?)request.Remarks ?? DBNull.Value);
                    command.Parameters.AddWithValue("@UserId", userId);
                    var rows = await command.ExecuteNonQueryAsync();
                    if (rows == 0)
                    {
                        await transaction.RollbackAsync();
                        return null;
                    }
                }

                await InsertLifeCycleAsync(connection, transaction, id, request.Status, userId, userId, request.Remarks);

                await transaction.CommitAsync();
                return await GetByIdAsync(id);
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "Error changing status of purchase requisition {Id}", id);
                throw;
            }
        }

        public async Task<IReadOnlyList<PurchaseRequisitionLifeCycleEntry>> GetLifeCycleAsync(int id)
        {
            var results = new List<PurchaseRequisitionLifeCycleEntry>();

            const string sql = @"
SELECT
    prlc.Id,
    prs.Name AS Status,
    ISNULL(te.FullName, NULLIF(LTRIM(RTRIM(ISNULL(te.FirstName, '') + ' ' + ISNULL(te.LastName, ''))), '')) AS ActionBy,
    prlc.Remarks,
    prlc.CreatedOn
FROM Inv.PurchaseRequisitionLifeCycles prlc
LEFT JOIN Inv.PurchaseRequisitionStatus prs ON prs.Id = prlc.PurchaseRequisitionStatusId
LEFT JOIN Users tu ON tu.UserID = prlc.ToUserId
LEFT JOIN Employee te ON te.EmpID = tu.EmpID
WHERE prlc.PurchaseRequisitionId = @Id
ORDER BY prlc.CreatedOn DESC, prlc.Id DESC;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@Id", id);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PurchaseRequisitionLifeCycleEntry
                {
                    Id = reader.GetInt32(reader.GetOrdinal("Id")),
                    Status = reader.IsDBNull(reader.GetOrdinal("Status")) ? "Unknown" : reader.GetString(reader.GetOrdinal("Status")),
                    ActionBy = reader.IsDBNull(reader.GetOrdinal("ActionBy")) ? null : reader.GetString(reader.GetOrdinal("ActionBy")),
                    Remarks = reader.IsDBNull(reader.GetOrdinal("Remarks")) ? null : reader.GetString(reader.GetOrdinal("Remarks")),
                    CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn"))
                });
            }

            return results;
        }

        public async Task<IReadOnlyList<PurchaseRequisitionLookupItem>> GetFinancialYearsAsync()
        {
            return await GetLookupAsync("SELECT Id, Name FROM Inv.FinancialYears WHERE IsActive = 1 ORDER BY StartDate DESC;");
        }

        public async Task<IReadOnlyList<PurchaseRequisitionLookupItem>> GetBudgetHeadsAsync()
        {
            return await GetLookupAsync("SELECT Id, ISNULL(ObjectCode + ' - ', '') + ObjectClassification AS Name FROM Inv.BudgetHeads WHERE IsActive = 1 ORDER BY ObjectCode;");
        }

        private async Task<IReadOnlyList<PurchaseRequisitionLookupItem>> GetLookupAsync(string sql)
        {
            var results = new List<PurchaseRequisitionLookupItem>();
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PurchaseRequisitionLookupItem
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1)
                });
            }
            return results;
        }

        private static async Task InsertLifeCycleAsync(SqlConnection connection, SqlTransaction transaction, int purchaseRequisitionId, string statusName, int fromUserId, int? toUserId, string? remarks)
        {
            const string sql = @"
INSERT INTO Inv.PurchaseRequisitionLifeCycles (PurchaseRequisitionId, PurchaseRequisitionStatusId, FromUserId, ToUserId, Remarks, CreatedOn)
SELECT @PurchaseRequisitionId, prs.Id, @FromUserId, @ToUserId, @Remarks, GETDATE()
FROM Inv.PurchaseRequisitionStatus prs
WHERE prs.Name = @StatusName;";

            using var command = new SqlCommand(sql, connection, transaction);
            command.Parameters.AddWithValue("@PurchaseRequisitionId", purchaseRequisitionId);
            command.Parameters.AddWithValue("@FromUserId", fromUserId);
            command.Parameters.AddWithValue("@ToUserId", (object?)toUserId ?? DBNull.Value);
            command.Parameters.AddWithValue("@Remarks", (object?)remarks ?? DBNull.Value);
            command.Parameters.AddWithValue("@StatusName", statusName);
            await command.ExecuteNonQueryAsync();
        }

        private static PurchaseRequisitionDetails MapDetails(SqlDataReader reader)
        {
            return new PurchaseRequisitionDetails
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                PRNumber = reader.GetString(reader.GetOrdinal("PRNumber")),
                DemandRequestId = reader.IsDBNull(reader.GetOrdinal("DemandRequestId")) ? null : reader.GetInt32(reader.GetOrdinal("DemandRequestId")),
                DemandNo = reader.IsDBNull(reader.GetOrdinal("DemandNo")) ? null : reader.GetString(reader.GetOrdinal("DemandNo")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                StoreId = reader.IsDBNull(reader.GetOrdinal("StoreId")) ? null : reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                DepartmentId = reader.IsDBNull(reader.GetOrdinal("DepartmentId")) ? null : reader.GetInt32(reader.GetOrdinal("DepartmentId")),
                DepartmentName = reader.IsDBNull(reader.GetOrdinal("DepartmentName")) ? null : reader.GetString(reader.GetOrdinal("DepartmentName")),
                FinancialYearId = reader.IsDBNull(reader.GetOrdinal("FinancialYearId")) ? null : reader.GetInt32(reader.GetOrdinal("FinancialYearId")),
                FinancialYearName = reader.IsDBNull(reader.GetOrdinal("FinancialYearName")) ? null : reader.GetString(reader.GetOrdinal("FinancialYearName")),
                DistributionPlan = reader.IsDBNull(reader.GetOrdinal("DistributionPlan")) ? null : reader.GetString(reader.GetOrdinal("DistributionPlan")),
                Priority = reader.GetInt32(reader.GetOrdinal("Priority")),
                DateRequiredBy = reader.IsDBNull(reader.GetOrdinal("DateRequiredBy")) ? null : reader.GetDateTime(reader.GetOrdinal("DateRequiredBy")),
                PRType = reader.GetInt32(reader.GetOrdinal("PRType")),
                VendorId = reader.IsDBNull(reader.GetOrdinal("VendorId")) ? null : reader.GetInt32(reader.GetOrdinal("VendorId")),
                VendorName = reader.IsDBNull(reader.GetOrdinal("VendorName")) ? null : reader.GetString(reader.GetOrdinal("VendorName")),
                SuggestedProcurementMethod = reader.IsDBNull(reader.GetOrdinal("SuggestedProcurementMethod")) ? null : reader.GetString(reader.GetOrdinal("SuggestedProcurementMethod")),
                Subject = reader.IsDBNull(reader.GetOrdinal("Subject")) ? null : reader.GetString(reader.GetOrdinal("Subject")),
                ScopeOfWork = reader.IsDBNull(reader.GetOrdinal("ScopeOfWork")) ? null : reader.GetString(reader.GetOrdinal("ScopeOfWork")),
                Instructions = reader.IsDBNull(reader.GetOrdinal("Instructions")) ? null : reader.GetString(reader.GetOrdinal("Instructions")),
                Remarks = reader.IsDBNull(reader.GetOrdinal("Remarks")) ? null : reader.GetString(reader.GetOrdinal("Remarks")),
                GoodsDeliveredContactPerson = reader.IsDBNull(reader.GetOrdinal("GoodsDeliveredContactPerson")) ? null : reader.GetString(reader.GetOrdinal("GoodsDeliveredContactPerson")),
                GoodsDeliveredCellNumber = reader.IsDBNull(reader.GetOrdinal("GoodsDeliveredCellNumber")) ? null : reader.GetString(reader.GetOrdinal("GoodsDeliveredCellNumber")),
                GoodsDeliveredEmail = reader.IsDBNull(reader.GetOrdinal("GoodsDeliveredEmail")) ? null : reader.GetString(reader.GetOrdinal("GoodsDeliveredEmail")),
                GoodsDeliveredTelephone = reader.IsDBNull(reader.GetOrdinal("GoodsDeliveredTelephone")) ? null : reader.GetString(reader.GetOrdinal("GoodsDeliveredTelephone")),
                GoodsDeliveredFaxNo = reader.IsDBNull(reader.GetOrdinal("GoodsDeliveredFaxNo")) ? null : reader.GetString(reader.GetOrdinal("GoodsDeliveredFaxNo")),
                GoodsDeliveryAddress = reader.IsDBNull(reader.GetOrdinal("GoodsDeliveryAddress")) ? null : reader.GetString(reader.GetOrdinal("GoodsDeliveryAddress")),
                TermsAndConditions = reader.IsDBNull(reader.GetOrdinal("TermsAndConditions")) ? null : reader.GetString(reader.GetOrdinal("TermsAndConditions")),
                IsTechnicalReviewed = reader.GetBoolean(reader.GetOrdinal("IsTechnicalReviewed")),
                TechnicalReviewRemarks = reader.IsDBNull(reader.GetOrdinal("TechnicalReviewRemarks")) ? null : reader.GetString(reader.GetOrdinal("TechnicalReviewRemarks")),
                TotalEstimatedCost = reader.GetDecimal(reader.GetOrdinal("TotalEstimatedCost")),
                PurchaseRequisitionStatusId = reader.GetInt32(reader.GetOrdinal("PurchaseRequisitionStatusId")),
                StatusName = reader.GetString(reader.GetOrdinal("StatusName")),
                StatusCategory = reader.GetString(reader.GetOrdinal("StatusCategory")),
                AssignedToId = reader.IsDBNull(reader.GetOrdinal("AssignedToId")) ? null : reader.GetInt32(reader.GetOrdinal("AssignedToId")),
                AssignedToName = reader.IsDBNull(reader.GetOrdinal("AssignedToName")) ? null : reader.GetString(reader.GetOrdinal("AssignedToName")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn"))
            };
        }
    }
}
