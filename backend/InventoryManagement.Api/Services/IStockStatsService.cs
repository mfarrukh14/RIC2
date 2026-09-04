using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockStatsService
    {
        Task<PagedResult<StockStatsItem>> SearchStockStatsAsync(StockStatsSearchRequest request);
    }
}
