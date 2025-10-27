using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockExpiringService
    {
        Task<IEnumerable<StockExpiringItem>> GetExpiringStockAsync(StockExpiringRequest request);
    }
}
