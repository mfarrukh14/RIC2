using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockStatsService
    {
        Task<List<StockStatsItem>> SearchStockStatsAsync(StockStatsSearchRequest request);
    }
}
