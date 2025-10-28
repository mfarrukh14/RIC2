using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStoreService
    {
        Task<IEnumerable<Store>> GetAllAsync();
        Task<Store?> GetByIdAsync(int id);
    }
}
