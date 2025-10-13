using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockTypeService
    {
        Task<IEnumerable<StockType>> GetAllStockTypesAsync();
        Task<StockType?> GetStockTypeByIdAsync(int id);
        Task<int> CreateStockTypeAsync(StockTypeRequest request);
        Task<bool> UpdateStockTypeAsync(int id, StockTypeRequest request);
        Task<bool> DeleteStockTypeAsync(int id);
    }
}
