using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IPurchaseOrderTypeService
    {
        Task<IReadOnlyList<PurchaseOrderTypeDto>> GetAllAsync();
        Task<PurchaseOrderTypeDto?> GetByIdAsync(int id);
        Task<PurchaseOrderTypeDto> CreateAsync(PurchaseOrderTypeUpsertRequest request);
        Task<PurchaseOrderTypeDto?> UpdateAsync(int id, PurchaseOrderTypeUpsertRequest request);
        Task<bool> DeleteAsync(int id);
    }
}