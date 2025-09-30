using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IManufacturerService
    {
        Task<IEnumerable<Manufacturer>> GetAllManufacturersAsync();
        Task<Manufacturer?> GetManufacturerByIdAsync(int id);
        Task<int> CreateManufacturerAsync(CreateManufacturerRequest request);
        Task<bool> UpdateManufacturerAsync(UpdateManufacturerRequest request);
        Task<bool> DeleteManufacturerAsync(int id, int modifiedById);
    }
}