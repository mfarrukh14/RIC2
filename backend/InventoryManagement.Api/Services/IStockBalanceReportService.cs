using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockBalanceReportService
    {
        Task<StockBalanceReport> GetStockBalanceReportAsync(StockBalanceSearchRequest request);
    }
}
