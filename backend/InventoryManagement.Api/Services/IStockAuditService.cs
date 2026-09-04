using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStockAuditService
    {
        Task<PagedResult<StockAuditItem>> SearchStockAuditItemsAsync(StockAuditSearchRequest request);
        Task<StockAudit> CreateStockAuditAsync(StockAuditRequest request);
        Task<List<StockAuditListItem>> GetAllAsync(StockAuditListRequest request);
    }
}
