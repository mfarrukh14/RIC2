using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IPurchaseOrderStatusService
    {
        Task<IReadOnlyList<PurchaseOrderStatusDto>> GetAllAsync();
        Task<PurchaseOrderStatusDto?> GetByIdAsync(int id);
        Task<PurchaseOrderStatusDto> CreateAsync(PurchaseOrderStatusUpsertRequest request);
        Task<PurchaseOrderStatusDto?> UpdateAsync(int id, PurchaseOrderStatusUpsertRequest request);
    }
}