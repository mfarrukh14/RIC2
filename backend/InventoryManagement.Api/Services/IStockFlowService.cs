using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockFlowService
    {
        Task<PagedResult<StockFlow>> GetStockFlowAsync(StockFlowSearchRequest request);
    }
}
