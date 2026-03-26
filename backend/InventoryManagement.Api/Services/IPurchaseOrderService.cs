using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IPurchaseOrderService
    {
        Task<IReadOnlyList<PurchaseOrderSummary>> GetAllAsync(PurchaseOrderFilter filter);
        Task<PurchaseOrderDetails?> GetByIdAsync(int id);
        Task<PurchaseOrderDetails> CreateAsync(PurchaseOrderCreateRequest request);
    }
}