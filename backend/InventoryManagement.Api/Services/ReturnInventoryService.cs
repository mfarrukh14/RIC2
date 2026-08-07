using Microsoft.Data.SqlClient;
using InventoryManagement.API.Models;
using System.Data;

namespace InventoryManagement.API.Services
{
    public class ReturnInventoryService : IReturnInventoryService
    {
        private readonly string _connectionString;
        private readonly ILogger<ReturnInventoryService> _logger;

        public ReturnInventoryService(IConfiguration configuration, ILogger<ReturnInventoryService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));
            _logger = logger;
        }

        public async Task<List<ReturnInventory>> GetAllAsync(ReturnInventoryFilterRequest? filter = null)
        {
            var returns = new List<ReturnInventory>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("ReturnInventory_GetAll", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@BranchId", (object?)filter?.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", (object?)filter?.StoreId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemTypeId", (object?)filter?.ItemTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@StartDate", (object?)filter?.StartDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", (object?)filter?.EndDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@PurchaseOrderNo", (object?)filter?.PurchaseOrderNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemId", (object?)filter?.ItemId ?? DBNull.Value);
                command.Parameters.AddWithValue("@InventoryNo", (object?)filter?.InventoryNo ?? DBNull.Value);

                using var reader = await command.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                {
                    returns.Add(MapToReturnInventory(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching return inventory records");
                throw;
            }

            return returns;
        }

        public async Task<ReturnInventory?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("ReturnInventory_GetById", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@Id", id);

                using var reader = await command.ExecuteReaderAsync();
                if (await reader.ReadAsync())
                {
                    return MapToReturnInventory(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching return inventory with ID {Id}", id);
                throw;
            }

            return null;
        }

        // Processes an actual return: validates stock is on hand, decrements it,
        // optionally decrements the matching Purchase Order / GRN line the stock
        // originally came in on, then records the return - all in one transaction
        // so a failure at any step leaves nothing partially applied.
        public async Task<ReturnInventory> CreateAsync(ReturnInventoryCreateRequest request, int branchId, int createdById)
        {
            if (request.StoreId is not int storeId)
            {
                throw new InvalidOperationException("Store is required.");
            }

            if (request.ItemTypeId is not int itemTypeId)
            {
                throw new InvalidOperationException("Item Type is required.");
            }

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();
                using var transaction = connection.BeginTransaction();

                try
                {
                    var itemName = await GetItemNameAsync(connection, transaction, request.ItemId);

                    await DecrementStoreStockAsync(connection, transaction, request.ItemId, itemName, storeId, request.ReturnQuantity);

                    if (!string.IsNullOrWhiteSpace(request.PurchaseOrderNo))
                    {
                        await ReducePurchaseOrderQuantityAsync(connection, transaction, request.PurchaseOrderNo.Trim(), request.ItemId, itemName, request.ReturnQuantity);
                    }

                    if (!string.IsNullOrWhiteSpace(request.InventoryNo))
                    {
                        await ReduceGrnRemainingQuantityAsync(connection, transaction, request.InventoryNo.Trim(), request.ItemId, itemName, request.ReturnQuantity);
                    }

                    int newId;
                    using (var command = new SqlCommand("ReturnInventory_Insert", connection, transaction))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@InventoryNo", DBNull.Value);
                        command.Parameters.AddWithValue("@PurchaseOrderNo", (object?)request.PurchaseOrderNo ?? DBNull.Value);
                        command.Parameters.AddWithValue("@BranchId", branchId);
                        command.Parameters.AddWithValue("@StoreId", storeId);
                        command.Parameters.AddWithValue("@ItemTypeId", itemTypeId);
                        command.Parameters.AddWithValue("@ItemId", request.ItemId);
                        command.Parameters.AddWithValue("@ReturnQuantity", request.ReturnQuantity);
                        command.Parameters.AddWithValue("@VendorId", (object?)request.VendorId ?? DBNull.Value);
                        command.Parameters.AddWithValue("@ReturnDate", (object?)request.ReturnDate ?? DBNull.Value);
                        command.Parameters.AddWithValue("@Reason", (object?)request.Reason ?? DBNull.Value);
                        command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);
                        command.Parameters.AddWithValue("@CreatedById", createdById);

                        var result = await command.ExecuteScalarAsync();
                        newId = Convert.ToInt32(result);
                    }

                    await transaction.CommitAsync();

                    return await GetByIdAsync(newId) ?? throw new Exception("Failed to retrieve created return inventory");
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
                _logger.LogError(ex, "Error creating return inventory");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, ReturnInventoryUpdateRequest request, int modifiedById)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("ReturnInventory_Update", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@PurchaseOrderNo", (object?)request.PurchaseOrderNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@StoreId", request.StoreId);
                command.Parameters.AddWithValue("@ItemTypeId", (object?)request.ItemTypeId ?? DBNull.Value);
                command.Parameters.AddWithValue("@VendorId", (object?)request.VendorId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ReturnDate", request.ReturnDate);
                command.Parameters.AddWithValue("@Reason", (object?)request.Reason ?? DBNull.Value);
                command.Parameters.AddWithValue("@Notes", (object?)request.Notes ?? DBNull.Value);
                command.Parameters.AddWithValue("@ModifiedById", modifiedById);

                var rowsAffected = await command.ExecuteScalarAsync();
                return Convert.ToInt32(rowsAffected) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating return inventory with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id, int modifiedById)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("ReturnInventory_Delete", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;
                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@ModifiedById", modifiedById);

                var rowsAffected = await command.ExecuteScalarAsync();
                return Convert.ToInt32(rowsAffected) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting return inventory with ID {Id}", id);
                throw;
            }
        }

        public async Task<ReturnInventoryLookupData> GetLookupDataAsync()
        {
            var lookupData = new ReturnInventoryLookupData();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var command = new SqlCommand("ReturnInventory_GetLookupData", connection);
                command.CommandType = System.Data.CommandType.StoredProcedure;

                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    lookupData.Branches.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.Stores.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.ItemTypes.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }

                await reader.NextResultAsync();
                while (await reader.ReadAsync())
                {
                    lookupData.Vendors.Add(new LookupItem
                    {
                        Id = reader.GetInt32(0),
                        Name = reader.GetString(1)
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error fetching return inventory lookup data");
                throw;
            }

            return lookupData;
        }

        private async Task<string> GetItemNameAsync(SqlConnection connection, SqlTransaction transaction, int itemId)
        {
            using var command = new SqlCommand("SELECT Name FROM Inv.Items WHERE Id = @ItemId;", connection, transaction);
            command.Parameters.AddWithValue("@ItemId", itemId);
            var result = await command.ExecuteScalarAsync();
            return result as string ?? $"Item #{itemId}";
        }

        // Guards against returning more than is actually on hand, same check used
        // for stock adjustments and demand-request issuance. Reads/writes
        // Pharmacy.PharmacyMedicinesStocks - the live ledger, not Inv.Stocks (see
        // Stock_Procedures.sql header for why).
        private async Task DecrementStoreStockAsync(SqlConnection connection, SqlTransaction transaction, int itemId, string itemName, int storeId, int quantity)
        {
            int available;
            using (var selectCommand = new SqlCommand(
                "SELECT ISNULL(TotalItemsInStock, 0) FROM Pharmacy.PharmacyMedicinesStocks WHERE ItemId = @ItemId AND StoreId = @StoreId;",
                connection, transaction))
            {
                selectCommand.Parameters.AddWithValue("@ItemId", itemId);
                selectCommand.Parameters.AddWithValue("@StoreId", storeId);
                var result = await selectCommand.ExecuteScalarAsync();
                available = result == null || result == DBNull.Value ? 0 : Convert.ToInt32(result);
            }

            if (available < quantity)
            {
                throw new InvalidOperationException($"Cannot return {quantity} of '{itemName}' - only {available} in stock at this store.");
            }

            using var updateCommand = new SqlCommand(
                "UPDATE Pharmacy.PharmacyMedicinesStocks SET TotalItemsInStock = TotalItemsInStock - @Quantity, ModifiedOn = GETDATE() WHERE ItemId = @ItemId AND StoreId = @StoreId;",
                connection, transaction);
            updateCommand.Parameters.AddWithValue("@ItemId", itemId);
            updateCommand.Parameters.AddWithValue("@StoreId", storeId);
            updateCommand.Parameters.AddWithValue("@Quantity", quantity);
            await updateCommand.ExecuteNonQueryAsync();
        }

        // When the return is tied to a Purchase Order number, the returned quantity
        // is removed from that PO's line for the item (deactivating the line if it
        // hits zero) and from the PO's total, so the PO no longer reflects stock
        // that has since gone back out.
        private async Task ReducePurchaseOrderQuantityAsync(SqlConnection connection, SqlTransaction transaction, string purchaseOrderNo, int itemId, string itemName, int quantity)
        {
            int purchaseOrderId;
            using (var poCommand = new SqlCommand(
                "SELECT TOP (1) PurchaseOrderId FROM Inv.PurchaseOrders WHERE PONumber = @PONumber AND IsActive = 1;",
                connection, transaction))
            {
                poCommand.Parameters.AddWithValue("@PONumber", purchaseOrderNo);
                var result = await poCommand.ExecuteScalarAsync();
                if (result == null || result == DBNull.Value)
                {
                    throw new InvalidOperationException($"No Purchase Order found with number '{purchaseOrderNo}'.");
                }
                purchaseOrderId = Convert.ToInt32(result);
            }

            int lineId;
            decimal lineQuantity;
            using (var lineCommand = new SqlCommand(
                "SELECT TOP (1) Id, UnitQuantity FROM Inv.PurchaseOrderItems WHERE PurchaseOrderId = @PurchaseOrderId AND ItemId = @ItemId AND IsActive = 1;",
                connection, transaction))
            {
                lineCommand.Parameters.AddWithValue("@PurchaseOrderId", purchaseOrderId);
                lineCommand.Parameters.AddWithValue("@ItemId", itemId);
                using var reader = await lineCommand.ExecuteReaderAsync();
                if (!await reader.ReadAsync())
                {
                    throw new InvalidOperationException($"Item '{itemName}' was not found on Purchase Order '{purchaseOrderNo}'.");
                }
                lineId = reader.GetInt32(0);
                lineQuantity = reader.GetDecimal(1);
            }

            if (lineQuantity <= quantity)
            {
                using var deactivateCommand = new SqlCommand(
                    "UPDATE Inv.PurchaseOrderItems SET UnitQuantity = 0, IsActive = 0, ModifiedOn = GETDATE() WHERE Id = @Id;",
                    connection, transaction);
                deactivateCommand.Parameters.AddWithValue("@Id", lineId);
                await deactivateCommand.ExecuteNonQueryAsync();
            }
            else
            {
                using var updateCommand = new SqlCommand(
                    "UPDATE Inv.PurchaseOrderItems SET UnitQuantity = UnitQuantity - @Quantity, ModifiedOn = GETDATE() WHERE Id = @Id;",
                    connection, transaction);
                updateCommand.Parameters.AddWithValue("@Id", lineId);
                updateCommand.Parameters.AddWithValue("@Quantity", quantity);
                await updateCommand.ExecuteNonQueryAsync();
            }

            using var totalCommand = new SqlCommand(
                "UPDATE Inv.PurchaseOrders SET TotalQuantity = CASE WHEN TotalQuantity - @Quantity < 0 THEN 0 ELSE TotalQuantity - @Quantity END, ModifiedOn = GETDATE() WHERE PurchaseOrderId = @PurchaseOrderId;",
                connection, transaction);
            totalCommand.Parameters.AddWithValue("@PurchaseOrderId", purchaseOrderId);
            totalCommand.Parameters.AddWithValue("@Quantity", quantity);
            await totalCommand.ExecuteNonQueryAsync();
        }

        // When the return is tied to a GRN invoice number, the returned quantity is
        // removed from that GRN line's RemainingQuantity for the item - ReceivedQuantity
        // is left untouched since it's the historical audit record of what actually came in.
        private async Task ReduceGrnRemainingQuantityAsync(SqlConnection connection, SqlTransaction transaction, string inventoryNo, int itemId, string itemName, int quantity)
        {
            int grnId;
            using (var grnCommand = new SqlCommand(
                "SELECT TOP (1) Id FROM Inv.GoodsReceivingNotes WHERE InvoiceNo = @InvoiceNo AND IsActive = 1;",
                connection, transaction))
            {
                grnCommand.Parameters.AddWithValue("@InvoiceNo", inventoryNo);
                var result = await grnCommand.ExecuteScalarAsync();
                if (result == null || result == DBNull.Value)
                {
                    throw new InvalidOperationException($"No goods receiving note found with invoice number '{inventoryNo}'.");
                }
                grnId = Convert.ToInt32(result);
            }

            int lineId;
            int remaining;
            using (var lineCommand = new SqlCommand(
                "SELECT TOP (1) Id, ISNULL(RemainingQuantity, 0) FROM Inv.GRNItems WHERE GRNId = @GRNId AND ItemId = @ItemId;",
                connection, transaction))
            {
                lineCommand.Parameters.AddWithValue("@GRNId", grnId);
                lineCommand.Parameters.AddWithValue("@ItemId", itemId);
                using var reader = await lineCommand.ExecuteReaderAsync();
                if (!await reader.ReadAsync())
                {
                    throw new InvalidOperationException($"Item '{itemName}' was not found on GRN invoice '{inventoryNo}'.");
                }
                lineId = reader.GetInt32(0);
                remaining = reader.GetInt32(1);
            }

            if (remaining < quantity)
            {
                throw new InvalidOperationException($"Cannot return {quantity} of '{itemName}' against invoice '{inventoryNo}' - only {remaining} remaining on that GRN.");
            }

            using var updateCommand = new SqlCommand(
                "UPDATE Inv.GRNItems SET RemainingQuantity = RemainingQuantity - @Quantity WHERE Id = @Id;",
                connection, transaction);
            updateCommand.Parameters.AddWithValue("@Id", lineId);
            updateCommand.Parameters.AddWithValue("@Quantity", quantity);
            await updateCommand.ExecuteNonQueryAsync();
        }

        private ReturnInventory MapToReturnInventory(SqlDataReader reader)
        {
            return new ReturnInventory
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                InventoryNo = reader.IsDBNull(reader.GetOrdinal("InventoryNo")) ? null : reader.GetString(reader.GetOrdinal("InventoryNo")),
                PurchaseOrderNo = reader.IsDBNull(reader.GetOrdinal("PurchaseOrderNo")) ? null : reader.GetString(reader.GetOrdinal("PurchaseOrderNo")),
                BranchId = reader.IsDBNull(reader.GetOrdinal("BranchId")) ? null : reader.GetInt32(reader.GetOrdinal("BranchId")),
                BranchName = reader.IsDBNull(reader.GetOrdinal("BranchName")) ? null : reader.GetString(reader.GetOrdinal("BranchName")),
                StoreId = reader.IsDBNull(reader.GetOrdinal("StoreId")) ? null : reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                ItemTypeId = reader.IsDBNull(reader.GetOrdinal("ItemTypeId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemTypeId")),
                ItemTypeName = reader.IsDBNull(reader.GetOrdinal("ItemTypeName")) ? null : reader.GetString(reader.GetOrdinal("ItemTypeName")),
                ItemId = reader.IsDBNull(reader.GetOrdinal("ItemId")) ? null : reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? null : reader.GetString(reader.GetOrdinal("ItemName")),
                ReturnQuantity = reader.GetInt32(reader.GetOrdinal("ReturnQuantity")),
                StockTypeId = reader.IsDBNull(reader.GetOrdinal("StockTypeId")) ? null : reader.GetInt32(reader.GetOrdinal("StockTypeId")),
                StockTypeName = reader.IsDBNull(reader.GetOrdinal("StockTypeName")) ? null : reader.GetString(reader.GetOrdinal("StockTypeName")),
                VendorId = reader.IsDBNull(reader.GetOrdinal("VendorId")) ? null : reader.GetInt32(reader.GetOrdinal("VendorId")),
                VendorName = reader.IsDBNull(reader.GetOrdinal("VendorName")) ? null : reader.GetString(reader.GetOrdinal("VendorName")),
                ReturnDate = reader.GetDateTime(reader.GetOrdinal("ReturnDate")),
                Reason = reader.IsDBNull(reader.GetOrdinal("Reason")) ? null : reader.GetString(reader.GetOrdinal("Reason")),
                Notes = reader.IsDBNull(reader.GetOrdinal("Notes")) ? null : reader.GetString(reader.GetOrdinal("Notes")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn"))
            };
        }
    }
}
