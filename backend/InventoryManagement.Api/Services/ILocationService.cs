using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface ILocationService
    {
        Task<IEnumerable<DropdownItem>> GetCountriesAsync();
        Task<IEnumerable<DropdownItem>> GetProvincesByCountryAsync(int countryId);
        Task<IEnumerable<DropdownItem>> GetCitiesByProvinceAsync(int provinceId);
    }
}
