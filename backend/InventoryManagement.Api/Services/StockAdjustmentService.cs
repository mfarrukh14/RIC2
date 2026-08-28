using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public class StockAdjustmentService : IStockAdjustmentService
    {
        private readonly string _connectionString;
        private readonly ILogger<StockAdjustmentService> _logger;

        public StockAdjustmentService(IConfiguration configuration, ILogger<StockAdjustmentService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? throw new ArgumentNullException("Connection string not found");
            _logger = logger;
        }

        public async Task<PagedResult<StockAdjustmentView>> GetAllAsync(StockAdjustmentSearchRequest? request = null)
        {
            var (pageNumber, pageSize) = PaginationHelper.Normalize(request?.PageNumber ?? 1, request?.PageSize ?? PaginationHelper.DefaultPageSize);
            var stockAdjustments = new List<StockAdjustmentView>();
            var totalCount = 0;

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockAdjustment_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@BranchId", (object?)request?.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", (object?)request?.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StartDate", (object?)request?.StartDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", (object?)request?.EndDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@SearchTerm", (object?)request?.SearchTerm ?? DBNull.Value);
                PaginationHelper.AddPagingParameters(command, pageNumber, pageSize);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    if (totalCount == 0)
                    {
                        totalCount = PaginationHelper.ReadTotalCount(reader);
                    }
                    stockAdjustments.Add(new StockAdjustmentView
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                        ItemNames = reader.IsDBNull(reader.GetOrdinal("ItemNames")) ? null : reader.GetString(reader.GetOrdinal("ItemNames")),
                        StockType = reader.IsDBNull(reader.GetOrdinal("StockType")) ? null : reader.GetString(reader.GetOrdinal("StockType")),
                        ActionBy = reader.IsDBNull(reader.GetOrdinal("ActionBy")) ? null : reader.GetString(reader.GetOrdinal("ActionBy")),
                        ActionOn = reader.IsDBNull(reader.GetOrdinal("ActionOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ActionOn")),
                        TotalQuantity = reader.GetDecimal(reader.GetOrdinal("TotalQuantity")),
                        TotalPurchaseValue = reader.GetDecimal(reader.GetOrdinal("TotalPurchaseValue")),
                        TotalSaleValue = reader.GetDecimal(reader.GetOrdinal("TotalSaleValue"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock adjustments");
                throw;
            }

            return new PagedResult<StockAdjustmentView> { Items = stockAdjustments, TotalCount = totalCount, PageNumber = pageNumber, PageSize = pageSize };
        }

        public async Task<StockAdjustment?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockAdjustment_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    var stockAdjustment = MapToStockAdjustment(reader);
                    
                    // Get details
                    if (await reader.NextResultAsync())
                    {
                        stockAdjustment.Details = new List<StockAdjustmentDetail>();
                        while (await reader.ReadAsync())
                        {
                            stockAdjustment.Details.Add(MapToStockAdjustmentDetail(reader));
                        }
                    }

                    return stockAdjustment;
                }

                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock adjustment with ID {Id}", id);
                throw;
            }
        }

        public async Task<StockAdjustment> CreateAsync(StockAdjustmentCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var transaction = connection.BeginTransaction();

                try
                {
                    // Insert main stock adjustment
                    int stockAdjustmentId;
                    
                    using (var command = new SqlCommand("StockAdjustment_Insert", connection, transaction))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        var idParam = new SqlParameter("@Id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                        command.Parameters.Add(idParam);
                        command.Parameters.AddWithValue("@StoreId", request.StoreId);
                        command.Parameters.AddWithValue("@BranchId", request.BranchId);
                        command.Parameters.AddWithValue("@Type", request.Type);
                        command.Parameters.AddWithValue("@CreatedById", (object?)request.CreatedById ?? DBNull.Value);
                        command.Parameters.AddWithValue("@CreatedOn", DateTime.UtcNow);

                        await command.ExecuteNonQueryAsync();
                        stockAdjustmentId = (int)idParam.Value;
                    }

                    // Insert details
                    foreach (var detail in request.Details)
                    {
                        using (var detailCommand = new SqlCommand("StockAdjustmentDetail_Insert", connection, transaction))
                        {
                            detailCommand.CommandType = CommandType.StoredProcedure;
                            var detailIdParam = new SqlParameter("@Id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                            detailCommand.Parameters.Add(detailIdParam);
                            detailCommand.Parameters.AddWithValue("@StockAdjustmentId", stockAdjustmentId);
                            detailCommand.Parameters.AddWithValue("@ItemId", (object?)detail.ItemId ?? DBNull.Value);
                            detailCommand.Parameters.AddWithValue("@MedicineId", (object?)detail.MedicineId ?? DBNull.Value);
                            detailCommand.Parameters.AddWithValue("@SubServiceId", (object?)detail.SubServiceId ?? DBNull.Value);
                            detailCommand.Parameters.AddWithValue("@Type", detail.Type);
                            detailCommand.Parameters.AddWithValue("@StockTypeId", detail.StockTypeId);
                            detailCommand.Parameters.AddWithValue("@Quantity", detail.Quantity);
                            detailCommand.Parameters.AddWithValue("@SaleValue", (object?)detail.SaleValue ?? DBNull.Value);
                            detailCommand.Parameters.AddWithValue("@BranchId", request.BranchId);
                            detailCommand.Parameters.AddWithValue("@CreatedById", (object?)request.CreatedById ?? DBNull.Value);
                            detailCommand.Parameters.AddWithValue("@CreatedOn", DateTime.UtcNow);

                            await detailCommand.ExecuteNonQueryAsync();
                        }

                        // This is the actual stock effect - previously the insert above was
                        // all that happened, so an adjustment was just a log entry that never
                        // touched the stock ledger regardless of Type. Type 2 ("Issue") adds stock
                        // into this store; Type 1 ("Less/Decrease") removes it.
                        await ApplyStockEffectAsync(connection, transaction, new ProductKey(detail.ItemId, detail.MedicineId, detail.SubServiceId), request.StoreId, request.BranchId, detail.Type, detail.Quantity);
                    }

                    await transaction.CommitAsync();

                    return await GetByIdAsync(stockAdjustmentId) ?? throw new Exception("Failed to retrieve created stock adjustment");
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating stock adjustment");
                throw;
            }
        }

        public async Task<StockAdjustment> UpdateAsync(StockAdjustmentUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var transaction = connection.BeginTransaction();

                try
                {
                    // Undo whatever the previous save of this adjustment already did to
                    // the stock ledger before applying the new lines - otherwise editing an
                    // adjustment would double up its effect instead of correcting it. Reverse
                    // against the OLD store, since the store itself may also be getting
                    // changed by this edit.
                    var previousStoreId = await GetAdjustmentStoreIdAsync(connection, transaction, request.Id);
                    if (previousStoreId.HasValue)
                    {
                        var previousDetails = await GetActiveDetailsAsync(connection, transaction, request.Id);
                        foreach (var previous in previousDetails)
                        {
                            await ReverseStockEffectAsync(connection, transaction, previous.Product, previousStoreId.Value, previous.Type, previous.Quantity);
                        }
                    }

                    // Update main stock adjustment
                    using (var command = new SqlCommand("StockAdjustment_Update", connection, transaction))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@Id", request.Id);
                        command.Parameters.AddWithValue("@StoreId", request.StoreId);
                        command.Parameters.AddWithValue("@BranchId", request.BranchId);
                        command.Parameters.AddWithValue("@Type", request.Type);
                        command.Parameters.AddWithValue("@ModifiedById", (object?)request.ModifiedById ?? DBNull.Value);
                        command.Parameters.AddWithValue("@ModifiedOn", DateTime.UtcNow);

                        await command.ExecuteNonQueryAsync();
                    }

                    // Delete existing details
                    using (var deleteCommand = new SqlCommand("StockAdjustmentDetail_DeleteByAdjustmentId", connection, transaction))
                    {
                        deleteCommand.CommandType = CommandType.StoredProcedure;
                        deleteCommand.Parameters.AddWithValue("@StockAdjustmentId", request.Id);
                        await deleteCommand.ExecuteNonQueryAsync();
                    }

                    // Insert new details
                    foreach (var detail in request.Details)
                    {
                        using (var detailCommand = new SqlCommand("StockAdjustmentDetail_Insert", connection, transaction))
                        {
                            detailCommand.CommandType = CommandType.StoredProcedure;
                            var detailIdParam = new SqlParameter("@Id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                            detailCommand.Parameters.Add(detailIdParam);
                            detailCommand.Parameters.AddWithValue("@StockAdjustmentId", request.Id);
                            detailCommand.Parameters.AddWithValue("@ItemId", (object?)detail.ItemId ?? DBNull.Value);
                            detailCommand.Parameters.AddWithValue("@MedicineId", (object?)detail.MedicineId ?? DBNull.Value);
                            detailCommand.Parameters.AddWithValue("@SubServiceId", (object?)detail.SubServiceId ?? DBNull.Value);
                            detailCommand.Parameters.AddWithValue("@Type", detail.Type);
                            detailCommand.Parameters.AddWithValue("@StockTypeId", detail.StockTypeId);
                            detailCommand.Parameters.AddWithValue("@Quantity", detail.Quantity);
                            detailCommand.Parameters.AddWithValue("@SaleValue", (object?)detail.SaleValue ?? DBNull.Value);
                            detailCommand.Parameters.AddWithValue("@BranchId", request.BranchId);
                            detailCommand.Parameters.AddWithValue("@CreatedById", (object?)request.ModifiedById ?? DBNull.Value);
                            detailCommand.Parameters.AddWithValue("@CreatedOn", DateTime.UtcNow);

                            await detailCommand.ExecuteNonQueryAsync();
                        }

                        await ApplyStockEffectAsync(connection, transaction, new ProductKey(detail.ItemId, detail.MedicineId, detail.SubServiceId), request.StoreId, request.BranchId, detail.Type, detail.Quantity);
                    }

                    await transaction.CommitAsync();

                    return await GetByIdAsync(request.Id) ?? throw new Exception("Failed to retrieve updated stock adjustment");
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating stock adjustment");
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = connection.BeginTransaction();

                try
                {
                    // Deleting an adjustment voids it - undo whatever it did to the stock ledger,
                    // same as reversing on edit, so a deleted adjustment doesn't leave a
                    // permanent, invisible effect on the store's balance.
                    var storeId = await GetAdjustmentStoreIdAsync(connection, transaction, id);
                    if (!storeId.HasValue)
                    {
                        await transaction.RollbackAsync();
                        return false;
                    }

                    var details = await GetActiveDetailsAsync(connection, transaction, id);
                    foreach (var detail in details)
                    {
                        await ReverseStockEffectAsync(connection, transaction, detail.Product, storeId.Value, detail.Type, detail.Quantity);
                    }

                    using (var command = new SqlCommand("StockAdjustment_Delete", connection, transaction)
                    {
                        CommandType = CommandType.StoredProcedure
                    })
                    {
                        command.Parameters.AddWithValue("@Id", id);
                        // StockAdjustment_Delete has SET NOCOUNT ON, so ExecuteNonQueryAsync's
                        // return value is unreliable (-1, not the actual row count) - existence
                        // was already confirmed above via GetAdjustmentStoreIdAsync, so that is
                        // the source of truth for whether this delete succeeded, not this call.
                        await command.ExecuteNonQueryAsync();
                    }

                    await transaction.CommitAsync();
                    return true;
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            catch (InvalidOperationException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting stock adjustment with ID {Id}", id);
                throw;
            }
        }

        // Type 2 ("Issue") adds stock into the store; Type 1 ("Less/Decrease", and anything
        // else) removes it. Reversing simply applies the opposite direction for the same
        // quantity - used when an adjustment is edited or deleted so its old effect doesn't
        // linger or get double-counted.
        private async Task ApplyStockEffectAsync(SqlConnection connection, SqlTransaction transaction, ProductKey product, int storeId, int branchId, int type, decimal quantity)
        {
            var qty = (int)Math.Round(quantity, MidpointRounding.AwayFromZero);
            if (qty <= 0)
            {
                return;
            }

            if (type == 2)
            {
                await AddStockAsync(connection, transaction, product, storeId, branchId, qty);
            }
            else
            {
                var itemName = await GetItemNameAsync(connection, transaction, product);
                await RemoveStockAsync(connection, transaction, product, itemName, storeId, qty);
            }
        }

        private async Task ReverseStockEffectAsync(SqlConnection connection, SqlTransaction transaction, ProductKey product, int storeId, int type, decimal quantity)
        {
            var qty = (int)Math.Round(quantity, MidpointRounding.AwayFromZero);
            if (qty <= 0)
            {
                return;
            }

            if (type == 2)
            {
                var itemName = await GetItemNameAsync(connection, transaction, product);
                await RemoveStockAsync(connection, transaction, product, itemName, storeId, qty);
            }
            else
            {
                // BranchId isn't needed when reversing a decrease back to an increase - the
                // store already had a stock row (that's what made the original decrease
                // possible), so this always takes the update branch of AddStockAsync's upsert.
                await AddStockAsync(connection, transaction, product, storeId, 0, qty);
            }
        }

        private async Task<string> GetItemNameAsync(SqlConnection connection, SqlTransaction transaction, ProductKey product)
        {
            using var command = new SqlCommand(
                "SELECT COALESCE((SELECT Name FROM Inv.Items WHERE Id = @ItemId), (SELECT MedicineFullName FROM Pharmacy.Medicines WHERE MedicineId = @MedicineId), (SELECT Name FROM Account.Fees WHERE Id = @SubServiceId));",
                connection, transaction);
            command.Parameters.AddWithValue("@ItemId", (object?)product.ItemId ?? DBNull.Value);
            command.Parameters.AddWithValue("@MedicineId", (object?)product.MedicineId ?? DBNull.Value);
            command.Parameters.AddWithValue("@SubServiceId", (object?)product.SubServiceId ?? DBNull.Value);
            var result = await command.ExecuteScalarAsync();
            return result as string ?? product.ToString();
        }

        private async Task<int?> GetAdjustmentStoreIdAsync(SqlConnection connection, SqlTransaction transaction, int stockAdjustmentId)
        {
            using var command = new SqlCommand("SELECT StoreId FROM Inv.StockAdjustments WHERE Id = @Id AND IsDeleted = 0;", connection, transaction);
            command.Parameters.AddWithValue("@Id", stockAdjustmentId);
            var result = await command.ExecuteScalarAsync();
            return result == null || result == DBNull.Value ? null : Convert.ToInt32(result);
        }

        private async Task<List<(ProductKey Product, int Type, decimal Quantity)>> GetActiveDetailsAsync(SqlConnection connection, SqlTransaction transaction, int stockAdjustmentId)
        {
            var details = new List<(ProductKey, int, decimal)>();
            using var command = new SqlCommand(
                "SELECT ItemId, MedicineId, SubServiceId, Type, Quantity FROM Inv.StockAdjustmentDetails WHERE StockAdjustmentId = @Id AND IsDeleted = 0;",
                connection, transaction);
            command.Parameters.AddWithValue("@Id", stockAdjustmentId);
            using var reader = await command.ExecuteReaderAsync();
            while (await reader.ReadAsync())
            {
                var product = new ProductKey(
                    reader.IsDBNull(0) ? null : reader.GetInt32(0),
                    reader.IsDBNull(1) ? null : reader.GetInt32(1),
                    reader.IsDBNull(2) ? null : reader.GetInt32(2));
                details.Add((product, reader.GetInt32(3), reader.GetDecimal(4)));
            }
            return details;
        }

        // Deducts stock, guarding against removing more than is actually on hand (same check
        // used for demand-request issuance). Reads/writes Pharmacy.PharmacyMedicinesStocks -
        // the live ledger, not Inv.Stocks (see Stock_Procedures.sql header for why).
        private async Task RemoveStockAsync(SqlConnection connection, SqlTransaction transaction, ProductKey product, string itemName, int storeId, int quantity)
        {
            int available;
            using (var selectCommand = new SqlCommand(
                "SELECT ISNULL(TotalItemsInStock, 0) FROM Pharmacy.PharmacyMedicinesStocks WHERE StoreId = @StoreId AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId));",
                connection, transaction))
            {
                product.AddParameters(selectCommand);
                selectCommand.Parameters.AddWithValue("@StoreId", storeId);
                var result = await selectCommand.ExecuteScalarAsync();
                available = result == null || result == DBNull.Value ? 0 : Convert.ToInt32(result);
            }

            if (available < quantity)
            {
                throw new InvalidOperationException($"Cannot decrease '{itemName}' by {quantity} - only {available} available in this store.");
            }

            using var updateCommand = new SqlCommand(
                "UPDATE Pharmacy.PharmacyMedicinesStocks SET TotalItemsInStock = TotalItemsInStock - @Quantity, ModifiedOn = GETDATE() WHERE StoreId = @StoreId AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId));",
                connection, transaction);
            product.AddParameters(updateCommand);
            updateCommand.Parameters.AddWithValue("@StoreId", storeId);
            updateCommand.Parameters.AddWithValue("@Quantity", quantity);
            await updateCommand.ExecuteNonQueryAsync();
        }

        // Credits stock, upserting since the store may never have held this item before.
        // No BranchId column on Pharmacy.PharmacyMedicinesStocks - @BranchId is accepted for
        // call-site compatibility but not written anywhere.
        private async Task AddStockAsync(SqlConnection connection, SqlTransaction transaction, ProductKey product, int storeId, int branchId, int quantity)
        {
            using var command = new SqlCommand(@"
IF EXISTS (SELECT 1 FROM Pharmacy.PharmacyMedicinesStocks WHERE StoreId = @StoreId AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId)))
    UPDATE Pharmacy.PharmacyMedicinesStocks
    SET TotalItemsInStock = ISNULL(TotalItemsInStock, 0) + @Quantity, ModifiedOn = GETDATE()
    WHERE StoreId = @StoreId AND ((@ItemId IS NOT NULL AND ItemId = @ItemId) OR (@MedicineId IS NOT NULL AND BranchMedicineId = @MedicineId) OR (@SubServiceId IS NOT NULL AND BranchSubServiceId = @SubServiceId));
ELSE
    INSERT INTO Pharmacy.PharmacyMedicinesStocks (ItemId, BranchMedicineId, BranchSubServiceId, TotalItemsInStock, MinimumPanicLevel, TotalItemsInTransition, TypeBit, StoreId, CreatedBy, CreatedOn)
    VALUES (@ItemId, @MedicineId, @SubServiceId, @Quantity, 0, 0,
        CASE WHEN @ItemId IS NOT NULL THEN 15 WHEN @MedicineId IS NOT NULL THEN 4 WHEN @SubServiceId IS NOT NULL THEN 5 ELSE NULL END,
        @StoreId, 1, GETDATE());", connection, transaction);
            product.AddParameters(command);
            command.Parameters.AddWithValue("@StoreId", storeId);
            command.Parameters.AddWithValue("@BranchId", branchId);
            command.Parameters.AddWithValue("@Quantity", quantity);
            await command.ExecuteNonQueryAsync();
        }

        private StockAdjustment MapToStockAdjustment(SqlDataReader reader)
        {
            return new StockAdjustment
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                Type = reader.GetInt32(reader.GetOrdinal("Type")),
                TypeName = reader.IsDBNull(reader.GetOrdinal("TypeName")) ? null : reader.GetString(reader.GetOrdinal("TypeName")),
                VoucherId = reader.IsDBNull(reader.GetOrdinal("VoucherId")) ? null : reader.GetInt32(reader.GetOrdinal("VoucherId")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                BranchName = reader.IsDBNull(reader.GetOrdinal("BranchName")) ? null : reader.GetString(reader.GetOrdinal("BranchName")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                CreatedByName = reader.IsDBNull(reader.GetOrdinal("CreatedByName")) ? null : reader.GetString(reader.GetOrdinal("CreatedByName")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                IsDeleted = reader.GetBoolean(reader.GetOrdinal("IsDeleted"))
            };
        }

        private StockAdjustmentDetail MapToStockAdjustmentDetail(SqlDataReader reader)
        {
            return new StockAdjustmentDetail
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                StockAdjustmentId = reader.GetInt32(reader.GetOrdinal("StockAdjustmentId")),
                ItemId = reader.IsDBNull(reader.GetOrdinal("ItemId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? null : reader.GetString(reader.GetOrdinal("ItemName")),
                MedicineId = reader.IsDBNull(reader.GetOrdinal("MedicineId")) ? null : reader.GetInt32(reader.GetOrdinal("MedicineId")),
                MedicineName = reader.IsDBNull(reader.GetOrdinal("MedicineName")) ? null : reader.GetString(reader.GetOrdinal("MedicineName")),
                SubServiceId = reader.IsDBNull(reader.GetOrdinal("SubServiceId")) ? null : reader.GetInt32(reader.GetOrdinal("SubServiceId")),
                SubServiceName = reader.IsDBNull(reader.GetOrdinal("SubServiceName")) ? null : reader.GetString(reader.GetOrdinal("SubServiceName")),
                Type = reader.GetInt32(reader.GetOrdinal("Type")),
                TypeName = reader.IsDBNull(reader.GetOrdinal("TypeName")) ? null : reader.GetString(reader.GetOrdinal("TypeName")),
                StockTypeId = reader.GetInt32(reader.GetOrdinal("StockTypeId")),
                StockTypeName = reader.IsDBNull(reader.GetOrdinal("StockTypeName")) ? null : reader.GetString(reader.GetOrdinal("StockTypeName")),
                Quantity = reader.GetDecimal(reader.GetOrdinal("Quantity")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                IsDeleted = reader.GetBoolean(reader.GetOrdinal("IsDeleted")),
                SaleValue = reader.IsDBNull(reader.GetOrdinal("SaleValue")) ? null : reader.GetDecimal(reader.GetOrdinal("SaleValue")),
                PurchaseValue = reader.IsDBNull(reader.GetOrdinal("PurchaseValue")) ? null : reader.GetDecimal(reader.GetOrdinal("PurchaseValue"))
            };
        }
    }
}
