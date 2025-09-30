using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IPackingService
    {
        Task<IEnumerable<Packing>> GetAllPackingsAsync();
        Task<Packing?> GetPackingByIdAsync(int id);
        Task<int> CreatePackingAsync(CreatePackingRequest request);
        Task<bool> UpdatePackingAsync(UpdatePackingRequest request);
        Task<bool> DeletePackingAsync(int id, int modifiedById);
    }
}