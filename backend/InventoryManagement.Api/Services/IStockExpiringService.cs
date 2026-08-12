using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockExpiringService
    {
        Task<PagedResult<StockExpiringItem>> GetExpiringStockAsync(StockExpiringRequest request);
    }
}
