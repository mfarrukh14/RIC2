using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockValueItemService
    {
        Task<PagedResult<StockValueItem>> GetStockValueItemsAsync(StockValueSearchRequest request);
        Task<GRNReport> GetGRNReportByBatchAsync(StockValueDetailRequest request);
    }
}
