using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public class StockConsumptionService : IStockConsumptionService
    {
        private readonly string _connectionString;
        private readonly ILogger<StockConsumptionService> _logger;

        public StockConsumptionService(IConfiguration configuration, ILogger<StockConsumptionService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException("Connection string not found");
            _logger = logger;
        }

        public async Task<IEnumerable<StockConsumptionView>> GetAllAsync(StockConsumptionSearchRequest? request = null)
        {
            var stockConsumptions = new List<StockConsumptionView>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockConsumption_GetAll", connection)
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
                    stockConsumptions.Add(new StockConsumptionView
                    {
                        Id = reader.GetInt32(reader.GetOrdinal("Id")),
                        StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                        ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? null : reader.GetString(reader.GetOrdinal("ItemName")),
                        Type = reader.IsDBNull(reader.GetOrdinal("Type")) ? null : reader.GetString(reader.GetOrdinal("Type")),
                        StockType = reader.IsDBNull(reader.GetOrdinal("StockType")) ? null : reader.GetString(reader.GetOrdinal("StockType")),
                        Quantity = reader.GetDecimal(reader.GetOrdinal("Quantity")),
                        CreatedBy = reader.IsDBNull(reader.GetOrdinal("CreatedBy")) ? null : reader.GetString(reader.GetOrdinal("CreatedBy")),
                        CreatedOn = reader.IsDBNull(reader.GetOrdinal("CreatedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("CreatedOn"))
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock consumptions");
                throw;
            }

            return stockConsumptions;
        }

        public async Task<StockConsumption?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("StockConsumption_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    var stockConsumption = MapToStockConsumption(reader);

                    // Get details
                    if (await reader.NextResultAsync())
                    {
                        stockConsumption.Details = new List<StockConsumptionDetail>();
                        while (await reader.ReadAsync())
                        {
                            stockConsumption.Details.Add(MapToStockConsumptionDetail(reader));
                        }
                    }

                    return stockConsumption;
                }

                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock consumption with ID {Id}", id);
                throw;
            }
        }

        public async Task<StockConsumption> CreateAsync(StockConsumptionCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var transaction = connection.BeginTransaction();

                try
                {
                    // Insert main stock consumption
                    int stockConsumptionId;

                    using (var command = new SqlCommand("StockConsumption_Insert", connection, transaction))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@StoreId", request.StoreId);
                        command.Parameters.AddWithValue("@BranchId", request.BranchId);
                        command.Parameters.AddWithValue("@Type", request.Type);
                        command.Parameters.AddWithValue("@CreatedById", (object?)request.CreatedById ?? DBNull.Value);
                        command.Parameters.AddWithValue("@CreatedOn", DateTime.UtcNow);
                        command.Parameters.AddWithValue("@Remarks", (object?)request.Remarks ?? DBNull.Value);

                        var newId = await command.ExecuteScalarAsync();
                        stockConsumptionId = Convert.ToInt32(newId);
                    }

                    // Insert details
                    foreach (var detail in request.Details)
                    {
                        using var detailCommand = new SqlCommand("StockConsumptionDetail_Insert", connection, transaction);
                        detailCommand.CommandType = CommandType.StoredProcedure;
                        detailCommand.Parameters.AddWithValue("@StockConsumptionId", stockConsumptionId);
                        detailCommand.Parameters.AddWithValue("@StoreId", request.StoreId);
                        detailCommand.Parameters.AddWithValue("@ItemId", detail.ItemId);
                        detailCommand.Parameters.AddWithValue("@Type", detail.Type);
                        detailCommand.Parameters.AddWithValue("@StockTypeId", detail.StockTypeId);
                        detailCommand.Parameters.AddWithValue("@Quantity", detail.Quantity);
                        detailCommand.Parameters.AddWithValue("@BranchId", request.BranchId);
                        detailCommand.Parameters.AddWithValue("@CreatedById", (object?)request.CreatedById ?? DBNull.Value);
                        detailCommand.Parameters.AddWithValue("@CreatedOn", DateTime.UtcNow);

                        await detailCommand.ExecuteScalarAsync();
                    }

                    await transaction.CommitAsync();

                    return await GetByIdAsync(stockConsumptionId) ?? throw new Exception("Failed to retrieve created stock consumption");
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating stock consumption");
                throw;
            }
        }

        public async Task<StockConsumption> UpdateAsync(StockConsumptionUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                using var transaction = connection.BeginTransaction();

                try
                {
                    // Update main stock consumption
                    using (var command = new SqlCommand("StockConsumption_Update", connection, transaction))
                    {
                        command.CommandType = CommandType.StoredProcedure;
                        command.Parameters.AddWithValue("@Id", request.Id);
                        command.Parameters.AddWithValue("@StoreId", request.StoreId);
                        command.Parameters.AddWithValue("@BranchId", request.BranchId);
                        command.Parameters.AddWithValue("@Type", request.Type);
                        command.Parameters.AddWithValue("@ModifiedById", (object?)request.ModifiedById ?? DBNull.Value);
                        command.Parameters.AddWithValue("@ModifiedOn", DateTime.UtcNow);
                        command.Parameters.AddWithValue("@Remarks", (object?)request.Remarks ?? DBNull.Value);

                        await command.ExecuteNonQueryAsync();
                    }

                    // Delete existing details
                    using (var deleteCommand = new SqlCommand("StockConsumptionDetail_DeleteByConsumptionId", connection, transaction))
                    {
                        deleteCommand.CommandType = CommandType.StoredProcedure;
                        deleteCommand.Parameters.AddWithValue("@StockConsumptionId", request.Id);
                        await deleteCommand.ExecuteNonQueryAsync();
                    }

                    // Insert new details
                    foreach (var detail in request.Details)
                    {
                        using var detailCommand = new SqlCommand("StockConsumptionDetail_Insert", connection, transaction);
                        detailCommand.CommandType = CommandType.StoredProcedure;
                        detailCommand.Parameters.AddWithValue("@StockConsumptionId", request.Id);
                        detailCommand.Parameters.AddWithValue("@StoreId", request.StoreId);
                        detailCommand.Parameters.AddWithValue("@ItemId", detail.ItemId);
                        detailCommand.Parameters.AddWithValue("@Type", detail.Type);
                        detailCommand.Parameters.AddWithValue("@StockTypeId", detail.StockTypeId);
                        detailCommand.Parameters.AddWithValue("@Quantity", detail.Quantity);
                        detailCommand.Parameters.AddWithValue("@BranchId", request.BranchId);
                        detailCommand.Parameters.AddWithValue("@CreatedById", (object?)request.ModifiedById ?? DBNull.Value);
                        detailCommand.Parameters.AddWithValue("@CreatedOn", DateTime.UtcNow);

                        await detailCommand.ExecuteScalarAsync();
                    }

                    await transaction.CommitAsync();

                    return await GetByIdAsync(request.Id) ?? throw new Exception("Failed to retrieve updated stock consumption");
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating stock consumption");
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                await connection.OpenAsync();

                // StockConsumption_Delete has SET NOCOUNT ON, so ExecuteNonQueryAsync's
                // return value is unreliable (-1, not the actual row count) - same bug
                // fixed for StockAdjustment_Delete. Check existence up front instead and
                // use that as the source of truth for whether this delete succeeded.
                using (var existsCommand = new SqlCommand(
                    "SELECT 1 FROM Inv.StockConsumptions WHERE Id = @Id AND IsDeleted = 0;", connection))
                {
                    existsCommand.Parameters.AddWithValue("@Id", id);
                    var exists = await existsCommand.ExecuteScalarAsync();
                    if (exists == null)
                    {
                        return false;
                    }
                }

                using (var command = new SqlCommand("StockConsumption_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                })
                {
                    command.Parameters.AddWithValue("@Id", id);
                    await command.ExecuteNonQueryAsync();
                }

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting stock consumption with ID {Id}", id);
                throw;
            }
        }

        private StockConsumption MapToStockConsumption(SqlDataReader reader)
        {
            return new StockConsumption
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                Type = reader.GetInt32(reader.GetOrdinal("Type")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                BranchName = reader.IsDBNull(reader.GetOrdinal("BranchName")) ? null : reader.GetString(reader.GetOrdinal("BranchName")),
                VoucherId = reader.IsDBNull(reader.GetOrdinal("VoucherId")) ? null : reader.GetInt32(reader.GetOrdinal("VoucherId")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                CreatedByName = reader.IsDBNull(reader.GetOrdinal("CreatedByName")) ? null : reader.GetString(reader.GetOrdinal("CreatedByName")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                IsDeleted = reader.GetBoolean(reader.GetOrdinal("IsDeleted")),
                Remarks = reader.IsDBNull(reader.GetOrdinal("Remarks")) ? null : reader.GetString(reader.GetOrdinal("Remarks"))
            };
        }

        private StockConsumptionDetail MapToStockConsumptionDetail(SqlDataReader reader)
        {
            return new StockConsumptionDetail
            {
                Id = reader.GetInt32(reader.GetOrdinal("Id")),
                StockConsumptionId = reader.IsDBNull(reader.GetOrdinal("StockConsumptionId")) ? null : reader.GetInt32(reader.GetOrdinal("StockConsumptionId")),
                StoreId = reader.GetInt32(reader.GetOrdinal("StoreId")),
                StoreName = reader.IsDBNull(reader.GetOrdinal("StoreName")) ? null : reader.GetString(reader.GetOrdinal("StoreName")),
                ItemId = reader.GetInt32(reader.GetOrdinal("ItemId")),
                ItemName = reader.IsDBNull(reader.GetOrdinal("ItemName")) ? null : reader.GetString(reader.GetOrdinal("ItemName")),
                Type = reader.GetInt32(reader.GetOrdinal("Type")),
                StockTypeId = reader.GetInt32(reader.GetOrdinal("StockTypeId")),
                StockTypeName = reader.IsDBNull(reader.GetOrdinal("StockTypeName")) ? null : reader.GetString(reader.GetOrdinal("StockTypeName")),
                Quantity = reader.GetDecimal(reader.GetOrdinal("Quantity")),
                BranchId = reader.GetInt32(reader.GetOrdinal("BranchId")),
                IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive")),
                CreatedById = reader.IsDBNull(reader.GetOrdinal("CreatedById")) ? null : reader.GetInt32(reader.GetOrdinal("CreatedById")),
                CreatedOn = reader.GetDateTime(reader.GetOrdinal("CreatedOn")),
                ModifiedById = reader.IsDBNull(reader.GetOrdinal("ModifiedById")) ? null : reader.GetInt32(reader.GetOrdinal("ModifiedById")),
                ModifiedOn = reader.IsDBNull(reader.GetOrdinal("ModifiedOn")) ? null : reader.GetDateTime(reader.GetOrdinal("ModifiedOn")),
                IsDeleted = reader.GetBoolean(reader.GetOrdinal("IsDeleted"))
            };
        }
    }
}
