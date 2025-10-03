using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using System.Data;

namespace InventoryManagement.Api.Services
{
    public class AssetAllocationService : IAssetAllocationService
    {
        private readonly string _connectionString;
        private readonly ILogger<AssetAllocationService> _logger;

        public AssetAllocationService(IConfiguration configuration, ILogger<AssetAllocationService> logger)
        {
            _connectionString = configuration.GetConnectionString("DefaultConnection") 
                ?? throw new ArgumentNullException("Connection string not found");
            _logger = logger;
        }

        public async Task<IEnumerable<AssetAllocation>> GetAllAsync()
        {
            var assetAllocations = new List<AssetAllocation>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("AssetAllocation_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    assetAllocations.Add(MapToAssetAllocation(reader));
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving asset allocations");
                throw;
            }

            return assetAllocations;
        }

        public async Task<AssetAllocation?> GetByIdAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("AssetAllocation_GetById", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                if (await reader.ReadAsync())
                {
                    return MapToAssetAllocation(reader);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving asset allocation with ID {Id}", id);
                throw;
            }

            return null;
        }

        public async Task<int> CreateAsync(AssetAllocationCreateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("AssetAllocation_Insert", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Remarks", (object?)request.Remarks ?? DBNull.Value);
                command.Parameters.AddWithValue("@AllocatedDate", request.AllocatedDate);
                command.Parameters.AddWithValue("@UserId", (object?)request.UserId ?? DBNull.Value);
                command.Parameters.AddWithValue("@DepartmentId", (object?)request.DepartmentId ?? DBNull.Value);
                command.Parameters.AddWithValue("@SubDepartmentId", (object?)request.SubDepartmentId ?? DBNull.Value);
                command.Parameters.AddWithValue("@RoomId", (object?)request.RoomId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemId", (object?)request.ItemId ?? DBNull.Value);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@Quantity", request.Quantity);
                command.Parameters.AddWithValue("@InventoryItemId", (object?)request.InventoryItemId ?? DBNull.Value);
                command.Parameters.AddWithValue("@SysBatchNo", (object?)request.SysBatchNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@BatchNo", (object?)request.BatchNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@CreatedById", 1); // TODO: Get from current user
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                var result = await command.ExecuteScalarAsync();
                return Convert.ToInt32(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating asset allocation");
                throw;
            }
        }

        public async Task<bool> UpdateAsync(int id, AssetAllocationUpdateRequest request)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("AssetAllocation_Update", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@Remarks", (object?)request.Remarks ?? DBNull.Value);
                command.Parameters.AddWithValue("@AllocatedDate", request.AllocatedDate);
                command.Parameters.AddWithValue("@ReturnDate", (object?)request.ReturnDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@UserId", (object?)request.UserId ?? DBNull.Value);
                command.Parameters.AddWithValue("@DepartmentId", (object?)request.DepartmentId ?? DBNull.Value);
                command.Parameters.AddWithValue("@SubDepartmentId", (object?)request.SubDepartmentId ?? DBNull.Value);
                command.Parameters.AddWithValue("@RoomId", (object?)request.RoomId ?? DBNull.Value);
                command.Parameters.AddWithValue("@ItemId", (object?)request.ItemId ?? DBNull.Value);
                command.Parameters.AddWithValue("@BranchId", (object?)request.BranchId ?? DBNull.Value);
                command.Parameters.AddWithValue("@IsReturn", request.IsReturn);
                command.Parameters.AddWithValue("@ReturnRemarks", (object?)request.ReturnRemarks ?? DBNull.Value);
                command.Parameters.AddWithValue("@Quantity", request.Quantity);
                command.Parameters.AddWithValue("@InventoryItemId", (object?)request.InventoryItemId ?? DBNull.Value);
                command.Parameters.AddWithValue("@SysBatchNo", (object?)request.SysBatchNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@BatchNo", (object?)request.BatchNo ?? DBNull.Value);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user
                command.Parameters.AddWithValue("@IsActive", request.IsActive);

                await connection.OpenAsync();
                var affectedRows = await command.ExecuteScalarAsync();
                return Convert.ToInt32(affectedRows) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating asset allocation with ID {Id}", id);
                throw;
            }
        }

        public async Task<bool> DeleteAsync(int id)
        {
            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("AssetAllocation_Delete", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Id", id);
                command.Parameters.AddWithValue("@ModifiedById", 1); // TODO: Get from current user

                await connection.OpenAsync();
                var affectedRows = await command.ExecuteScalarAsync();
                return Convert.ToInt32(affectedRows) > 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting asset allocation with ID {Id}", id);
                throw;
            }
        }

        public async Task<IEnumerable<User>> GetUsersAsync()
        {
            var users = new List<User>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("User_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    users.Add(new User
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name"),
                        Email = reader.IsDBNull("Email") ? null : reader.GetString("Email"),
                        UserName = reader.IsDBNull("UserName") ? null : reader.GetString("UserName"),
                        Department = reader.IsDBNull("Department") ? null : reader.GetString("Department"),
                        Designation = reader.IsDBNull("Designation") ? null : reader.GetString("Designation"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving users");
                throw;
            }

            return users;
        }

        public async Task<IEnumerable<Room>> GetRoomsAsync()
        {
            var rooms = new List<Room>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Room_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    rooms.Add(new Room
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name"),
                        Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                        Floor = reader.IsDBNull("Floor") ? null : reader.GetString("Floor"),
                        Building = reader.IsDBNull("Building") ? null : reader.GetString("Building"),
                        Capacity = reader.IsDBNull("Capacity") ? null : reader.GetInt32("Capacity"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rooms");
                throw;
            }

            return rooms;
        }

        public async Task<IEnumerable<Department>> GetDepartmentsAsync()
        {
            var departments = new List<Department>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Department_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    departments.Add(new Department
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name"),
                        Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                        Head = reader.IsDBNull("Head") ? null : reader.GetString("Head"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving departments");
                throw;
            }

            return departments;
        }

        public async Task<IEnumerable<SubDepartment>> GetSubDepartmentsAsync()
        {
            var subDepartments = new List<SubDepartment>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("SubDepartment_GetAll", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    subDepartments.Add(new SubDepartment
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name"),
                        Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                        DepartmentId = reader.IsDBNull("DepartmentId") ? null : reader.GetInt32("DepartmentId"),
                        DepartmentName = reader.IsDBNull("DepartmentName") ? null : reader.GetString("DepartmentName"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sub-departments");
                throw;
            }

            return subDepartments;
        }

        public async Task<IEnumerable<InventoryItem>> GetAvailableInventoryItemsAsync()
        {
            var items = new List<InventoryItem>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("InventoryItem_GetAvailable", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    items.Add(new InventoryItem
                    {
                        Id = reader.GetInt32("Id"),
                        Name = reader.GetString("Name"),
                        Description = reader.IsDBNull("Description") ? null : reader.GetString("Description"),
                        SerialNumber = reader.IsDBNull("SerialNumber") ? null : reader.GetString("SerialNumber"),
                        Model = reader.IsDBNull("Model") ? null : reader.GetString("Model"),
                        BrandId = reader.IsDBNull("BrandId") ? null : reader.GetInt32("BrandId"),
                        BrandName = reader.IsDBNull("BrandName") ? null : reader.GetString("BrandName"),
                        ItemTypeId = reader.IsDBNull("ItemTypeId") ? null : reader.GetInt32("ItemTypeId"),
                        ItemTypeName = reader.IsDBNull("ItemTypeName") ? null : reader.GetString("ItemTypeName"),
                        ItemUnitId = reader.IsDBNull("ItemUnitId") ? null : reader.GetInt32("ItemUnitId"),
                        ItemUnitName = reader.IsDBNull("ItemUnitName") ? null : reader.GetString("ItemUnitName"),
                        ManufacturerId = reader.IsDBNull("ManufacturerId") ? null : reader.GetInt32("ManufacturerId"),
                        ManufacturerName = reader.IsDBNull("ManufacturerName") ? null : reader.GetString("ManufacturerName"),
                        PurchaseDate = reader.IsDBNull("PurchaseDate") ? null : reader.GetDateTime("PurchaseDate"),
                        PurchasePrice = reader.IsDBNull("PurchasePrice") ? null : reader.GetDecimal("PurchasePrice"),
                        CurrentValue = reader.IsDBNull("CurrentValue") ? null : reader.GetDecimal("CurrentValue"),
                        Condition = reader.IsDBNull("Condition") ? null : reader.GetString("Condition"),
                        Status = reader.IsDBNull("Status") ? null : reader.GetString("Status"),
                        BranchId = reader.IsDBNull("BranchId") ? null : reader.GetInt32("BranchId"),
                        BranchName = reader.IsDBNull("BranchName") ? null : reader.GetString("BranchName"),
                        IsActive = reader.GetBoolean("IsActive")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving available inventory items");
                throw;
            }

            return items;
        }

        public async Task<IEnumerable<AssetAllocationReport>> GetReportAsync(AssetAllocationReportFilter filter)
        {
            var reports = new List<AssetAllocationReport>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("AssetAllocation_GetReport", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@StartDate", (object?)filter.StartDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@EndDate", (object?)filter.EndDate ?? DBNull.Value);
                command.Parameters.AddWithValue("@AllocationType", filter.AllocationType);
                command.Parameters.AddWithValue("@RoomId", (object?)filter.RoomId ?? DBNull.Value);
                command.Parameters.AddWithValue("@UserId", (object?)filter.UserId ?? DBNull.Value);
                command.Parameters.AddWithValue("@AssetId", (object?)filter.AssetId ?? DBNull.Value);
                command.Parameters.AddWithValue("@Building", (object?)filter.Building ?? DBNull.Value);
                command.Parameters.AddWithValue("@Floor", (object?)filter.Floor ?? DBNull.Value);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    reports.Add(new AssetAllocationReport
                    {
                        Id = reader.GetInt32("Id"),
                        AllocatedDate = reader.GetDateTime("AllocatedDate"),
                        ReturnDate = reader.IsDBNull("ReturnDate") ? null : reader.GetDateTime("ReturnDate"),
                        Quantity = reader.GetInt32("Quantity"),
                        Remarks = reader.IsDBNull("Remarks") ? null : reader.GetString("Remarks"),
                        IsReturn = reader.GetBoolean("IsReturn"),
                        ReturnRemarks = reader.IsDBNull("ReturnRemarks") ? null : reader.GetString("ReturnRemarks"),
                        AssetId = reader.IsDBNull("AssetId") ? null : reader.GetInt32("AssetId"),
                        AssetName = reader.IsDBNull("AssetName") ? null : reader.GetString("AssetName"),
                        SerialNumber = reader.IsDBNull("SerialNumber") ? null : reader.GetString("SerialNumber"),
                        Model = reader.IsDBNull("Model") ? null : reader.GetString("Model"),
                        UnitPrice = reader.IsDBNull("UnitPrice") ? null : reader.GetDecimal("UnitPrice"),
                        TotalPrice = reader.IsDBNull("TotalPrice") ? null : reader.GetDecimal("TotalPrice"),
                        UserId = reader.IsDBNull("UserId") ? null : reader.GetInt32("UserId"),
                        UserName = reader.IsDBNull("UserName") ? null : reader.GetString("UserName"),
                        UserEmail = reader.IsDBNull("UserEmail") ? null : reader.GetString("UserEmail"),
                        UserDepartment = reader.IsDBNull("UserDepartment") ? null : reader.GetString("UserDepartment"),
                        UserDesignation = reader.IsDBNull("UserDesignation") ? null : reader.GetString("UserDesignation"),
                        RoomId = reader.IsDBNull("RoomId") ? null : reader.GetInt32("RoomId"),
                        RoomName = reader.IsDBNull("RoomName") ? null : reader.GetString("RoomName"),
                        Building = reader.IsDBNull("Building") ? null : reader.GetString("Building"),
                        Floor = reader.IsDBNull("Floor") ? null : reader.GetString("Floor"),
                        RoomDescription = reader.IsDBNull("RoomDescription") ? null : reader.GetString("RoomDescription"),
                        DepartmentId = reader.IsDBNull("DepartmentId") ? null : reader.GetInt32("DepartmentId"),
                        DepartmentName = reader.IsDBNull("DepartmentName") ? null : reader.GetString("DepartmentName"),
                        SubDepartmentId = reader.IsDBNull("SubDepartmentId") ? null : reader.GetInt32("SubDepartmentId"),
                        SubDepartmentName = reader.IsDBNull("SubDepartmentName") ? null : reader.GetString("SubDepartmentName"),
                        BranchId = reader.IsDBNull("BranchId") ? null : reader.GetInt32("BranchId"),
                        BranchName = reader.IsDBNull("BranchName") ? null : reader.GetString("BranchName"),
                        BrandName = reader.IsDBNull("BrandName") ? null : reader.GetString("BrandName"),
                        ItemTypeName = reader.IsDBNull("ItemTypeName") ? null : reader.GetString("ItemTypeName"),
                        ManufacturerName = reader.IsDBNull("ManufacturerName") ? null : reader.GetString("ManufacturerName"),
                        AllocationNo = reader.IsDBNull("AllocationNo") ? null : reader.GetString("AllocationNo")
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving asset allocation report");
                throw;
            }

            return reports;
        }

        public async Task<IEnumerable<string>> GetBuildingsAsync()
        {
            var buildings = new List<string>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Room_GetBuildings", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    if (!reader.IsDBNull(0))
                    {
                        buildings.Add(reader.GetString(0));
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving buildings");
                throw;
            }

            return buildings;
        }

        public async Task<IEnumerable<string>> GetFloorsByBuildingAsync(string? building)
        {
            var floors = new List<string>();

            try
            {
                using var connection = new SqlConnection(_connectionString);
                using var command = new SqlCommand("Room_GetFloorsByBuilding", connection)
                {
                    CommandType = CommandType.StoredProcedure
                };

                command.Parameters.AddWithValue("@Building", (object?)building ?? DBNull.Value);

                await connection.OpenAsync();
                using var reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    if (!reader.IsDBNull(0))
                    {
                        floors.Add(reader.GetString(0));
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving floors");
                throw;
            }

            return floors;
        }

        private static AssetAllocation MapToAssetAllocation(SqlDataReader reader)
        {
            return new AssetAllocation
            {
                Id = reader.GetInt32("Id"),
                Remarks = reader.IsDBNull("Remarks") ? null : reader.GetString("Remarks"),
                AllocatedDate = reader.GetDateTime("AllocatedDate"),
                ReturnDate = reader.IsDBNull("ReturnDate") ? null : reader.GetDateTime("ReturnDate"),
                UserId = reader.IsDBNull("UserId") ? null : reader.GetInt32("UserId"),
                UserName = reader.IsDBNull("UserName") ? null : reader.GetString("UserName"),
                UserEmail = reader.IsDBNull("UserEmail") ? null : reader.GetString("UserEmail"),
                UserDepartment = reader.IsDBNull("UserDepartment") ? null : reader.GetString("UserDepartment"),
                DepartmentId = reader.IsDBNull("DepartmentId") ? null : reader.GetInt32("DepartmentId"),
                DepartmentName = reader.IsDBNull("DepartmentName") ? null : reader.GetString("DepartmentName"),
                SubDepartmentId = reader.IsDBNull("SubDepartmentId") ? null : reader.GetInt32("SubDepartmentId"),
                SubDepartmentName = reader.IsDBNull("SubDepartmentName") ? null : reader.GetString("SubDepartmentName"),
                RoomId = reader.IsDBNull("RoomId") ? null : reader.GetInt32("RoomId"),
                RoomName = reader.IsDBNull("RoomName") ? null : reader.GetString("RoomName"),
                Building = reader.IsDBNull("Building") ? null : reader.GetString("Building"),
                Floor = reader.IsDBNull("Floor") ? null : reader.GetString("Floor"),
                ItemId = reader.IsDBNull("ItemId") ? null : reader.GetInt32("ItemId"),
                BranchId = reader.IsDBNull("BranchId") ? null : reader.GetInt32("BranchId"),
                BranchName = reader.IsDBNull("BranchName") ? null : reader.GetString("BranchName"),
                IsReturn = reader.GetBoolean("IsReturn"),
                ReturnRemarks = reader.IsDBNull("ReturnRemarks") ? null : reader.GetString("ReturnRemarks"),
                Quantity = reader.GetInt32("Quantity"),
                InventoryItemId = reader.IsDBNull("InventoryItemId") ? null : reader.GetInt32("InventoryItemId"),
                InventoryItemName = reader.IsDBNull("InventoryItemName") ? null : reader.GetString("InventoryItemName"),
                SerialNumber = reader.IsDBNull("SerialNumber") ? null : reader.GetString("SerialNumber"),
                Model = reader.IsDBNull("Model") ? null : reader.GetString("Model"),
                ItemStatus = reader.IsDBNull("ItemStatus") ? null : reader.GetString("ItemStatus"),
                PurchasePrice = reader.IsDBNull("PurchasePrice") ? null : reader.GetDecimal("PurchasePrice"),
                CurrentValue = reader.IsDBNull("CurrentValue") ? null : reader.GetDecimal("CurrentValue"),
                SysBatchNo = reader.IsDBNull("SysBatchNo") ? null : reader.GetString("SysBatchNo"),
                BatchNo = reader.IsDBNull("BatchNo") ? null : reader.GetString("BatchNo"),
                IsActive = reader.GetBoolean("IsActive"),
                CreatedById = reader.IsDBNull("CreatedById") ? null : reader.GetInt32("CreatedById"),
                CreatedOn = reader.IsDBNull("CreatedOn") ? null : reader.GetDateTime("CreatedOn"),
                ModifiedById = reader.IsDBNull("ModifiedById") ? null : reader.GetInt32("ModifiedById"),
                ModifiedOn = reader.IsDBNull("ModifiedOn") ? null : reader.GetDateTime("ModifiedOn")
            };
        }
    }
}