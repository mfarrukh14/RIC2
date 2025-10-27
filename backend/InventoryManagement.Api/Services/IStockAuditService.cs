using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockAuditService
    {
        Task<List<StockAuditItem>> SearchStockAuditItemsAsync(StockAuditSearchRequest request);
        Task<StockAudit> CreateStockAuditAsync(StockAuditRequest request);
    }
}
