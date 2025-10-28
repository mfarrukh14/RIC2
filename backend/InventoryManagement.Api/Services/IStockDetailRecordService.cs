using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockDetailRecordService
    {
        Task<IEnumerable<StockDetailRecord>> GetStockDetailRecordsAsync(StockDetailRecordSearchRequest request);
    }
}
