using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public interface ISampleCollectionConsumptionItemService
    {
        Task<IEnumerable<SampleCollectionConsumptionItem>> GetAllAsync();
        Task<SampleCollectionConsumptionItem?> GetByIdAsync(int id);
        Task<int> CreateAsync(CreateSampleCollectionConsumptionItemRequest request);
        Task<bool> UpdateAsync(int id, UpdateSampleCollectionConsumptionItemRequest request);
        Task<bool> DeleteAsync(int id);
        Task<SampleCollectionConsumptionItemLookupData> GetLookupDataAsync();
    }
}
