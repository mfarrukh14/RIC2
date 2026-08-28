using System.Data;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Services
{
    // Unlike DemandRequestService, this service only ever targets the live HMS database -
    // there is no legacy dbo-schema fallback for Pharmacy/Patient/Account/Data tables, so
    // SQL here is written directly against their real schema-qualified names with no
    // NormalizeSql indirection.
    public class PharmacyService : IPharmacyService
    {
        private readonly string _connectionString;
        private readonly ILogger<PharmacyService> _logger;

        public PharmacyService(IConfiguration configuration, ILogger<PharmacyService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        // PharmacyChallanForms/PharmacyChallanFormDetails money columns are SQL `real`
        // (maps to .NET float), not decimal - GetDecimal throws on them, so every money
        // read goes through this helper instead.
        private static decimal ReadDecimal(SqlDataReader reader, int ordinal)
        {
            return reader.IsDBNull(ordinal) ? 0m : Convert.ToDecimal(reader.GetValue(ordinal));
        }

        public async Task<IReadOnlyList<PharmacyPatientSearchResult>> SearchPatientsAsync(string query)
        {
            var results = new List<PharmacyPatientSearchResult>();
            const string sql = @"
SELECT TOP 15 PatientID, MRNo, Name, Email, MobileNo
FROM dbo.Patients
WHERE IsActive = 1 AND ISNULL(IsDeleted, 0) = 0
  AND (MRNo LIKE '%' + @Query + '%' OR Name LIKE '%' + @Query + '%')
ORDER BY Name;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@Query", query ?? string.Empty);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                var email = reader.IsDBNull(3) ? null : reader.GetString(3);
                var mobile = reader.IsDBNull(4) ? null : reader.GetString(4);
                results.Add(new PharmacyPatientSearchResult
                {
                    PatientId = reader.GetInt32(0),
                    MRNo = reader.IsDBNull(1) ? string.Empty : reader.GetString(1),
                    Name = reader.IsDBNull(2) ? string.Empty : reader.GetString(2),
                    MaskedContact = MaskContact(email, mobile)
                });
            }

            return results;
        }

        // Legacy leaks full name+email in the search dropdown; here contact details are
        // masked before ever leaving the API instead.
        private static string? MaskContact(string? email, string? mobile)
        {
            if (!string.IsNullOrWhiteSpace(mobile))
            {
                var trimmed = mobile.Trim();
                return trimmed.Length > 4 ? new string('*', trimmed.Length - 4) + trimmed[^4..] : trimmed;
            }

            if (!string.IsNullOrWhiteSpace(email))
            {
                var at = email.IndexOf('@');
                return at > 1 ? email[0] + new string('*', at - 1) + email[at..] : email;
            }

            return null;
        }

        // Sourced from Inv.Items/Pharmacy.PharmacyMedicinesStocks - the same "Add Items"
        // master and live stock ledger used everywhere else in this app (see
        // Stock_Procedures.sql header for why it's Pharmacy.PharmacyMedicinesStocks and not
        // Inv.Stocks) - filtered to active items for the given branch, with live per-store
        // on-hand quantity. Both callers (RetailPharmacyPage dispense picker,
        // ItemWiseSalePage report filter) are outbound/consuming contexts, so items with no
        // stock at this store are excluded rather than just shown at 0 - there is nothing to
        // dispense/sell from an empty shelf. Returns the full list (no text filter) since the
        // frontend renders this as a plain dropdown, not a search box.
        public async Task<IReadOnlyList<PharmacyItemSearchResult>> GetActiveItemsAsync(int branchId, int storeId)
        {
            var results = new List<PharmacyItemSearchResult>();
            const string sql = @"
SELECT i.Id, i.Name, CAST(COALESCE(i.SalePrice, i.RetailPrice, 0) AS DECIMAL(18,2)) AS UnitPrice,
    CAST(ISNULL((SELECT SUM(s.TotalItemsInStock) FROM Pharmacy.PharmacyMedicinesStocks s WHERE s.ItemId = i.Id AND s.StoreId = @StoreId), 0) AS DECIMAL(18,2)) AS StoreStockQty
FROM Inv.Items i
WHERE i.BranchId = @BranchId AND i.IsActive = 1
    AND ISNULL((SELECT SUM(s.TotalItemsInStock) FROM Pharmacy.PharmacyMedicinesStocks s WHERE s.ItemId = i.Id AND s.StoreId = @StoreId), 0) > 0
ORDER BY i.Name;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@BranchId", branchId);
            command.Parameters.AddWithValue("@StoreId", storeId);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PharmacyItemSearchResult
                {
                    ItemId = reader.GetInt32(0),
                    ItemName = reader.IsDBNull(1) ? string.Empty : reader.GetString(1),
                    UnitPrice = reader.IsDBNull(2) ? 0 : reader.GetDecimal(2),
                    StoreStockQty = reader.IsDBNull(3) ? 0 : reader.GetDecimal(3)
                });
            }

            return results;
        }

        // Full active-doctor list for a plain dropdown, same reasoning as GetActiveItemsAsync.
        public async Task<IReadOnlyList<PharmacyDoctorSearchResult>> GetActiveDoctorsAsync()
        {
            var results = new List<PharmacyDoctorSearchResult>();
            const string sql = @"
SELECT d.DocID, e.FullName
FROM dbo.Doctors d
INNER JOIN Employee e ON e.EmpID = d.EmpID
WHERE ISNULL(d.Status, 1) = 1
ORDER BY e.FullName;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PharmacyDoctorSearchResult
                {
                    DoctorId = reader.GetInt32(0),
                    Name = reader.IsDBNull(1) ? string.Empty : reader.GetString(1)
                });
            }

            return results;
        }

        public async Task<IReadOnlyList<PharmacyPendingPrescriptionItem>> GetPendingPrescriptionsAsync(int patientId, int storeId)
        {
            var results = new List<PharmacyPendingPrescriptionItem>();
            const string sql = @"
SELECT pd.Id, pd.PatientsMedicineId, pd.PatientPharmacyId, pd.MedicineId, bm.Id AS BranchMedicineId,
    ISNULL(bm.MedicineFullName, 'Unassigned Medicine') AS MedicineName,
    pd.Quantity, pd.FrequencyNumeric,
    ISNULL((SELECT SUM(s.TotalItemsInStock) FROM Pharmacy.PharmacyMedicinesStocks s WHERE s.BranchMedicineId = bm.Id AND s.StoreId = @StoreId), 0) AS CurrentStock
FROM Patient.PatientPharmacies pp
INNER JOIN Patient.PatientPharmacyDetails pd ON pd.PatientPharmacyId = pp.Id
LEFT JOIN Pharmacy.BranchMedicines bm ON bm.MedicineId = pd.MedicineId AND bm.BranchId = pp.BranchId
WHERE pp.PatientId = @PatientId AND ISNULL(pp.Verified, 0) = 0
  AND ISNULL(pd.IsDispensed, 0) = 0 AND ISNULL(pd.IsDeleted, 0) = 0
ORDER BY pp.TimeStamp DESC;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@PatientId", patientId);
            command.Parameters.AddWithValue("@StoreId", storeId);

            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PharmacyPendingPrescriptionItem
                {
                    PatientPharmacyDetailId = reader.GetInt32(0),
                    PatientsMedicineId = reader.IsDBNull(1) ? null : reader.GetInt32(1),
                    PatientPharmacyId = reader.GetInt32(2),
                    MedicineId = reader.IsDBNull(3) ? null : reader.GetInt32(3),
                    BranchMedicineId = reader.IsDBNull(4) ? null : reader.GetInt32(4),
                    MedicineName = reader.IsDBNull(5) ? string.Empty : reader.GetString(5),
                    PrescribedQuantity = reader.IsDBNull(6) ? 0 : reader.GetInt32(6),
                    Frequency = reader.IsDBNull(7) ? null : reader.GetString(7),
                    CurrentStock = reader.IsDBNull(8) ? 0 : reader.GetDecimal(8)
                });
            }

            return results;
        }

        // Same challan-number format as the legacy system ("PH" + branch code + alpha
        // sequence + 4-digit number), generated via the already-migrated
        // Patient.GetChallanNo function against a COUNT(*)-based sequence - same pragmatic
        // (not collision-proof under heavy concurrency) approach the legacy system used,
        // acceptable at this app's scale.
        private static async Task<string> GenerateChallanNoAsync(SqlConnection connection, SqlTransaction transaction, int branchId)
        {
            const string countSql = "SELECT COUNT(*) FROM Pharmacy.PharmacyChallanForms WHERE BranchId = @BranchId;";
            using var countCommand = new SqlCommand(countSql, connection, transaction);
            countCommand.Parameters.AddWithValue("@BranchId", branchId);
            var count = Convert.ToInt32(await countCommand.ExecuteScalarAsync());

            const string fnSql = "SELECT Patient.GetChallanNo(@NumericSequence, @BranchId);";
            using var fnCommand = new SqlCommand(fnSql, connection, transaction);
            fnCommand.Parameters.AddWithValue("@NumericSequence", count);
            fnCommand.Parameters.AddWithValue("@BranchId", branchId);
            var suffix = (string)(await fnCommand.ExecuteScalarAsync())!;
            return "PH" + suffix;
        }

        // Deducts stock FIFO by batch-creation-date across Pharmacy.PharmacyMedicinesStocks
        // rows for this medicine+store (same ordering as the legacy system - by CreatedOn,
        // not by StockExpiryDate/FEFO), validating total availability across all batches
        // before touching any of them. Returns the medicine's display name for error
        // messages/logging.
        private static async Task<string> DeductStockFifoAsync(SqlConnection connection, SqlTransaction transaction, int branchMedicineId, int storeId, int quantity)
        {
            string medicineName;
            const string nameSql = "SELECT MedicineFullName FROM Pharmacy.BranchMedicines WHERE Id = @Id;";
            using (var nameCommand = new SqlCommand(nameSql, connection, transaction))
            {
                nameCommand.Parameters.AddWithValue("@Id", branchMedicineId);
                medicineName = (await nameCommand.ExecuteScalarAsync()) as string ?? "Unassigned Medicine";
            }

            const string lookupSql = @"
SELECT ID, TotalItemsInStock FROM Pharmacy.PharmacyMedicinesStocks
WHERE BranchMedicineId = @BranchMedicineId AND StoreId = @StoreId AND TotalItemsInStock > 0
ORDER BY CreatedOn ASC;";

            var batches = new List<(int Id, decimal Available)>();
            using (var lookupCommand = new SqlCommand(lookupSql, connection, transaction))
            {
                lookupCommand.Parameters.AddWithValue("@BranchMedicineId", branchMedicineId);
                lookupCommand.Parameters.AddWithValue("@StoreId", storeId);
                using var reader = await lookupCommand.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    batches.Add((reader.GetInt32(0), reader.GetDecimal(1)));
                }
            }

            var totalAvailable = batches.Sum(b => b.Available);
            if (totalAvailable < quantity)
            {
                throw new InvalidOperationException($"Cannot dispense {quantity} unit(s) of '{medicineName}' - only {totalAvailable} available in this store.");
            }

            var remaining = quantity;
            foreach (var batch in batches)
            {
                if (remaining <= 0)
                {
                    break;
                }

                var take = Math.Min(remaining, batch.Available);

                const string updateSql = @"
UPDATE Pharmacy.PharmacyMedicinesStocks
SET TotalItemsInStock = TotalItemsInStock - @Take, ModifiedOn = GETDATE()
WHERE ID = @Id;";
                using var updateCommand = new SqlCommand(updateSql, connection, transaction);
                updateCommand.Parameters.AddWithValue("@Take", take);
                updateCommand.Parameters.AddWithValue("@Id", batch.Id);
                await updateCommand.ExecuteNonQueryAsync();

                remaining -= (int)take;
            }

            return medicineName;
        }

        // Deducts stock for an ad-hoc "general item" (Inv.Items) dispense against
        // Pharmacy.PharmacyMedicinesStocks - the same live stock ledger Demand Requests/
        // GRN/etc. use (see Stock_Procedures.sql header for why it's not Inv.Stocks),
        // keeping this number consistent with what the rest of the app shows for that
        // store.
        private static async Task<string> DeductInvStockAsync(SqlConnection connection, SqlTransaction transaction, int itemId, int storeId, int quantity)
        {
            string itemName;
            const string nameSql = "SELECT Name FROM Inv.Items WHERE Id = @Id;";
            using (var nameCommand = new SqlCommand(nameSql, connection, transaction))
            {
                nameCommand.Parameters.AddWithValue("@Id", itemId);
                itemName = (await nameCommand.ExecuteScalarAsync()) as string ?? "Unassigned Item";
            }

            const string selectSql = "SELECT ISNULL(TotalItemsInStock, 0) FROM Pharmacy.PharmacyMedicinesStocks WHERE ItemId = @ItemId AND StoreId = @StoreId;";
            decimal available;
            using (var selectCommand = new SqlCommand(selectSql, connection, transaction))
            {
                selectCommand.Parameters.AddWithValue("@ItemId", itemId);
                selectCommand.Parameters.AddWithValue("@StoreId", storeId);
                var result = await selectCommand.ExecuteScalarAsync();
                available = result == null || result == DBNull.Value ? 0 : Convert.ToDecimal(result);
            }

            if (available < quantity)
            {
                throw new InvalidOperationException($"Cannot dispense {quantity} unit(s) of '{itemName}' - only {available} available in this store.");
            }

            const string updateSql = @"
UPDATE Pharmacy.PharmacyMedicinesStocks
SET TotalItemsInStock = TotalItemsInStock - @Quantity, ModifiedOn = GETDATE()
WHERE ItemId = @ItemId AND StoreId = @StoreId;";
            using var updateCommand = new SqlCommand(updateSql, connection, transaction);
            updateCommand.Parameters.AddWithValue("@Quantity", quantity);
            updateCommand.Parameters.AddWithValue("@ItemId", itemId);
            updateCommand.Parameters.AddWithValue("@StoreId", storeId);
            await updateCommand.ExecuteNonQueryAsync();

            return itemName;
        }

        public async Task<PharmacyChallanDetails> CreateOrAppendProvisionalAsync(PharmacyProvisionalDispenseRequest request, int branchId, int actingUserId)
        {
            if (request.Items == null || request.Items.Count == 0)
            {
                throw new InvalidOperationException("At least one item is required.");
            }

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();
            using var transaction = await connection.BeginTransactionAsync();

            int? challanId = null;

            try
            {
                string? challanNo = null;

                if (request.PatientId.HasValue)
                {
                    const string findSql = @"
SELECT TOP 1 f.Id, f.ChallanNo FROM Pharmacy.PharmacyChallanForms f
INNER JOIN Account.ChallanTypes ct ON ct.Id = f.ChallanTypeId AND ct.Name = 'Provisional'
WHERE f.PatientId = @PatientId AND f.StoreId = @StoreId AND f.IsFinalized = 0
ORDER BY f.Timestamp DESC;";
                    using var findCommand = new SqlCommand(findSql, connection, (SqlTransaction)transaction);
                    findCommand.Parameters.AddWithValue("@PatientId", request.PatientId.Value);
                    findCommand.Parameters.AddWithValue("@StoreId", request.StoreId);
                    using var reader = await findCommand.ExecuteReaderAsync();
                    if (await reader.ReadAsync())
                    {
                        challanId = reader.GetInt32(0);
                        challanNo = reader.IsDBNull(1) ? null : reader.GetString(1);
                    }
                }

                if (challanId == null)
                {
                    challanNo = await GenerateChallanNoAsync(connection, (SqlTransaction)transaction, branchId);

                    const string insertHeaderSql = @"
INSERT INTO Pharmacy.PharmacyChallanForms
    (PatientId, VisitNo, ChallanNo, ActionById, Timestamp, BranchId, StoreId, PrescribedInId, PrescribedById,
     ChallanTypeId, IsFinalized, IsInPatient, IsClosingPharmacyChallanFinal, Amount, Discount, Total, PaidAmount, Remaining, GrandTotal)
SELECT
    @PatientId, @VisitNo, @ChallanNo, @ActionById, SYSUTCDATETIME(), @BranchId, @StoreId, @PrescribedInId, @PrescribedById,
    ct.Id, 0, 0, 0, 0, 0, 0, 0, 0, 0
FROM Account.ChallanTypes ct WHERE ct.Name = 'Provisional';
SELECT CAST(SCOPE_IDENTITY() AS INT);";
                    using var insertCommand = new SqlCommand(insertHeaderSql, connection, (SqlTransaction)transaction);
                    insertCommand.Parameters.AddWithValue("@PatientId", (object?)request.PatientId ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@VisitNo", (object?)request.VisitNo ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@ChallanNo", challanNo!);
                    insertCommand.Parameters.AddWithValue("@ActionById", actingUserId);
                    insertCommand.Parameters.AddWithValue("@BranchId", branchId);
                    insertCommand.Parameters.AddWithValue("@StoreId", request.StoreId);
                    insertCommand.Parameters.AddWithValue("@PrescribedInId", (object?)request.PrescribedInId ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@PrescribedById", (object?)request.PrescribedById ?? DBNull.Value);
                    challanId = Convert.ToInt32(await insertCommand.ExecuteScalarAsync());
                }

                foreach (var item in request.Items)
                {
                    if (item.Quantity <= 0)
                    {
                        continue;
                    }

                    if (item.ItemId.HasValue)
                    {
                        // Ad-hoc general item (Add Items / Inv.Items) - TypeBit 15, matches
                        // the legacy "generic Item" domain, deducted from the live stock ledger.
                        await DeductInvStockAsync(connection, (SqlTransaction)transaction, item.ItemId.Value, request.StoreId, item.Quantity);

                        const string insertItemDetailSql = @"
INSERT INTO Pharmacy.PharmacyChallanFormDetails
    (PatientId, VisitNo, ChallanNo, ActionById, Timestamp, ItemId, BranchId, StoreId, PrescribedInId, PrescribedById,
     PharmacyChallanFormsId, Quantity, CustomQuantity, Total, Chargeable, IsInPatient, IsClosingPharmacyChallanFinal, TypeBit)
VALUES (@PatientId, @VisitNo, @ChallanNo, @ActionById, SYSUTCDATETIME(), @ItemId, @BranchId, @StoreId, @PrescribedInId, @PrescribedById,
    @ChallanId, @Quantity, @Quantity, @Total, 1, 0, 0, 15);";
                        using var itemDetailCommand = new SqlCommand(insertItemDetailSql, connection, (SqlTransaction)transaction);
                        itemDetailCommand.Parameters.AddWithValue("@PatientId", (object?)request.PatientId ?? DBNull.Value);
                        itemDetailCommand.Parameters.AddWithValue("@VisitNo", (object?)request.VisitNo ?? DBNull.Value);
                        itemDetailCommand.Parameters.AddWithValue("@ChallanNo", challanNo!);
                        itemDetailCommand.Parameters.AddWithValue("@ActionById", actingUserId);
                        itemDetailCommand.Parameters.AddWithValue("@ItemId", item.ItemId.Value);
                        itemDetailCommand.Parameters.AddWithValue("@BranchId", branchId);
                        itemDetailCommand.Parameters.AddWithValue("@StoreId", request.StoreId);
                        itemDetailCommand.Parameters.AddWithValue("@PrescribedInId", (object?)request.PrescribedInId ?? DBNull.Value);
                        itemDetailCommand.Parameters.AddWithValue("@PrescribedById", (object?)request.PrescribedById ?? DBNull.Value);
                        itemDetailCommand.Parameters.AddWithValue("@ChallanId", challanId.Value);
                        itemDetailCommand.Parameters.AddWithValue("@Quantity", item.Quantity);
                        itemDetailCommand.Parameters.AddWithValue("@Total", item.Quantity * item.UnitPrice);
                        await itemDetailCommand.ExecuteNonQueryAsync();
                        continue;
                    }

                    if (!item.BranchMedicineId.HasValue)
                    {
                        throw new InvalidOperationException("Each item must specify either ItemId or BranchMedicineId.");
                    }

                    await DeductStockFifoAsync(connection, (SqlTransaction)transaction, item.BranchMedicineId.Value, request.StoreId, item.Quantity);

                    const string insertDetailSql = @"
INSERT INTO Pharmacy.PharmacyChallanFormDetails
    (PatientId, VisitNo, ChallanNo, ActionById, Timestamp, MedicineId, BranchId, StoreId, PrescribedInId, PrescribedById,
     PharmacyChallanFormsId, Quantity, CustomQuantity, Total, Chargeable, IsInPatient, IsClosingPharmacyChallanFinal, TypeBit)
SELECT @PatientId, @VisitNo, @ChallanNo, @ActionById, SYSUTCDATETIME(), bm.MedicineId, @BranchId, @StoreId, @PrescribedInId, @PrescribedById,
    @ChallanId, @Quantity, @Quantity, @Total, 1, 0, 0, 4
FROM Pharmacy.BranchMedicines bm WHERE bm.Id = @BranchMedicineId;";
                    using var detailCommand = new SqlCommand(insertDetailSql, connection, (SqlTransaction)transaction);
                    detailCommand.Parameters.AddWithValue("@PatientId", (object?)request.PatientId ?? DBNull.Value);
                    detailCommand.Parameters.AddWithValue("@VisitNo", (object?)request.VisitNo ?? DBNull.Value);
                    detailCommand.Parameters.AddWithValue("@ChallanNo", challanNo!);
                    detailCommand.Parameters.AddWithValue("@ActionById", actingUserId);
                    detailCommand.Parameters.AddWithValue("@BranchId", branchId);
                    detailCommand.Parameters.AddWithValue("@StoreId", request.StoreId);
                    detailCommand.Parameters.AddWithValue("@PrescribedInId", (object?)request.PrescribedInId ?? DBNull.Value);
                    detailCommand.Parameters.AddWithValue("@PrescribedById", (object?)request.PrescribedById ?? DBNull.Value);
                    detailCommand.Parameters.AddWithValue("@ChallanId", challanId.Value);
                    detailCommand.Parameters.AddWithValue("@Quantity", item.Quantity);
                    detailCommand.Parameters.AddWithValue("@Total", item.Quantity * item.UnitPrice);
                    detailCommand.Parameters.AddWithValue("@BranchMedicineId", item.BranchMedicineId.Value);
                    await detailCommand.ExecuteNonQueryAsync();
                }

                const string rollupSql = @"
UPDATE Pharmacy.PharmacyChallanForms
SET Amount = ISNULL((SELECT SUM(Total) FROM Pharmacy.PharmacyChallanFormDetails WHERE PharmacyChallanFormsId = @ChallanId), 0),
    Total = ISNULL((SELECT SUM(Total) FROM Pharmacy.PharmacyChallanFormDetails WHERE PharmacyChallanFormsId = @ChallanId), 0),
    GrandTotal = ISNULL((SELECT SUM(Total) FROM Pharmacy.PharmacyChallanFormDetails WHERE PharmacyChallanFormsId = @ChallanId), 0)
WHERE Id = @ChallanId;";
                using (var rollupCommand = new SqlCommand(rollupSql, connection, (SqlTransaction)transaction))
                {
                    rollupCommand.Parameters.AddWithValue("@ChallanId", challanId.Value);
                    await rollupCommand.ExecuteNonQueryAsync();
                }

                await transaction.CommitAsync();
            }
            catch (InvalidOperationException)
            {
                await transaction.RollbackAsync();
                throw;
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "Error adding items to pharmacy provisional basket");
                throw;
            }

            // Outside the try/catch above on purpose - the transaction is already
            // committed at this point, so a failure here must not attempt a rollback
            // against it (SqlTransaction throws "already completed" if you do).
            return await GetChallanByIdAsync(challanId.Value) ?? throw new InvalidOperationException("Failed to load the basket after saving.");
        }

        public async Task<PharmacyChallanDetails> FinalizeDispenseAsync(int provisionalChallanId, PharmacyFinalizeDispenseRequest request, int actingUserId)
        {
            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();
            using var transaction = await connection.BeginTransactionAsync();

            int finalChallanId;

            try
            {
                int? patientId;
                string? visitNo;
                int branchId;
                int storeId;
                int? prescribedInId;
                int? prescribedById;
                bool isFinalized;
                string? currentChallanTypeName;
                decimal amount;

                const string headerSql = @"
SELECT f.PatientId, f.VisitNo, f.BranchId, f.StoreId, f.PrescribedInId, f.PrescribedById, f.IsFinalized, ct.Name, f.Amount
FROM Pharmacy.PharmacyChallanForms f
LEFT JOIN Account.ChallanTypes ct ON ct.Id = f.ChallanTypeId
WHERE f.Id = @Id;";
                using (var headerCommand = new SqlCommand(headerSql, connection, (SqlTransaction)transaction))
                {
                    headerCommand.Parameters.AddWithValue("@Id", provisionalChallanId);
                    using var reader = await headerCommand.ExecuteReaderAsync();
                    if (!await reader.ReadAsync())
                    {
                        await transaction.RollbackAsync();
                        throw new InvalidOperationException("Basket not found.");
                    }

                    patientId = reader.IsDBNull(0) ? null : reader.GetInt32(0);
                    visitNo = reader.IsDBNull(1) ? null : reader.GetString(1);
                    branchId = reader.GetInt32(2);
                    storeId = reader.GetInt32(3);
                    prescribedInId = reader.IsDBNull(4) ? null : reader.GetInt32(4);
                    prescribedById = reader.IsDBNull(5) ? null : reader.GetInt32(5);
                    isFinalized = reader.GetBoolean(6);
                    currentChallanTypeName = reader.IsDBNull(7) ? null : reader.GetString(7);
                    amount = ReadDecimal(reader, 8);
                }

                if (isFinalized || !string.Equals(currentChallanTypeName, "Provisional", StringComparison.OrdinalIgnoreCase))
                {
                    await transaction.RollbackAsync();
                    throw new InvalidOperationException("This basket has already been finalized or is not a valid provisional basket.");
                }

                if (amount <= 0)
                {
                    await transaction.RollbackAsync();
                    throw new InvalidOperationException("This basket has no items to dispense.");
                }

                var discount = request.DiscountType == 2
                    ? Math.Round(amount * request.DiscountAmount / 100m, 2)
                    : request.DiscountType == 1 ? request.DiscountAmount : 0m;
                if (discount > amount)
                {
                    discount = amount;
                }

                var total = amount - discount;
                var change = request.PaidAmount > total ? request.PaidAmount - total : 0;
                var remaining = total > request.PaidAmount ? total - request.PaidAmount : 0;

                var challanNo = await GenerateChallanNoAsync(connection, (SqlTransaction)transaction, branchId);

                const string insertFinalHeaderSql = @"
INSERT INTO Pharmacy.PharmacyChallanForms
    (PatientId, VisitNo, ChallanNo, ActionById, Timestamp, BranchId, StoreId, PrescribedInId, PrescribedById,
     ChallanTypeId, IsFinalized, IsInPatient, IsClosingPharmacyChallanFinal, Amount, Discount, DiscountType, Total, PaidAmount,
     Remaining, GrandTotal, Change, PaymentTypeId, ClosingPharmacyChallanId)
SELECT
    @PatientId, @VisitNo, @ChallanNo, @ActionById, SYSUTCDATETIME(), @BranchId, @StoreId, @PrescribedInId, @PrescribedById,
    ct.Id, 1, 0, 0, @Amount, @Discount, @DiscountType, @Total, @PaidAmount, @Remaining, @Total, @Change, @PaymentTypeId, @ProvisionalId
FROM Account.ChallanTypes ct WHERE ct.Name = 'Final';
SELECT CAST(SCOPE_IDENTITY() AS INT);";
                using (var insertCommand = new SqlCommand(insertFinalHeaderSql, connection, (SqlTransaction)transaction))
                {
                    insertCommand.Parameters.AddWithValue("@PatientId", (object?)patientId ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@VisitNo", (object?)visitNo ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@ChallanNo", challanNo);
                    insertCommand.Parameters.AddWithValue("@ActionById", actingUserId);
                    insertCommand.Parameters.AddWithValue("@BranchId", branchId);
                    insertCommand.Parameters.AddWithValue("@StoreId", storeId);
                    insertCommand.Parameters.AddWithValue("@PrescribedInId", (object?)prescribedInId ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@PrescribedById", (object?)prescribedById ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@Amount", amount);
                    insertCommand.Parameters.AddWithValue("@Discount", discount);
                    insertCommand.Parameters.AddWithValue("@DiscountType", (object?)request.DiscountType ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@Total", total);
                    insertCommand.Parameters.AddWithValue("@PaidAmount", request.PaidAmount);
                    insertCommand.Parameters.AddWithValue("@Remaining", remaining);
                    insertCommand.Parameters.AddWithValue("@Change", change);
                    insertCommand.Parameters.AddWithValue("@PaymentTypeId", (object?)request.PaymentTypeId ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@ProvisionalId", provisionalChallanId);
                    finalChallanId = Convert.ToInt32(await insertCommand.ExecuteScalarAsync());
                }

                const string copyDetailsSql = @"
INSERT INTO Pharmacy.PharmacyChallanFormDetails
    (PatientId, VisitNo, ChallanNo, ActionById, Timestamp, MedicineId, ItemId, BranchId, StoreId, PrescribedInId, PrescribedById,
     PharmacyChallanFormsId, Quantity, CustomQuantity, Total, Chargeable, IsInPatient, IsClosingPharmacyChallanFinal, TypeBit)
SELECT PatientId, VisitNo, @NewChallanNo, ActionById, SYSUTCDATETIME(), MedicineId, ItemId, BranchId, StoreId, PrescribedInId, PrescribedById,
    @FinalChallanId, Quantity, CustomQuantity, Total, Chargeable, IsInPatient, 0, TypeBit
FROM Pharmacy.PharmacyChallanFormDetails
WHERE PharmacyChallanFormsId = @ProvisionalId;";
                using (var copyCommand = new SqlCommand(copyDetailsSql, connection, (SqlTransaction)transaction))
                {
                    copyCommand.Parameters.AddWithValue("@NewChallanNo", challanNo);
                    copyCommand.Parameters.AddWithValue("@FinalChallanId", finalChallanId);
                    copyCommand.Parameters.AddWithValue("@ProvisionalId", provisionalChallanId);
                    await copyCommand.ExecuteNonQueryAsync();
                }

                const string closeProvisionalSql = @"
UPDATE Pharmacy.PharmacyChallanForms
SET IsFinalized = 1, ClosingPharmacyFinalChallanId = @FinalChallanId, ClosingPharmacyFinalChallanNo = @NewChallanNo, IsClosingPharmacyChallanFinal = 1
WHERE Id = @ProvisionalId;
UPDATE Pharmacy.PharmacyChallanFormDetails
SET ClosingPharmacyFinalChallanId = @FinalChallanId, ClosingPharmacyFinalChallanNo = @NewChallanNo, IsClosingPharmacyChallanFinal = 1
WHERE PharmacyChallanFormsId = @ProvisionalId;";
                using (var closeCommand = new SqlCommand(closeProvisionalSql, connection, (SqlTransaction)transaction))
                {
                    closeCommand.Parameters.AddWithValue("@FinalChallanId", finalChallanId);
                    closeCommand.Parameters.AddWithValue("@NewChallanNo", challanNo);
                    closeCommand.Parameters.AddWithValue("@ProvisionalId", provisionalChallanId);
                    await closeCommand.ExecuteNonQueryAsync();
                }

                // Closes out the source prescription rows (matched by medicine, within this
                // patient's pending items) - a simplification vs. legacy's exact per-row
                // linkage, acceptable since a patient rarely has two pending prescriptions
                // of the same medicine open at once.
                if (patientId.HasValue)
                {
                    const string closePharmacySql = @"
UPDATE Patient.PatientPharmacies SET Verified = 1 WHERE Id IN (
    SELECT DISTINCT pd.PatientPharmacyId FROM Patient.PatientPharmacyDetails pd
    INNER JOIN Pharmacy.PharmacyChallanFormDetails d ON d.MedicineId = pd.MedicineId AND d.PharmacyChallanFormsId = @ProvisionalId
    WHERE pd.PatientId = @PatientId AND ISNULL(pd.IsDispensed, 0) = 0
);
UPDATE pd SET pd.IsDispensed = 1
FROM Patient.PatientPharmacyDetails pd
INNER JOIN Pharmacy.PharmacyChallanFormDetails d ON d.MedicineId = pd.MedicineId AND d.PharmacyChallanFormsId = @ProvisionalId
WHERE pd.PatientId = @PatientId AND ISNULL(pd.IsDispensed, 0) = 0;
UPDATE pm SET pm.RevisedQuantity = d.Quantity, pm.IsNotDispensed = 0
FROM Patient.PatientsMedicines pm
INNER JOIN Pharmacy.PharmacyChallanFormDetails d ON d.MedicineId = pm.MedicineId AND d.PharmacyChallanFormsId = @ProvisionalId
WHERE pm.PatientId = @PatientId AND ISNULL(pm.IsNotDispensed, 1) = 1;";
                    using var closePharmacyCommand = new SqlCommand(closePharmacySql, connection, (SqlTransaction)transaction);
                    closePharmacyCommand.Parameters.AddWithValue("@ProvisionalId", provisionalChallanId);
                    closePharmacyCommand.Parameters.AddWithValue("@PatientId", patientId.Value);
                    await closePharmacyCommand.ExecuteNonQueryAsync();
                }

                await transaction.CommitAsync();
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "Error finalizing pharmacy dispense for provisional challan {ProvisionalChallanId}", provisionalChallanId);
                throw;
            }

            // Outside the try/catch above on purpose - see the equivalent comment in
            // CreateOrAppendProvisionalAsync.
            return await GetChallanByIdAsync(finalChallanId) ?? throw new InvalidOperationException("Failed to load the finalized challan.");
        }

        public async Task<PharmacyChallanDetails?> GetChallanByIdAsync(int id)
        {
            const string headerSql = @"
SELECT f.Id, f.ChallanNo, ISNULL(ct.Name, '') AS ChallanType, f.IsFinalized, f.PatientId, p.Name AS PatientName,
    f.VisitNo, f.StoreId, s.StoreName, f.Timestamp, f.Amount, f.Discount, f.DiscountType, f.Total, f.PaidAmount,
    f.Remaining, f.Change, f.PaymentTypeId, pt.Name AS PaymentTypeName
FROM Pharmacy.PharmacyChallanForms f
LEFT JOIN Account.ChallanTypes ct ON ct.Id = f.ChallanTypeId
LEFT JOIN dbo.Patients p ON p.PatientID = f.PatientId
LEFT JOIN Inv.PharmacyStores s ON s.StoreId = f.StoreId
LEFT JOIN Account.PaymentTypes pt ON pt.PaymentTypeId = f.PaymentTypeId
WHERE f.Id = @Id;";

            const string itemsSql = @"
SELECT d.Id, d.MedicineId, COALESCE(m.MedicineFullName, ii.Name, 'Unassigned') AS MedicineName, d.Quantity, d.Total
FROM Pharmacy.PharmacyChallanFormDetails d
LEFT JOIN Pharmacy.Medicines m ON m.MedicineId = d.MedicineId
LEFT JOIN Inv.Items ii ON ii.Id = d.ItemId
WHERE d.PharmacyChallanFormsId = @Id
ORDER BY d.Id;";

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            PharmacyChallanDetails? details = null;
            using (var headerCommand = new SqlCommand(headerSql, connection))
            {
                headerCommand.Parameters.AddWithValue("@Id", id);
                using var reader = await headerCommand.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    details = new PharmacyChallanDetails
                    {
                        Id = reader.GetInt32(0),
                        ChallanNo = reader.IsDBNull(1) ? null : reader.GetString(1),
                        ChallanType = reader.IsDBNull(2) ? string.Empty : reader.GetString(2),
                        IsFinalized = reader.GetBoolean(3),
                        PatientId = reader.IsDBNull(4) ? null : reader.GetInt32(4),
                        PatientName = reader.IsDBNull(5) ? null : reader.GetString(5),
                        VisitNo = reader.IsDBNull(6) ? null : reader.GetString(6),
                        StoreId = reader.IsDBNull(7) ? null : reader.GetInt32(7),
                        StoreName = reader.IsDBNull(8) ? null : reader.GetString(8),
                        Timestamp = reader.GetDateTime(9),
                        Amount = ReadDecimal(reader, 10),
                        Discount = ReadDecimal(reader, 11),
                        DiscountType = reader.IsDBNull(12) ? null : reader.GetInt32(12),
                        Total = ReadDecimal(reader, 13),
                        PaidAmount = ReadDecimal(reader, 14),
                        Remaining = ReadDecimal(reader, 15),
                        Change = ReadDecimal(reader, 16),
                        PaymentTypeId = reader.IsDBNull(17) ? null : reader.GetInt32(17),
                        PaymentTypeName = reader.IsDBNull(18) ? null : reader.GetString(18)
                    };
                }
            }

            if (details == null)
            {
                return null;
            }

            using (var itemsCommand = new SqlCommand(itemsSql, connection))
            {
                itemsCommand.Parameters.AddWithValue("@Id", id);
                using var reader = await itemsCommand.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    details.Items.Add(new PharmacyChallanItem
                    {
                        Id = reader.GetInt32(0),
                        BranchMedicineId = reader.IsDBNull(1) ? null : reader.GetInt32(1),
                        MedicineName = reader.IsDBNull(2) ? "Unassigned Medicine" : reader.GetString(2),
                        Quantity = reader.IsDBNull(3) ? 0 : reader.GetInt32(3),
                        Total = ReadDecimal(reader, 4)
                    });
                }
            }

            return details;
        }

        public async Task<PharmacyLookups> GetLookupsAsync(int branchId)
        {
            var stores = new List<PharmacyLookupItem>();
            var paymentTypes = new List<PharmacyLookupItem>();
            var prescribedIns = new List<PharmacyLookupItem>();

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            const string storesSql = "SELECT StoreId, StoreName FROM Inv.PharmacyStores WHERE BranchId = @BranchId AND IsActive = 1 ORDER BY StoreName;";
            using (var command = new SqlCommand(storesSql, connection))
            {
                command.Parameters.AddWithValue("@BranchId", branchId);
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    stores.Add(new PharmacyLookupItem { Id = reader.GetInt32(0), Name = reader.IsDBNull(1) ? string.Empty : reader.GetString(1) });
                }
            }

            const string paymentTypesSql = "SELECT PaymentTypeId, Name FROM Account.PaymentTypes WHERE ISNULL(IsActive, 1) = 1 AND ISNULL(IsDeleted, 0) = 0 ORDER BY Name;";
            using (var command = new SqlCommand(paymentTypesSql, connection))
            {
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    paymentTypes.Add(new PharmacyLookupItem { Id = reader.GetInt32(0), Name = reader.IsDBNull(1) ? string.Empty : reader.GetString(1) });
                }
            }

            const string prescribedInsSql = "SELECT PrescribedInId, Name FROM Data.PrescribedIns ORDER BY Name;";
            using (var command = new SqlCommand(prescribedInsSql, connection))
            {
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    prescribedIns.Add(new PharmacyLookupItem { Id = reader.GetInt32(0), Name = reader.IsDBNull(1) ? string.Empty : reader.GetString(1) });
                }
            }

            return new PharmacyLookups { Stores = stores, PaymentTypes = paymentTypes, PrescribedIns = prescribedIns };
        }

        // ==================== Pharmacy Department Store ====================

        public async Task<IReadOnlyList<PharmacyDepartmentStoreMapping>> GetDepartmentStoreMappingsAsync()
        {
            var results = new List<PharmacyDepartmentStoreMapping>();
            const string sql = @"
SELECT psd.Id, psd.BranchDepartmentId, ISNULL(bd.Name, 'Unassigned') AS DepartmentName, psd.PharmacyStoreId, ISNULL(s.StoreName, 'Unassigned') AS StoreName, psd.ModifiedOn
FROM Pharmacy.PharmacyStoreDepartments psd
LEFT JOIN Data.BranchDepartments bd ON bd.BranchDepartmentId = psd.BranchDepartmentId
LEFT JOIN Inv.PharmacyStores s ON s.StoreId = psd.PharmacyStoreId
ORDER BY DepartmentName;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PharmacyDepartmentStoreMapping
                {
                    Id = reader.GetInt32(0),
                    BranchDepartmentId = reader.GetInt32(1),
                    DepartmentName = reader.GetString(2),
                    PharmacyStoreId = reader.GetInt32(3),
                    StoreName = reader.GetString(4),
                    ModifiedOn = reader.IsDBNull(5) ? null : reader.GetDateTime(5)
                });
            }

            return results;
        }

        public async Task<IReadOnlyList<PharmacyLookupItem>> GetBranchDepartmentsAsync(int branchId)
        {
            var results = new List<PharmacyLookupItem>();
            const string sql = "SELECT BranchDepartmentId, Name FROM Data.BranchDepartments WHERE BranchId = @BranchId AND IsActive = 1 ORDER BY Name;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@BranchId", branchId);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PharmacyLookupItem { Id = reader.GetInt32(0), Name = reader.IsDBNull(1) ? string.Empty : reader.GetString(1) });
            }

            return results;
        }

        public async Task<PharmacyDepartmentStoreMapping> CreateDepartmentStoreMappingAsync(PharmacyDepartmentStoreMappingRequest request)
        {
            const string sql = @"
INSERT INTO Pharmacy.PharmacyStoreDepartments (BranchDepartmentId, PharmacyStoreId, CreatedOn, ModifiedOn)
VALUES (@BranchDepartmentId, @PharmacyStoreId, GETDATE(), GETDATE());
SELECT CAST(SCOPE_IDENTITY() AS INT);";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@BranchDepartmentId", request.BranchDepartmentId);
            command.Parameters.AddWithValue("@PharmacyStoreId", request.PharmacyStoreId);
            await connection.OpenAsync();
            var id = Convert.ToInt32(await command.ExecuteScalarAsync());

            var mappings = await GetDepartmentStoreMappingsAsync();
            return mappings.First(m => m.Id == id);
        }

        public async Task<PharmacyDepartmentStoreMapping?> UpdateDepartmentStoreMappingAsync(int id, PharmacyDepartmentStoreMappingRequest request)
        {
            const string sql = @"
UPDATE Pharmacy.PharmacyStoreDepartments
SET BranchDepartmentId = @BranchDepartmentId, PharmacyStoreId = @PharmacyStoreId, ModifiedOn = GETDATE()
WHERE Id = @Id;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@Id", id);
            command.Parameters.AddWithValue("@BranchDepartmentId", request.BranchDepartmentId);
            command.Parameters.AddWithValue("@PharmacyStoreId", request.PharmacyStoreId);
            await connection.OpenAsync();
            var rowsAffected = await command.ExecuteNonQueryAsync();

            if (rowsAffected == 0)
            {
                return null;
            }

            var mappings = await GetDepartmentStoreMappingsAsync();
            return mappings.FirstOrDefault(m => m.Id == id);
        }

        // Hard delete, regardless of any active flag - matches this app's established
        // convention (see the demand-request/hard-delete work) that GetAll/GetById never
        // hide inactive rows and delete means delete.
        public async Task<bool> DeleteDepartmentStoreMappingAsync(int id)
        {
            const string sql = "DELETE FROM Pharmacy.PharmacyStoreDepartments WHERE Id = @Id;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@Id", id);
            await connection.OpenAsync();
            var rowsAffected = await command.ExecuteNonQueryAsync();
            return rowsAffected > 0;
        }

        // ==================== Refund Medicine ====================

        public async Task<IReadOnlyList<PharmacyRefundLineItem>> GetRefundableLinesAsync(int storeId, string challanNo)
        {
            var results = new List<PharmacyRefundLineItem>();
            const string sql = @"
SELECT d.Id, COALESCE(m.MedicineFullName, ii.Name, 'Unassigned') AS MedicineName,
    CASE WHEN d.Quantity <> 0 THEN d.Total / d.Quantity ELSE 0 END AS Rate,
    d.Quantity AS IssuedQuantity,
    ISNULL((SELECT SUM(-r.Quantity) FROM Pharmacy.PharmacyChallanFormDetails r WHERE r.RefundingChallanIdForDetail = d.Id), 0) AS AlreadyRefundedQuantity
FROM Pharmacy.PharmacyChallanFormDetails d
INNER JOIN Pharmacy.PharmacyChallanForms f ON f.Id = d.PharmacyChallanFormsId
LEFT JOIN Pharmacy.Medicines m ON m.MedicineId = d.MedicineId
LEFT JOIN Inv.Items ii ON ii.Id = d.ItemId
WHERE f.StoreId = @StoreId AND f.ChallanNo = @ChallanNo AND f.IsFinalized = 1 AND d.Quantity > 0
ORDER BY d.Id;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@StoreId", storeId);
            command.Parameters.AddWithValue("@ChallanNo", challanNo);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                var issued = reader.GetInt32(3);
                var refunded = reader.GetInt32(4);
                results.Add(new PharmacyRefundLineItem
                {
                    ChallanFormDetailId = reader.GetInt32(0),
                    MedicineName = reader.IsDBNull(1) ? string.Empty : reader.GetString(1),
                    Rate = ReadDecimal(reader, 2),
                    IssuedQuantity = issued,
                    AlreadyRefundedQuantity = refunded,
                    RefundableQuantity = Math.Max(0, issued - refunded)
                });
            }

            return results;
        }

        // Credits refunded quantity back to Pharmacy.PharmacyMedicinesStocks (the live
        // ledger - see Stock_Procedures.sql header for why it's not Inv.Stocks) - same
        // upsert idiom as AddStockAsync in DemandRequestService. No BranchId column on this
        // table; @branchId is accepted for call-site compatibility but not written anywhere.
        private static async Task AddInvStockAsync(SqlConnection connection, SqlTransaction transaction, int itemId, int storeId, int branchId, int quantity)
        {
            const string upsertSql = @"
IF EXISTS (SELECT 1 FROM Pharmacy.PharmacyMedicinesStocks WHERE ItemId = @ItemId AND StoreId = @StoreId)
    UPDATE Pharmacy.PharmacyMedicinesStocks SET TotalItemsInStock = TotalItemsInStock + @Quantity, ModifiedOn = GETDATE()
    WHERE ItemId = @ItemId AND StoreId = @StoreId;
ELSE
    INSERT INTO Pharmacy.PharmacyMedicinesStocks (ItemId, TotalItemsInStock, MinimumPanicLevel, TotalItemsInTransition, TypeBit, StoreId, CreatedBy, CreatedOn)
    VALUES (@ItemId, @Quantity, 0, 0, 15, @StoreId, 1, GETDATE());";
            using var command = new SqlCommand(upsertSql, connection, transaction);
            command.Parameters.AddWithValue("@ItemId", itemId);
            command.Parameters.AddWithValue("@StoreId", storeId);
            command.Parameters.AddWithValue("@BranchId", branchId);
            command.Parameters.AddWithValue("@Quantity", quantity);
            await command.ExecuteNonQueryAsync();
        }

        // Credits refunded quantity back to Pharmacy.PharmacyMedicinesStocks. The
        // simplified challan-detail model here (one summed row per item, unlike legacy's
        // per-batch rows) doesn't retain which exact batch a sale was fulfilled from, so
        // the credit goes to the most-recently-created existing batch for this
        // medicine+store (or a new generic batch if none exists) rather than the precise
        // original lot - a documented simplification, not a precision guarantee.
        private static async Task AddPharmacyStockBackAsync(SqlConnection connection, SqlTransaction transaction, int medicineId, int storeId, int quantity)
        {
            int? branchMedicineId;
            using (var lookupCommand = new SqlCommand(
                "SELECT TOP 1 Id FROM Pharmacy.BranchMedicines WHERE MedicineId = @MedicineId;", connection, transaction))
            {
                lookupCommand.Parameters.AddWithValue("@MedicineId", medicineId);
                var result = await lookupCommand.ExecuteScalarAsync();
                branchMedicineId = result == null || result == DBNull.Value ? null : Convert.ToInt32(result);
            }

            if (!branchMedicineId.HasValue)
            {
                return;
            }

            const string upsertSql = @"
IF EXISTS (SELECT TOP 1 1 FROM Pharmacy.PharmacyMedicinesStocks WHERE BranchMedicineId = @BranchMedicineId AND StoreId = @StoreId)
    UPDATE Pharmacy.PharmacyMedicinesStocks
    SET TotalItemsInStock = TotalItemsInStock + @Quantity, ModifiedOn = GETDATE()
    WHERE ID = (SELECT TOP 1 ID FROM Pharmacy.PharmacyMedicinesStocks WHERE BranchMedicineId = @BranchMedicineId AND StoreId = @StoreId ORDER BY CreatedOn DESC);
ELSE
    INSERT INTO Pharmacy.PharmacyMedicinesStocks (StoreId, BranchMedicineId, TotalItemsInStock, MinimumPanicLevel, TypeBit, CreatedBy, CreatedOn, StockTypeId, TotalItemsInTransition)
    VALUES (@StoreId, @BranchMedicineId, @Quantity, 0, 15, 1, GETDATE(), 1, 0);";
            using var upsertCommand = new SqlCommand(upsertSql, connection, transaction);
            upsertCommand.Parameters.AddWithValue("@BranchMedicineId", branchMedicineId.Value);
            upsertCommand.Parameters.AddWithValue("@StoreId", storeId);
            upsertCommand.Parameters.AddWithValue("@Quantity", quantity);
            await upsertCommand.ExecuteNonQueryAsync();
        }

        public async Task<PharmacyChallanDetails> ProcessRefundAsync(PharmacyRefundRequest request, int actingUserId)
        {
            if (request.Items == null || request.Items.Count == 0)
            {
                throw new InvalidOperationException("At least one item is required to process a refund.");
            }

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();
            using var transaction = await connection.BeginTransactionAsync();

            int refundChallanId;

            try
            {
                int originalChallanFormsId;
                int? patientId;
                string? visitNo;
                int branchId;

                const string headerSql = @"
SELECT f.Id, f.PatientId, f.VisitNo, f.BranchId
FROM Pharmacy.PharmacyChallanForms f
WHERE f.StoreId = @StoreId AND f.ChallanNo = @ChallanNo AND f.IsFinalized = 1;";
                using (var headerCommand = new SqlCommand(headerSql, connection, (SqlTransaction)transaction))
                {
                    headerCommand.Parameters.AddWithValue("@StoreId", request.StoreId);
                    headerCommand.Parameters.AddWithValue("@ChallanNo", request.ChallanNo);
                    using var reader = await headerCommand.ExecuteReaderAsync();
                    if (!await reader.ReadAsync())
                    {
                        await transaction.RollbackAsync();
                        throw new InvalidOperationException("Challan not found for this store.");
                    }

                    originalChallanFormsId = reader.GetInt32(0);
                    patientId = reader.IsDBNull(1) ? null : reader.GetInt32(1);
                    visitNo = reader.IsDBNull(2) ? null : reader.GetString(2);
                    branchId = reader.GetInt32(3);
                }

                var refundChallanNo = await GenerateChallanNoAsync(connection, (SqlTransaction)transaction, branchId);

                const string insertHeaderSql = @"
INSERT INTO Pharmacy.PharmacyChallanForms
    (PatientId, VisitNo, ChallanNo, ActionById, Timestamp, BranchId, StoreId, ChallanTypeId, IsFinalized, IsInPatient,
     IsClosingPharmacyChallanFinal, Amount, Discount, Total, PaidAmount, Remaining, GrandTotal, RefundingChallanNo, RefundingChallanId)
SELECT
    @PatientId, @VisitNo, @ChallanNo, @ActionById, SYSUTCDATETIME(), @BranchId, @StoreId, ct.Id, 1, 0, 0,
    0, 0, 0, 0, 0, 0, @OriginalChallanNo, @OriginalChallanId
FROM Account.ChallanTypes ct WHERE ct.Name = 'Refund';
SELECT CAST(SCOPE_IDENTITY() AS INT);";
                using (var insertCommand = new SqlCommand(insertHeaderSql, connection, (SqlTransaction)transaction))
                {
                    insertCommand.Parameters.AddWithValue("@PatientId", (object?)patientId ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@VisitNo", (object?)visitNo ?? DBNull.Value);
                    insertCommand.Parameters.AddWithValue("@ChallanNo", refundChallanNo);
                    insertCommand.Parameters.AddWithValue("@ActionById", actingUserId);
                    insertCommand.Parameters.AddWithValue("@BranchId", branchId);
                    insertCommand.Parameters.AddWithValue("@StoreId", request.StoreId);
                    insertCommand.Parameters.AddWithValue("@OriginalChallanNo", request.ChallanNo);
                    insertCommand.Parameters.AddWithValue("@OriginalChallanId", originalChallanFormsId);
                    refundChallanId = Convert.ToInt32(await insertCommand.ExecuteScalarAsync());
                }

                var totalRefunded = 0m;

                foreach (var refundItem in request.Items)
                {
                    if (refundItem.RefundQuantity <= 0)
                    {
                        continue;
                    }

                    int? medicineId;
                    int? itemId;
                    int originalQuantity;
                    decimal originalTotal;
                    using (var lineCommand = new SqlCommand(
                        "SELECT MedicineId, ItemId, Quantity, Total FROM Pharmacy.PharmacyChallanFormDetails WHERE Id = @Id;",
                        connection, (SqlTransaction)transaction))
                    {
                        lineCommand.Parameters.AddWithValue("@Id", refundItem.ChallanFormDetailId);
                        using var reader = await lineCommand.ExecuteReaderAsync();
                        if (!await reader.ReadAsync())
                        {
                            await transaction.RollbackAsync();
                            throw new InvalidOperationException("One of the selected lines could not be found.");
                        }

                        medicineId = reader.IsDBNull(0) ? null : reader.GetInt32(0);
                        itemId = reader.IsDBNull(1) ? null : reader.GetInt32(1);
                        originalQuantity = reader.GetInt32(2);
                        originalTotal = ReadDecimal(reader, 3);
                    }

                    int alreadyRefunded;
                    using (var refundedCommand = new SqlCommand(
                        "SELECT ISNULL(SUM(-Quantity), 0) FROM Pharmacy.PharmacyChallanFormDetails WHERE RefundingChallanIdForDetail = @Id;",
                        connection, (SqlTransaction)transaction))
                    {
                        refundedCommand.Parameters.AddWithValue("@Id", refundItem.ChallanFormDetailId);
                        alreadyRefunded = Convert.ToInt32(await refundedCommand.ExecuteScalarAsync());
                    }

                    var refundable = Math.Max(0, originalQuantity - alreadyRefunded);
                    if (refundItem.RefundQuantity > refundable)
                    {
                        await transaction.RollbackAsync();
                        throw new InvalidOperationException($"Cannot refund {refundItem.RefundQuantity} unit(s) - only {refundable} still refundable for this line.");
                    }

                    var unitPrice = originalQuantity != 0 ? originalTotal / originalQuantity : 0;
                    var refundTotal = unitPrice * refundItem.RefundQuantity;
                    totalRefunded += refundTotal;

                    if (itemId.HasValue)
                    {
                        await AddInvStockAsync(connection, (SqlTransaction)transaction, itemId.Value, request.StoreId, branchId, refundItem.RefundQuantity);
                    }
                    else if (medicineId.HasValue)
                    {
                        await AddPharmacyStockBackAsync(connection, (SqlTransaction)transaction, medicineId.Value, request.StoreId, refundItem.RefundQuantity);
                    }

                    const string insertRefundDetailSql = @"
INSERT INTO Pharmacy.PharmacyChallanFormDetails
    (PatientId, VisitNo, ChallanNo, ActionById, Timestamp, MedicineId, ItemId, BranchId, StoreId,
     PharmacyChallanFormsId, Quantity, CustomQuantity, Total, Chargeable, IsInPatient, IsClosingPharmacyChallanFinal, TypeBit,
     RefundingChallanIdForDetail, RefundingChallanNoForDetail)
VALUES (@PatientId, @VisitNo, @ChallanNo, @ActionById, SYSUTCDATETIME(), @MedicineId, @ItemId, @BranchId, @StoreId,
    @RefundChallanId, @Quantity, @Quantity, @Total, 1, 0, 0, @TypeBit, @OriginalDetailId, @OriginalChallanNo);";
                    using var detailCommand = new SqlCommand(insertRefundDetailSql, connection, (SqlTransaction)transaction);
                    detailCommand.Parameters.AddWithValue("@PatientId", (object?)patientId ?? DBNull.Value);
                    detailCommand.Parameters.AddWithValue("@VisitNo", (object?)visitNo ?? DBNull.Value);
                    detailCommand.Parameters.AddWithValue("@ChallanNo", refundChallanNo);
                    detailCommand.Parameters.AddWithValue("@ActionById", actingUserId);
                    detailCommand.Parameters.AddWithValue("@MedicineId", (object?)medicineId ?? DBNull.Value);
                    detailCommand.Parameters.AddWithValue("@ItemId", (object?)itemId ?? DBNull.Value);
                    detailCommand.Parameters.AddWithValue("@BranchId", branchId);
                    detailCommand.Parameters.AddWithValue("@StoreId", request.StoreId);
                    detailCommand.Parameters.AddWithValue("@RefundChallanId", refundChallanId);
                    detailCommand.Parameters.AddWithValue("@Quantity", -refundItem.RefundQuantity);
                    detailCommand.Parameters.AddWithValue("@Total", -refundTotal);
                    detailCommand.Parameters.AddWithValue("@TypeBit", itemId.HasValue ? 15 : 4);
                    detailCommand.Parameters.AddWithValue("@OriginalDetailId", refundItem.ChallanFormDetailId);
                    detailCommand.Parameters.AddWithValue("@OriginalChallanNo", request.ChallanNo);
                    await detailCommand.ExecuteNonQueryAsync();
                }

                if (totalRefunded <= 0)
                {
                    await transaction.RollbackAsync();
                    throw new InvalidOperationException("Nothing to refund - enter a refund quantity for at least one item.");
                }

                const string updateHeaderTotalsSql = @"
UPDATE Pharmacy.PharmacyChallanForms
SET Amount = @Total, Total = @Total, GrandTotal = @Total, PaidAmount = @Total, Remaining = 0
WHERE Id = @Id;";
                using (var updateCommand = new SqlCommand(updateHeaderTotalsSql, connection, (SqlTransaction)transaction))
                {
                    updateCommand.Parameters.AddWithValue("@Total", -totalRefunded);
                    updateCommand.Parameters.AddWithValue("@Id", refundChallanId);
                    await updateCommand.ExecuteNonQueryAsync();
                }

                const string upsertRefundTrackingSql = @"
IF EXISTS (SELECT 1 FROM Pharmacy.PharmacyChallanFormRefundDetails WHERE RefundingPharmacyChallanNo = @OriginalChallanNo)
    UPDATE Pharmacy.PharmacyChallanFormRefundDetails
    SET TotalRefundedAmount = ISNULL(TotalRefundedAmount, 0) + @Amount, ModifiedOn = GETDATE()
    WHERE RefundingPharmacyChallanNo = @OriginalChallanNo;
ELSE
    INSERT INTO Pharmacy.PharmacyChallanFormRefundDetails
        (PatientId, VisitNo, RefundingPharmacyChallanNo, RefundingPharmacyChallanId, TotalRefundedAmount, CreatedById, CreatedOn, IsActive, IsDeleted)
    VALUES (@PatientId, @VisitNo, @OriginalChallanNo, @OriginalChallanId, @Amount, @ActionById, GETDATE(), 1, 0);";
                using (var trackingCommand = new SqlCommand(upsertRefundTrackingSql, connection, (SqlTransaction)transaction))
                {
                    trackingCommand.Parameters.AddWithValue("@OriginalChallanNo", request.ChallanNo);
                    trackingCommand.Parameters.AddWithValue("@Amount", totalRefunded);
                    trackingCommand.Parameters.AddWithValue("@PatientId", (object?)patientId ?? DBNull.Value);
                    trackingCommand.Parameters.AddWithValue("@VisitNo", (object?)visitNo ?? DBNull.Value);
                    trackingCommand.Parameters.AddWithValue("@OriginalChallanId", originalChallanFormsId);
                    trackingCommand.Parameters.AddWithValue("@ActionById", actingUserId);
                    await trackingCommand.ExecuteNonQueryAsync();
                }

                await transaction.CommitAsync();
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                _logger.LogError(ex, "Error processing pharmacy refund for challan {ChallanNo}", request.ChallanNo);
                throw;
            }

            return await GetChallanByIdAsync(refundChallanId) ?? throw new InvalidOperationException("Failed to load the refund challan.");
        }

        // ==================== Daily Sale ====================

        public async Task<IReadOnlyList<PharmacyDailySaleEntry>> GetDailySaleAsync(int? storeId, DateTime? dateFrom, DateTime? dateTo, string? challanType)
        {
            var results = new List<PharmacyDailySaleEntry>();
            const string sql = @"
SELECT f.Id, p.MRNo, COALESCE(f.PatientFullName, p.Name) AS PatientName, f.VisitNo, f.ChallanNo, ISNULL(ct.Name, '') AS ChallanType, s.StoreName,
    f.Timestamp, f.Discount, f.Total, f.PaidAmount, f.Remaining
FROM Pharmacy.PharmacyChallanForms f
LEFT JOIN Account.ChallanTypes ct ON ct.Id = f.ChallanTypeId
LEFT JOIN dbo.Patients p ON p.PatientID = f.PatientId
LEFT JOIN Inv.PharmacyStores s ON s.StoreId = f.StoreId
WHERE ct.Name IN ('Final', 'Refund')
  AND (@StoreId IS NULL OR f.StoreId = @StoreId)
  AND (@DateFrom IS NULL OR f.Timestamp >= @DateFrom)
  AND (@DateTo IS NULL OR f.Timestamp <= @DateTo)
  AND (@ChallanType IS NULL OR ct.Name = @ChallanType)
ORDER BY f.Timestamp DESC;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@StoreId", (object?)storeId ?? DBNull.Value);
            command.Parameters.AddWithValue("@DateFrom", (object?)dateFrom ?? DBNull.Value);
            command.Parameters.AddWithValue("@DateTo", (object?)dateTo ?? DBNull.Value);
            command.Parameters.AddWithValue("@ChallanType", (object?)challanType ?? DBNull.Value);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PharmacyDailySaleEntry
                {
                    Id = reader.GetInt32(0),
                    MRNo = reader.IsDBNull(1) ? null : reader.GetString(1),
                    PatientName = reader.IsDBNull(2) ? null : reader.GetString(2),
                    VisitNo = reader.IsDBNull(3) ? null : reader.GetString(3),
                    ChallanNo = reader.IsDBNull(4) ? null : reader.GetString(4),
                    ChallanType = reader.IsDBNull(5) ? string.Empty : reader.GetString(5),
                    StoreName = reader.IsDBNull(6) ? null : reader.GetString(6),
                    Timestamp = reader.GetDateTime(7),
                    Discount = ReadDecimal(reader, 8),
                    Total = ReadDecimal(reader, 9),
                    PaidAmount = ReadDecimal(reader, 10),
                    Remaining = ReadDecimal(reader, 11)
                });
            }

            return results;
        }

        // ==================== Item Wise Sale ====================

        public async Task<IReadOnlyList<PharmacyItemWiseSaleEntry>> GetItemWiseSaleAsync(int? storeId, int? itemId, DateTime? dateFrom, DateTime? dateTo)
        {
            var results = new List<PharmacyItemWiseSaleEntry>();
            const string sql = @"
SELECT COALESCE(f.PatientFullName, p.Name) AS PatientName, p.MRNo, f.VisitNo, f.ChallanNo, f.Timestamp, s.StoreName,
    COALESCE(m.MedicineFullName, ii.Name, 'Unassigned') AS ItemName, d.Quantity,
    CASE WHEN d.Quantity <> 0 THEN d.Total / d.Quantity ELSE 0 END AS UnitPrice, d.Total
FROM Pharmacy.PharmacyChallanFormDetails d
INNER JOIN Pharmacy.PharmacyChallanForms f ON f.Id = d.PharmacyChallanFormsId
LEFT JOIN Account.ChallanTypes ct ON ct.Id = f.ChallanTypeId
LEFT JOIN dbo.Patients p ON p.PatientID = f.PatientId
LEFT JOIN Inv.PharmacyStores s ON s.StoreId = f.StoreId
LEFT JOIN Pharmacy.Medicines m ON m.MedicineId = d.MedicineId
LEFT JOIN Inv.Items ii ON ii.Id = d.ItemId
WHERE ct.Name IN ('Final', 'Refund') AND d.Quantity > 0
  AND (@StoreId IS NULL OR f.StoreId = @StoreId)
  AND (@ItemId IS NULL OR d.ItemId = @ItemId)
  AND (@DateFrom IS NULL OR f.Timestamp >= @DateFrom)
  AND (@DateTo IS NULL OR f.Timestamp <= @DateTo)
ORDER BY f.Timestamp DESC;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@StoreId", (object?)storeId ?? DBNull.Value);
            command.Parameters.AddWithValue("@ItemId", (object?)itemId ?? DBNull.Value);
            command.Parameters.AddWithValue("@DateFrom", (object?)dateFrom ?? DBNull.Value);
            command.Parameters.AddWithValue("@DateTo", (object?)dateTo ?? DBNull.Value);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PharmacyItemWiseSaleEntry
                {
                    PatientName = reader.IsDBNull(0) ? null : reader.GetString(0),
                    MRNo = reader.IsDBNull(1) ? null : reader.GetString(1),
                    VisitNo = reader.IsDBNull(2) ? null : reader.GetString(2),
                    ChallanNo = reader.IsDBNull(3) ? null : reader.GetString(3),
                    Timestamp = reader.GetDateTime(4),
                    StoreName = reader.IsDBNull(5) ? null : reader.GetString(5),
                    ItemName = reader.IsDBNull(6) ? string.Empty : reader.GetString(6),
                    Quantity = reader.IsDBNull(7) ? 0 : reader.GetInt32(7),
                    UnitPrice = ReadDecimal(reader, 8),
                    Total = ReadDecimal(reader, 9)
                });
            }

            return results;
        }

        // ==================== Pharmacy Queue ====================

        public async Task<IReadOnlyList<PharmacyQueueEntry>> GetQueueAsync(int storeId)
        {
            var results = new List<PharmacyQueueEntry>();
            const string sql = @"
SELECT pp.Id, pp.PatientId, COALESCE(pp.PatientFullName, p.Name) AS PatientName, p.MRNo, pp.VisitNo,
    e.FullName AS PrescribedByName, pi.Name AS PrescribedInName, pp.TimeStamp
FROM Patient.PatientPharmacies pp
LEFT JOIN dbo.Patients p ON p.PatientID = pp.PatientId
LEFT JOIN dbo.Doctors doc ON doc.DocID = pp.PrescribedByDoctorId
LEFT JOIN Employee e ON e.EmpID = doc.EmpID
LEFT JOIN Data.PrescribedIns pi ON pi.PrescribedInId = pp.PrescribedInId
WHERE pp.PharmacyStoreId = @StoreId AND ISNULL(pp.Verified, 0) = 0
ORDER BY pp.TimeStamp DESC;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@StoreId", storeId);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PharmacyQueueEntry
                {
                    PatientPharmacyId = reader.GetInt32(0),
                    PatientId = reader.IsDBNull(1) ? null : reader.GetInt32(1),
                    PatientName = reader.IsDBNull(2) ? null : reader.GetString(2),
                    MRNo = reader.IsDBNull(3) ? null : reader.GetString(3),
                    VisitNo = reader.IsDBNull(4) ? null : reader.GetString(4),
                    PrescribedByName = reader.IsDBNull(5) ? null : reader.GetString(5),
                    PrescribedInName = reader.IsDBNull(6) ? null : reader.GetString(6),
                    Timestamp = reader.GetDateTime(7)
                });
            }

            return results;
        }

        // ==================== Pharmacy Online Order ====================

        public async Task<IReadOnlyList<PharmacyOnlineOrderEntry>> GetOnlineOrdersAsync(DateTime? dateFrom, DateTime? dateTo, int? storeId, string? status)
        {
            var results = new List<PharmacyOnlineOrderEntry>();
            const string sql = @"
SELECT pp.Id, pp.PharmacyOrderNumber, COALESCE(pp.PatientFullName, p.Name) AS PatientName, p.CNIC, p.MRNo,
    e.FullName AS ActionByName, s.StoreName, pp.TimeStamp, pp.PatientPharmacyStatusName
FROM Patient.PatientPharmacies pp
LEFT JOIN dbo.Patients p ON p.PatientID = pp.PatientId
LEFT JOIN Users u ON u.UserID = pp.ActionById
LEFT JOIN Employee e ON e.EmpID = u.EmpID
LEFT JOIN Inv.PharmacyStores s ON s.StoreId = pp.PharmacyStoreId
WHERE ISNULL(pp.IsOnlinePharmacy, 0) = 1
  AND (@StoreId IS NULL OR pp.PharmacyStoreId = @StoreId)
  AND (@DateFrom IS NULL OR pp.TimeStamp >= @DateFrom)
  AND (@DateTo IS NULL OR pp.TimeStamp <= @DateTo)
  AND (@Status IS NULL OR pp.PatientPharmacyStatusName = @Status)
ORDER BY pp.TimeStamp DESC;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@StoreId", (object?)storeId ?? DBNull.Value);
            command.Parameters.AddWithValue("@DateFrom", (object?)dateFrom ?? DBNull.Value);
            command.Parameters.AddWithValue("@DateTo", (object?)dateTo ?? DBNull.Value);
            command.Parameters.AddWithValue("@Status", (object?)status ?? DBNull.Value);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PharmacyOnlineOrderEntry
                {
                    PatientPharmacyId = reader.GetInt32(0),
                    OrderNumber = reader.IsDBNull(1) ? null : reader.GetString(1),
                    PatientName = reader.IsDBNull(2) ? null : reader.GetString(2),
                    CNIC = reader.IsDBNull(3) ? null : reader.GetString(3),
                    MRNo = reader.IsDBNull(4) ? null : reader.GetString(4),
                    ActionByName = reader.IsDBNull(5) ? null : reader.GetString(5),
                    StoreName = reader.IsDBNull(6) ? null : reader.GetString(6),
                    Timestamp = reader.GetDateTime(7),
                    Status = reader.IsDBNull(8) ? null : reader.GetString(8)
                });
            }

            return results;
        }

        // ==================== Pharmacy Dashboard ====================

        public async Task<PharmacyDashboardSummary> GetDashboardSummaryAsync(int branchId, int? storeId, DateTime? dateFrom, DateTime? dateTo)
        {
            var summary = new PharmacyDashboardSummary();

            using var connection = new SqlConnection(_connectionString);
            await connection.OpenAsync();

            const string countSql = @"
SELECT COUNT(*) FROM Pharmacy.PharmacyChallanForms f
LEFT JOIN Account.ChallanTypes ct ON ct.Id = f.ChallanTypeId
WHERE f.IsFinalized = 1 AND ct.Name = 'Final'
  AND (@StoreId IS NULL OR f.StoreId = @StoreId)
  AND (@DateFrom IS NULL OR f.Timestamp >= @DateFrom)
  AND (@DateTo IS NULL OR f.Timestamp <= @DateTo);";
            using (var command = new SqlCommand(countSql, connection))
            {
                command.Parameters.AddWithValue("@StoreId", (object?)storeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateFrom", (object?)dateFrom ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateTo", (object?)dateTo ?? DBNull.Value);
                summary.DailyPrescriptionsDispensed = Convert.ToInt32(await command.ExecuteScalarAsync());
            }

            const string topDispensedSql = @"
SELECT TOP 10 COALESCE(m.MedicineFullName, ii.Name, 'Unassigned') AS Name, SUM(d.Quantity) AS Quantity
FROM Pharmacy.PharmacyChallanFormDetails d
INNER JOIN Pharmacy.PharmacyChallanForms f ON f.Id = d.PharmacyChallanFormsId
LEFT JOIN Account.ChallanTypes ct ON ct.Id = f.ChallanTypeId
LEFT JOIN Pharmacy.Medicines m ON m.MedicineId = d.MedicineId
LEFT JOIN Inv.Items ii ON ii.Id = d.ItemId
WHERE f.IsFinalized = 1 AND ct.Name = 'Final' AND d.Quantity > 0
  AND (@StoreId IS NULL OR f.StoreId = @StoreId)
  AND (@DateFrom IS NULL OR f.Timestamp >= @DateFrom)
  AND (@DateTo IS NULL OR f.Timestamp <= @DateTo)
GROUP BY COALESCE(m.MedicineFullName, ii.Name, 'Unassigned')
ORDER BY SUM(d.Quantity) DESC;";
            using (var command = new SqlCommand(topDispensedSql, connection))
            {
                command.Parameters.AddWithValue("@StoreId", (object?)storeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateFrom", (object?)dateFrom ?? DBNull.Value);
                command.Parameters.AddWithValue("@DateTo", (object?)dateTo ?? DBNull.Value);
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    summary.TopDispensedItems.Add(new PharmacyDashboardItemStat { Name = reader.GetString(0), Quantity = ReadDecimal(reader, 1) });
                }
            }

            const string topStockSql = @"
SELECT TOP 10 i.Name, SUM(s.TotalItemsInStock) AS Quantity
FROM Pharmacy.PharmacyMedicinesStocks s
INNER JOIN Inv.Items i ON i.Id = s.ItemId
WHERE i.BranchId = @BranchId
  AND (@StoreId IS NULL OR s.StoreId = @StoreId)
GROUP BY i.Name
ORDER BY SUM(s.TotalItemsInStock) DESC;";
            using (var command = new SqlCommand(topStockSql, connection))
            {
                command.Parameters.AddWithValue("@BranchId", branchId);
                command.Parameters.AddWithValue("@StoreId", (object?)storeId ?? DBNull.Value);
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    summary.TopItemsInStock.Add(new PharmacyDashboardItemStat { Name = reader.GetString(0), Quantity = ReadDecimal(reader, 1) });
                }
            }

            const string expiringSql = @"
