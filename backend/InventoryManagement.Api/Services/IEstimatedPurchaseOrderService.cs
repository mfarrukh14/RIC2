using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IEstimatedPurchaseOrderService
    {
        Task<IEnumerable<EstimatedPurchaseOrderItem>> GetEstimatedPurchaseOrdersAsync(EstimatedPurchaseOrderSearchRequest request);
    }
}