using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockValueItemService
    {
        Task<IEnumerable<StockValueItem>> GetStockValueItemsAsync(StockValueSearchRequest request);
        Task<GRNReport> GetGRNReportByBatchAsync(StockValueDetailRequest request);
    }
}
