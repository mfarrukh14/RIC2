using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockFlowService
    {
        Task<IEnumerable<StockFlow>> GetStockFlowAsync(StockFlowSearchRequest request);
    }
}
