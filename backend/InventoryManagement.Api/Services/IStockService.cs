using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockService
    {
        Task<PagedResult<Stock>> SearchStocksAsync(StockSearchRequest request);
        Task<Dictionary<int, int>> GetQuantitiesByStoreAsync(int storeId);
        Task<bool> UpdateMinimumPanicLevelAsync(int stockId, int minimumPanicLevel);
    }
}
