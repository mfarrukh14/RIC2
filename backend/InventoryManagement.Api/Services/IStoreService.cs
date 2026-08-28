using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IStoreService
    {
        Task<IEnumerable<PharmacyStoreViewModel>> GetAllAsync();
        Task<Store?> GetByIdAsync(int id);
        Task<Store> CreateAsync(StoreCreateRequest request);
        Task UpdateAsync(int id, StoreUpdateRequest request);
        Task DeleteAsync(int id);
        Task<IReadOnlyList<DropdownItem>> GetPharmacyStoreDropdownAsync(PharmacyStoreDropdownRequest request, bool isAdmin, IReadOnlyCollection<int> allowedStoreIds);
        Task<StoreLocationLookupResponse> GetLocationLookupAsync();
    }
}
