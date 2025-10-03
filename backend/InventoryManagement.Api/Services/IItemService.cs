using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IItemService
    {
        Task<IEnumerable<Item>> GetAllAsync();
        Task<Item?> GetByIdAsync(int id);
        Task<int> CreateAsync(ItemCreateRequest request);
        Task<bool> UpdateAsync(int id, ItemUpdateRequest request);
        Task<bool> DeleteAsync(int id);
        
        // Lookup data methods
        Task<IEnumerable<Category>> GetCategoriesAsync();
        Task<IEnumerable<SubCategory>> GetSubCategoriesAsync();
        Task<IEnumerable<Price>> GetPricesAsync();
        Task<IEnumerable<TaxRate>> GetTaxRatesAsync();
        Task<IEnumerable<TaxDescription>> GetTaxDescriptionsAsync();
        Task<IEnumerable<TaxType>> GetTaxTypesAsync();
    }
}