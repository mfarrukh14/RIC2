using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockConsumptionService
    {
        Task<IEnumerable<StockConsumptionView>> GetAllAsync(StockConsumptionSearchRequest? request = null);
        Task<StockConsumption?> GetByIdAsync(Guid id);
        Task<StockConsumption> CreateAsync(StockConsumptionCreateRequest request);
        Task<StockConsumption> UpdateAsync(StockConsumptionUpdateRequest request);
        Task<bool> DeleteAsync(Guid id);
    }
}