SELECT TOP 15 ISNULL(bm.MedicineFullName, 'Unassigned') AS Name, s.StockExpiryDate, SUM(s.TotalItemsInStock) AS Quantity
FROM Pharmacy.PharmacyMedicinesStocks s
LEFT JOIN Pharmacy.BranchMedicines bm ON bm.Id = s.BranchMedicineId
WHERE s.StockExpiryDate IS NOT NULL AND s.StockExpiryDate <= DATEADD(DAY, 90, GETDATE()) AND s.TotalItemsInStock > 0
  AND (@StoreId IS NULL OR s.StoreId = @StoreId)
GROUP BY ISNULL(bm.MedicineFullName, 'Unassigned'), s.StockExpiryDate
ORDER BY s.StockExpiryDate ASC;";
            using (var command = new SqlCommand(expiringSql, connection))
            {
                command.Parameters.AddWithValue("@StoreId", (object?)storeId ?? DBNull.Value);
                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    summary.ExpiringSoon.Add(new PharmacyDashboardExpiryStat
                    {
                        Name = reader.GetString(0),
                        ExpiryDate = reader.GetDateTime(1),
                        Quantity = ReadDecimal(reader, 2)
                    });
                }
            }

            return summary;
        }

        // ==================== Immunization ====================

        public async Task<IReadOnlyList<PharmacyLookupItem>> GetVaccinesAsync()
        {
            var results = new List<PharmacyLookupItem>();
            const string sql = "SELECT VaccineId, Name FROM Data.Vaccines WHERE ISNULL(IsActive, 1) = 1 AND ISNULL(IsDeleted, 0) = 0 ORDER BY Name;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PharmacyLookupItem { Id = reader.GetInt32(0), Name = reader.IsDBNull(1) ? string.Empty : reader.GetString(1) });
            }

            return results;
        }

        public async Task<IReadOnlyList<PharmacyVaccineRecord>> GetVaccineRecordsAsync(DateTime? dateFrom, DateTime? dateTo, int? patientId)
        {
            var results = new List<PharmacyVaccineRecord>();
            const string sql = @"
SELECT pv.PatientVaccineId, pv.PatientId, p.Name AS PatientName, p.MRNo, pv.VaccineId, v.Name AS VaccineName, pv.VaccinationDate, pv.VaccinationRemarks
FROM Patient.PatientVaccines pv
LEFT JOIN dbo.Patients p ON p.PatientID = pv.PatientId
LEFT JOIN Data.Vaccines v ON v.VaccineId = pv.VaccineId
WHERE ISNULL(pv.IsDeleted, 0) = 0
  AND (@PatientId IS NULL OR pv.PatientId = @PatientId)
  AND (@DateFrom IS NULL OR pv.VaccinationDate >= @DateFrom)
  AND (@DateTo IS NULL OR pv.VaccinationDate <= @DateTo)
ORDER BY pv.VaccinationDate DESC;";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@PatientId", (object?)patientId ?? DBNull.Value);
            command.Parameters.AddWithValue("@DateFrom", (object?)dateFrom ?? DBNull.Value);
            command.Parameters.AddWithValue("@DateTo", (object?)dateTo ?? DBNull.Value);
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                results.Add(new PharmacyVaccineRecord
                {
                    PatientVaccineId = reader.GetInt32(0),
                    PatientId = reader.IsDBNull(1) ? 0 : reader.GetInt32(1),
                    PatientName = reader.IsDBNull(2) ? null : reader.GetString(2),
                    MRNo = reader.IsDBNull(3) ? null : reader.GetString(3),
                    VaccineId = reader.IsDBNull(4) ? 0 : reader.GetInt32(4),
                    VaccineName = reader.IsDBNull(5) ? null : reader.GetString(5),
                    VaccinationDate = reader.IsDBNull(6) ? null : reader.GetDateTime(6),
                    Remarks = reader.IsDBNull(7) ? null : reader.GetString(7)
                });
            }

            return results;
        }

        public async Task<PharmacyVaccineRecord> CreateVaccineRecordAsync(PharmacyVaccineCreateRequest request, int actingUserId)
        {
            const string sql = @"
INSERT INTO Patient.PatientVaccines (PatientId, VaccineId, VaccinationDate, VaccinationRemarks, VaccinationStatus, CreatedById, CreatedOn, IsActive, IsDeleted)
VALUES (@PatientId, @VaccineId, @VaccinationDate, @Remarks, 1, @ActingUserId, GETDATE(), 1, 0);
SELECT CAST(SCOPE_IDENTITY() AS INT);";

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand(sql, connection);
            command.Parameters.AddWithValue("@PatientId", request.PatientId);
            command.Parameters.AddWithValue("@VaccineId", request.VaccineId);
            command.Parameters.AddWithValue("@VaccinationDate", (object?)request.VaccinationDate ?? DBNull.Value);
            command.Parameters.AddWithValue("@Remarks", (object?)request.Remarks ?? DBNull.Value);
            command.Parameters.AddWithValue("@ActingUserId", actingUserId);
            await connection.OpenAsync();
            var id = Convert.ToInt32(await command.ExecuteScalarAsync());

            var records = await GetVaccineRecordsAsync(null, null, request.PatientId);
            return records.First(r => r.PatientVaccineId == id);
        }
    }
}
