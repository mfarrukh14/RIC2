using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockConsumptionService
    {
        Task<IEnumerable<StockConsumptionView>> GetAllAsync(StockConsumptionSearchRequest? request = null);
        Task<StockConsumption?> GetByIdAsync(int id);
        Task<StockConsumption> CreateAsync(StockConsumptionCreateRequest request);
        Task<StockConsumption> UpdateAsync(StockConsumptionUpdateRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
