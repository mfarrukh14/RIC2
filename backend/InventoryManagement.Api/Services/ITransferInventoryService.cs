using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface ITransferInventoryService
    {
        Task<List<TransferInventory>> GetAllAsync();
        Task<TransferInventory?> GetByIdAsync(int id);
        Task<TransferInventory> CreateAsync(TransferInventoryCreateRequest request);
        Task<bool> UpdateAsync(int id, TransferInventoryUpdateRequest request);
        Task<bool> DeleteAsync(int id);
        Task<TransferInventoryLookupData> GetLookupDataAsync();
    }
}
