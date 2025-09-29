using InventoryManagement.Api.DTOs;

namespace InventoryManagement.Api.Services
{
    public interface IManufacturerService
    {
        Task<IEnumerable<ManufacturerDto>> GetAllManufacturersAsync();
        Task<ManufacturerDto?> GetManufacturerByIdAsync(int id);
        Task<ManufacturerDto> CreateManufacturerAsync(CreateManufacturerDto createManufacturerDto);
        Task<ManufacturerDto?> UpdateManufacturerAsync(int id, UpdateManufacturerDto updateManufacturerDto);
        Task<bool> DeleteManufacturerAsync(int id);
    }
}