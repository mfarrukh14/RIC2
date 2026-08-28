using InventoryManagement.Api.DTOs;

namespace InventoryManagement.Api.Services
{
    public interface IVendorService
    {
        Task<IEnumerable<VendorDto>> GetAllVendorsAsync(int branchId);
        Task<VendorDto?> GetVendorByIdAsync(int id);
        Task<VendorDto> CreateVendorAsync(CreateVendorDto createVendorDto, int? branchId);
        Task<VendorDto?> UpdateVendorAsync(int id, UpdateVendorDto updateVendorDto, int? branchId);
        Task<bool> DeleteVendorAsync(int id);
    }
}