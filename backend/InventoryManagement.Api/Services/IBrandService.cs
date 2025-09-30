using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IBrandService
    {
        Task<IEnumerable<Brand>> GetAllBrandsAsync();
        Task<Brand?> GetBrandByIdAsync(int id);
        Task<int> CreateBrandAsync(CreateBrandRequest request);
        Task<bool> UpdateBrandAsync(UpdateBrandRequest request);
        Task<bool> DeleteBrandAsync(int id, int modifiedById);
    }
}