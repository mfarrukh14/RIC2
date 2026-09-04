using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockDetailRecordService
    {
        Task<PagedResult<StockDetailRecord>> GetStockDetailRecordsAsync(StockDetailRecordSearchRequest request);
    }
}
