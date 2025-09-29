using InventoryManagement.Api.DTOs;

namespace InventoryManagement.Api.Services
{
    public interface IVendorService
    {
        Task<IEnumerable<VendorDto>> GetAllVendorsAsync();
        Task<VendorDto?> GetVendorByIdAsync(int id);
        Task<VendorDto> CreateVendorAsync(CreateVendorDto createVendorDto);
        Task<VendorDto?> UpdateVendorAsync(int id, UpdateVendorDto updateVendorDto);
        Task<bool> DeleteVendorAsync(int id);
    }
}