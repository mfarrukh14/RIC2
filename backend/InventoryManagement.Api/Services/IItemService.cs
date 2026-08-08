using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IItemService
    {
        Task<PagedResult<Item>> GetAllAsync(ItemFilterRequest? filter = null);
        Task<IEnumerable<UnifiedItemLookupResult>> GetAllWithMedicinesAsync(string? search);
        Task<Item?> GetByIdAsync(int id);
        Task<int> CreateAsync(ItemCreateRequest request);
        Task<bool> UpdateAsync(int id, ItemUpdateRequest request);
        Task<bool> DeleteAsync(int id);
        
        // Lookup data methods
        Task<IEnumerable<Category>> GetCategoriesAsync();
        Task<Category?> GetCategoryByIdAsync(int id);
        Task<int> CreateCategoryAsync(string name, string? description, bool isActive);
        Task<bool> UpdateCategoryAsync(int id, string name, string? description, bool isActive);
        Task<bool> DeleteCategoryAsync(int id);
        
        Task<IEnumerable<SubCategory>> GetSubCategoriesAsync();
        Task<IEnumerable<Price>> GetPricesAsync();
        Task<IEnumerable<TaxRate>> GetTaxRatesAsync();
        Task<IEnumerable<TaxDescription>> GetTaxDescriptionsAsync();
        Task<IEnumerable<TaxType>> GetTaxTypesAsync();
    }
}