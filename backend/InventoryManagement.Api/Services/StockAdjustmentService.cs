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

        public async Task<IEnumerable<StockAdjustmentView>> GetAllAsync(StockAdjustmentSearchRequest? request = null)
        {
            var stockAdjustments = new List<StockAdjustmentView>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockAdjustment_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                if (request != null)
                {
                    if (request.BranchId.HasValue)
                        command.Parameters.AddWithValue("@BranchId", request.BranchId.Value);
                    if (request.StoreId.HasValue)
                        command.Parameters.AddWithValue("@StoreId", request.StoreId.Value);
                    if (request.StartDate.HasValue)
                        command.Parameters.AddWithValue("@StartDate", request.StartDate.Value);
                    if (request.EndDate.HasValue)
                        command.Parameters.AddWithValue("@EndDate", request.EndDate.Value);
                }

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
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

            return stockAdjustments;
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
                        using var detailCommand = new SqlCommand("StockAdjustmentDetail_Insert", connection, transaction);
                        detailCommand.CommandType = CommandType.StoredProcedure;
                        var detailIdParam = new SqlParameter("@Id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                        detailCommand.Parameters.Add(detailIdParam);
                        detailCommand.Parameters.AddWithValue("@StockAdjustmentId", stockAdjustmentId);
                        detailCommand.Parameters.AddWithValue("@ItemId", detail.ItemId);
                        detailCommand.Parameters.AddWithValue("@Type", detail.Type);
                        detailCommand.Parameters.AddWithValue("@StockTypeId", detail.StockTypeId);
                        detailCommand.Parameters.AddWithValue("@Quantity", detail.Quantity);
                        detailCommand.Parameters.AddWithValue("@SaleValue", (object?)detail.SaleValue ?? DBNull.Value);
                        detailCommand.Parameters.AddWithValue("@BranchId", request.BranchId);
                        detailCommand.Parameters.AddWithValue("@CreatedById", (object?)request.CreatedById ?? DBNull.Value);
                        detailCommand.Parameters.AddWithValue("@CreatedOn", DateTime.UtcNow);

                        await detailCommand.ExecuteNonQueryAsync();
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
                        using var detailCommand = new SqlCommand("StockAdjustmentDetail_Insert", connection, transaction);
                        detailCommand.CommandType = CommandType.StoredProcedure;
                        var detailIdParam = new SqlParameter("@Id", SqlDbType.Int) { Direction = ParameterDirection.Output };
                        detailCommand.Parameters.Add(detailIdParam);
                        detailCommand.Parameters.AddWithValue("@StockAdjustmentId", request.Id);
                        detailCommand.Parameters.AddWithValue("@ItemId", detail.ItemId);
                        detailCommand.Parameters.AddWithValue("@Type", detail.Type);
                        detailCommand.Parameters.AddWithValue("@StockTypeId", detail.StockTypeId);
                        detailCommand.Parameters.AddWithValue("@Quantity", detail.Quantity);
                        detailCommand.Parameters.AddWithValue("@SaleValue", (object?)detail.SaleValue ?? DBNull.Value);
                        detailCommand.Parameters.AddWithValue("@BranchId", request.BranchId);
                        detailCommand.Parameters.AddWithValue("@CreatedById", (object?)request.ModifiedById ?? DBNull.Value);
                        detailCommand.Parameters.AddWithValue("@CreatedOn", DateTime.UtcNow);

                        await detailCommand.ExecuteNonQueryAsync();
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
                using var command = new SqlCommand("StockAdjustment_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                var result = await command.ExecuteNonQueryAsync();

                return result > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting stock adjustment with ID {Id}", id);
                throw;
            }
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
                ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? null : reader.GetString(reader.GetOrdinal("ItemName")),
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
