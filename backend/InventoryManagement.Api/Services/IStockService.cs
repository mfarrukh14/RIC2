using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockService
    {
        Task<PagedResult<Stock>> SearchStocksAsync(StockSearchRequest request, bool isAdmin, IReadOnlyCollection<int> allowedStoreIds);
        Task<StoreItemQuantities> GetQuantitiesByStoreAsync(int storeId);
        Task<bool> UpdateMinimumPanicLevelAsync(int stockId, int minimumPanicLevel);
    }
}
