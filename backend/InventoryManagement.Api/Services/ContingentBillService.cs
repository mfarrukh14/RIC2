using InventoryManagement.API.Models;
using InventoryManagement.Api.Models;
using Microsoft.Data.SqlClient;
using System.Data;

namespace InventoryManagement.API.Services
{
    public class ContingentBillService : IContingentBillService
    {
        private readonly string _connectionString;

        public ContingentBillService(IConfiguration configuration)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new InvalidOperationException("Connection string not found");
        }

        public async Task<PagedResult<ContingentBill>> GetAllAsync(ContingentBillFilterRequest filter)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(filter.PageNumber, filter.PageSize);
            var bills = new List<ContingentBill>();
            var totalCount = 0;

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ContingentBills_GetAll", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@BudgetSetupId", (object?)filter.BudgetSetupId ?? DBNull.Value);
            command.Parameters.AddWithValue("@VendorId", (object?)filter.VendorId ?? DBNull.Value);
            command.Parameters.AddWithValue("@FinancialYearId", (object?)filter.FinancialYearId ?? DBNull.Value);
            command.Parameters.AddWithValue("@PurchaseOrderTypeId", (object?)filter.PurchaseOrderTypeId ?? DBNull.Value);
            command.Parameters.AddWithValue("@ContingentBillStatusId", (object?)filter.ContingentBillStatusId ?? DBNull.Value);
            command.Parameters.AddWithValue("@DateStart", (object?)filter.DateStart ?? DBNull.Value);
            command.Parameters.AddWithValue("@DateEnd", (object?)filter.DateEnd ?? DBNull.Value);
            command.Parameters.AddWithValue("@SearchTerm", (object?)filter.SearchTerm ?? DBNull.Value);
            PaginationHelper.AddPagingParameters(command, pageNumber, pageSize);

            await connection.OpenAsync();

            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                if (totalCount == 0)
                {
                    totalCount = PaginationHelper.ReadTotalCount(reader);
                }
                bills.Add(MapContingentBill(reader));
            }

            return new PagedResult<ContingentBill> { Items = bills, TotalCount = totalCount, PageNumber = pageNumber, PageSize = pageSize };
        }

        public async Task<ContingentBill?> GetByIdAsync(int id)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ContingentBills_GetById", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);
            await connection.OpenAsync();

            using var reader = await command.ExecuteReaderAsync();
            if (await reader.ReadAsync())
            {
                return MapContingentBill(reader);
            }

            return null;
        }

        public async Task<int> CreateAsync(CreateContingentBillRequest request)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ContingentBills_Insert", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            AddCommonParameters(command, request);

            await connection.OpenAsync();
            var result = await command.ExecuteScalarAsync();
            return Convert.ToInt32(result);
        }

        public async Task<bool> UpdateAsync(int id, UpdateContingentBillRequest request)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ContingentBills_Update", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);
            AddCommonParameters(command, request);

            await connection.OpenAsync();
            var rowsAffected = await command.ExecuteNonQueryAsync();
            return rowsAffected > 0;
        }

        public async Task<bool> DeleteAsync(int id)
        {
            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ContingentBills_Delete", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            command.Parameters.AddWithValue("@Id", id);

            await connection.OpenAsync();
            var rowsAffected = await command.ExecuteNonQueryAsync();
            return rowsAffected > 0;
        }

        public async Task<ContingentBillLookupData> GetLookupDataAsync()
        {
            var lookupData = new ContingentBillLookupData();

            using var connection = new SqlConnection(_connectionString);
            using var command = new SqlCommand("ContingentBills_GetLookupData", connection)
            {
                CommandType = CommandType.StoredProcedure
            };

            await connection.OpenAsync();

            using var reader = await command.ExecuteReaderAsync();

            // Read Financial Years
            while (await reader.ReadAsync())
            {
                lookupData.FinancialYears.Add(new LookupItem
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1)
                });
            }

            // Read Purchase Order Types
            await reader.NextResultAsync();
            while (await reader.ReadAsync())
            {
                lookupData.PurchaseOrderTypes.Add(new LookupItem
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1)
                });
            }

            // Read Vendors
            await reader.NextResultAsync();
            while (await reader.ReadAsync())
            {
                lookupData.Vendors.Add(new LookupItem
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1)
                });
            }

            // Read Branches
            await reader.NextResultAsync();
            while (await reader.ReadAsync())
            {
                lookupData.Branches.Add(new LookupItem
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1)
                });
            }

            // Read Departments (used as Budget Head for now)
            await reader.NextResultAsync();
            while (await reader.ReadAsync())
            {
                lookupData.Departments.Add(new LookupItem
                {
                    Id = reader.GetInt32(0),
                    Name = reader.GetString(1)
                });
            }

            return lookupData;
        }

        private ContingentBill MapContingentBill(SqlDataReader reader)
        {
            return new ContingentBill
            {
                Id = reader.GetInt32("Id"),
                FinancialYearId = reader.GetInt32("FinancialYearId"),
                FinancialYearName = reader.IsDBNull("FinancialYearName") ? null : reader.GetString("FinancialYearName"),
                PurchaseOrderTypeId = reader.GetInt32("PurchaseOrderTypeId"),
                PurchaseOrderTypeName = reader.IsDBNull("PurchaseOrderTypeName") ? null : reader.GetString("PurchaseOrderTypeName"),
                PurchaseOrderDate = reader.GetDateTime("PurchaseOrderDate"),
                VendorId = reader.GetInt32("VendorId"),
                VendorName = reader.IsDBNull("VendorName") ? null : reader.GetString("VendorName"),
                BudgetSetupId = reader.IsDBNull("BudgetSetupId") ? null : reader.GetString("BudgetSetupId"),
                BudgetSetupName = reader.IsDBNull("BudgetSetupName") ? null : reader.GetString("BudgetSetupName"),
                BillNo = reader.IsDBNull("BillNo") ? null : reader.GetString("BillNo"),
                BillDate = reader.GetDateTime("BillDate"),
                BudgetAllotment = GetNullableFloat(reader, "BudgetAllotment"),
                BillAmount = GetNullableFloat(reader, "BillAmount"),
                TotalPreviousBill = GetNullableFloat(reader, "TotalPreviousBill"),
                TotalUptoDate = GetNullableFloat(reader, "TotalUptoDate"),
                AvailableBalance = GetNullableFloat(reader, "AvailableBalance"),
                GrandTotal = GetNullableFloat(reader, "GrandTotal"),
                TaxAmount = GetNullableFloat(reader, "TaxAmount"),
                NetPayment = GetNullableFloat(reader, "NetPayment"),
                AmountInWords = reader.IsDBNull("AmountInWords") ? null : reader.GetString("AmountInWords"),
                Stamp1 = reader.IsDBNull("Stamp1") ? null : reader.GetString("Stamp1"),
                Stamp2 = reader.IsDBNull("Stamp2") ? null : reader.GetString("Stamp2"),
                Stamp3 = reader.IsDBNull("Stamp3") ? null : reader.GetString("Stamp3"),
                Stamp4 = reader.IsDBNull("Stamp4") ? null : reader.GetString("Stamp4"),
                Stamp5 = reader.IsDBNull("Stamp5") ? null : reader.GetString("Stamp5"),
                Stamp6 = reader.IsDBNull("Stamp6") ? null : reader.GetString("Stamp6"),
                TermsAndConditions = reader.IsDBNull("TermsAndConditions") ? null : reader.GetString("TermsAndConditions"),
                PreAuditedAmount = GetNullableFloat(reader, "PreAuditedAmount"),
                PreAuditedAmountInWords = reader.IsDBNull("PreAuditedAmountInWords") ? null : reader.GetString("PreAuditedAmountInWords"),
                TokenNo = reader.IsDBNull("TokenNo") ? null : reader.GetString("TokenNo"),
                AuditDate = reader.IsDBNull("AuditDate") ? null : reader.GetDateTime("AuditDate"),
                DisplayStampFormatForAuditSection = reader.IsDBNull("DisplayStampFormatForAuditSection") ? null : reader.GetBoolean("DisplayStampFormatForAuditSection"),
                IsClosed = reader.GetBoolean("IsClosed"),
                Remarks = reader.IsDBNull("Remarks") ? null : reader.GetString("Remarks"),
                RegisterPageNo = reader.IsDBNull("RegisterPageNo") ? null : reader.GetString("RegisterPageNo"),
                SRNO = reader.IsDBNull("SRNO") ? null : reader.GetString("SRNO"),
                BranchId = reader.GetInt32("BranchId"),
                BranchName = reader.IsDBNull("BranchName") ? null : reader.GetString("BranchName"),
                ContingentBillStatusId = reader.IsDBNull("ContingentBillStatusId") ? null : reader.GetInt32("ContingentBillStatusId"),
                AssignedToId = reader.IsDBNull("AssignedToId") ? null : reader.GetInt32("AssignedToId"),
                AssignedFromId = reader.IsDBNull("AssignedFromId") ? null : reader.GetInt32("AssignedFromId"),
                ApprovedById = reader.IsDBNull("ApprovedById") ? null : reader.GetInt32("ApprovedById"),
                CreatedById = reader.IsDBNull("CreatedById") ? null : reader.GetString("CreatedById"),
                CreatedOn = reader.GetDateTime("CreatedOn"),
                ModifiedById = reader.IsDBNull("ModifiedById") ? null : reader.GetString("ModifiedById"),
                ModifiedOn = reader.IsDBNull("ModifiedOn") ? null : reader.GetDateTime("ModifiedOn"),
                IsDeleted = reader.GetBoolean("IsDeleted"),
                IsActive = reader.GetBoolean("IsActive")
            };
        }

        private void AddCommonParameters(SqlCommand command, dynamic request)
        {
            command.Parameters.AddWithValue("@FinancialYearId", request.FinancialYearId);
            command.Parameters.AddWithValue("@PurchaseOrderTypeId", request.PurchaseOrderTypeId);
            command.Parameters.AddWithValue("@PurchaseOrderDate", request.PurchaseOrderDate);
            command.Parameters.AddWithValue("@VendorId", request.VendorId);
            command.Parameters.AddWithValue("@BudgetSetupId", (object?)request.BudgetSetupId ?? DBNull.Value);
            command.Parameters.AddWithValue("@BillNo", (object?)request.BillNo ?? DBNull.Value);
            command.Parameters.AddWithValue("@BillDate", request.BillDate);
            command.Parameters.AddWithValue("@BudgetAllotment", (object?)request.BudgetAllotment ?? DBNull.Value);
            command.Parameters.AddWithValue("@BillAmount", (object?)request.BillAmount ?? DBNull.Value);
            command.Parameters.AddWithValue("@TotalPreviousBill", (object?)request.TotalPreviousBill ?? DBNull.Value);
            command.Parameters.AddWithValue("@TotalUptoDate", (object?)request.TotalUptoDate ?? DBNull.Value);
            command.Parameters.AddWithValue("@AvailableBalance", (object?)request.AvailableBalance ?? DBNull.Value);
            command.Parameters.AddWithValue("@GrandTotal", (object?)request.GrandTotal ?? DBNull.Value);
            command.Parameters.AddWithValue("@TaxAmount", (object?)request.TaxAmount ?? DBNull.Value);
            command.Parameters.AddWithValue("@NetPayment", (object?)request.NetPayment ?? DBNull.Value);
            command.Parameters.AddWithValue("@AmountInWords", (object?)request.AmountInWords ?? DBNull.Value);
            command.Parameters.AddWithValue("@Stamp1", (object?)request.Stamp1 ?? DBNull.Value);
            command.Parameters.AddWithValue("@Stamp2", (object?)request.Stamp2 ?? DBNull.Value);
            command.Parameters.AddWithValue("@Stamp3", (object?)request.Stamp3 ?? DBNull.Value);
            command.Parameters.AddWithValue("@Stamp4", (object?)request.Stamp4 ?? DBNull.Value);
            command.Parameters.AddWithValue("@Stamp5", (object?)request.Stamp5 ?? DBNull.Value);
            command.Parameters.AddWithValue("@Stamp6", (object?)request.Stamp6 ?? DBNull.Value);
            command.Parameters.AddWithValue("@TermsAndConditions", (object?)request.TermsAndConditions ?? DBNull.Value);
            command.Parameters.AddWithValue("@PreAuditedAmount", (object?)request.PreAuditedAmount ?? DBNull.Value);
            command.Parameters.AddWithValue("@PreAuditedAmountInWords", (object?)request.PreAuditedAmountInWords ?? DBNull.Value);
            command.Parameters.AddWithValue("@TokenNo", (object?)request.TokenNo ?? DBNull.Value);
            command.Parameters.AddWithValue("@AuditDate", (object?)request.AuditDate ?? DBNull.Value);
            command.Parameters.AddWithValue("@DisplayStampFormatForAuditSection", (object?)request.DisplayStampFormatForAuditSection ?? DBNull.Value);
            command.Parameters.AddWithValue("@IsClosed", request.IsClosed);
            command.Parameters.AddWithValue("@Remarks", (object?)request.Remarks ?? DBNull.Value);
            command.Parameters.AddWithValue("@RegisterPageNo", (object?)request.RegisterPageNo ?? DBNull.Value);
            command.Parameters.AddWithValue("@SRNO", (object?)request.SRNO ?? DBNull.Value);
            command.Parameters.AddWithValue("@ContingentBillStatusId", (object?)request.ContingentBillStatusId ?? DBNull.Value);
            command.Parameters.AddWithValue("@AssignedToId", (object?)request.AssignedToId ?? DBNull.Value);
            command.Parameters.AddWithValue("@AssignedFromId", (object?)request.AssignedFromId ?? DBNull.Value);
            command.Parameters.AddWithValue("@ApprovedById", (object?)request.ApprovedById ?? DBNull.Value);

            // Handle Create vs Update specific parameters
            if (request is CreateContingentBillRequest createRequest)
            {
                command.Parameters.AddWithValue("@BranchId", createRequest.BranchId);
                command.Parameters.AddWithValue("@CreatedById", (object?)createRequest.CreatedById ?? DBNull.Value);
            }
            else if (request is UpdateContingentBillRequest updateRequest)
            {
                command.Parameters.AddWithValue("@ModifiedById", (object?)updateRequest.ModifiedById ?? DBNull.Value);
            }
        }

        private static float? GetNullableFloat(SqlDataReader reader, string columnName)
        {
            if (reader.IsDBNull(columnName))
            {
                return null;
            }

            return Convert.ToSingle(reader.GetValue(reader.GetOrdinal(columnName)));
        }
    }
}
