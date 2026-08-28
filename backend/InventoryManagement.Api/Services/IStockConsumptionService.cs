using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockConsumptionService
    {
        Task<PagedResult<StockConsumptionView>> GetAllAsync(StockConsumptionSearchRequest? request, bool isAdmin, IReadOnlyCollection<int> allowedStoreIds);
        Task<StockConsumption?> GetByIdAsync(int id);
        Task<StockConsumption> CreateAsync(StockConsumptionCreateRequest request);
        Task<StockConsumption> UpdateAsync(StockConsumptionUpdateRequest request);
        Task<bool> DeleteAsync(int id);
    }
}
