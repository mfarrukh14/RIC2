using InventoryManagement.Api.Data;
using InventoryManagement.Api.DTOs;
using InventoryManagement.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace InventoryManagement.Api.Services
{
    public class ManufacturerService : IManufacturerService
    {
        private readonly InventoryContext _context;

        public ManufacturerService(InventoryContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<ManufacturerDto>> GetAllManufacturersAsync()
        {
            var manufacturers = await _context.Manufacturers
                .OrderBy(m => m.Name)
                .ToListAsync();

            return manufacturers.Select(MapToDto);
        }

        public async Task<ManufacturerDto?> GetManufacturerByIdAsync(int id)
        {
            var manufacturer = await _context.Manufacturers.FindAsync(id);
            return manufacturer == null ? null : MapToDto(manufacturer);
        }

        public async Task<ManufacturerDto> CreateManufacturerAsync(CreateManufacturerDto createManufacturerDto)
        {
            var manufacturer = new Manufacturer
            {
                Name = createManufacturerDto.Name,
                Email = createManufacturerDto.Email,
                Ntn = createManufacturerDto.Ntn,
                Stn = createManufacturerDto.Stn,
                Country = createManufacturerDto.Country,
                StateProvince = createManufacturerDto.StateProvince,
                City = createManufacturerDto.City,
                Address = createManufacturerDto.Address,
                ContactNo = createManufacturerDto.ContactNo,
                Description = createManufacturerDto.Description,
                ContactPersonName1 = createManufacturerDto.ContactPersonName1,
                ContactPersonEmail1 = createManufacturerDto.ContactPersonEmail1,
                ContactPersonPhone1 = createManufacturerDto.ContactPersonPhone1,
                ContactPersonName2 = createManufacturerDto.ContactPersonName2,
                ContactPersonEmail2 = createManufacturerDto.ContactPersonEmail2,
                ContactPersonPhone2 = createManufacturerDto.ContactPersonPhone2,
                IsActive = createManufacturerDto.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            _context.Manufacturers.Add(manufacturer);
            await _context.SaveChangesAsync();

            return MapToDto(manufacturer);
        }

        public async Task<ManufacturerDto?> UpdateManufacturerAsync(int id, UpdateManufacturerDto updateManufacturerDto)
        {
            var manufacturer = await _context.Manufacturers.FindAsync(id);
            if (manufacturer == null)
                return null;

            manufacturer.Name = updateManufacturerDto.Name;
            manufacturer.Email = updateManufacturerDto.Email;
            manufacturer.Ntn = updateManufacturerDto.Ntn;
            manufacturer.Stn = updateManufacturerDto.Stn;
            manufacturer.Country = updateManufacturerDto.Country;
            manufacturer.StateProvince = updateManufacturerDto.StateProvince;
            manufacturer.City = updateManufacturerDto.City;
            manufacturer.Address = updateManufacturerDto.Address;
            manufacturer.ContactNo = updateManufacturerDto.ContactNo;
            manufacturer.Description = updateManufacturerDto.Description;
            manufacturer.ContactPersonName1 = updateManufacturerDto.ContactPersonName1;
            manufacturer.ContactPersonEmail1 = updateManufacturerDto.ContactPersonEmail1;
            manufacturer.ContactPersonPhone1 = updateManufacturerDto.ContactPersonPhone1;
            manufacturer.ContactPersonName2 = updateManufacturerDto.ContactPersonName2;
            manufacturer.ContactPersonEmail2 = updateManufacturerDto.ContactPersonEmail2;
            manufacturer.ContactPersonPhone2 = updateManufacturerDto.ContactPersonPhone2;
            manufacturer.IsActive = updateManufacturerDto.IsActive;
            manufacturer.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return MapToDto(manufacturer);
        }

        public async Task<bool> DeleteManufacturerAsync(int id)
        {
            var manufacturer = await _context.Manufacturers.FindAsync(id);
            if (manufacturer == null)
                return false;

            _context.Manufacturers.Remove(manufacturer);
            await _context.SaveChangesAsync();

            return true;
        }

        private static ManufacturerDto MapToDto(Manufacturer manufacturer)
        {
            return new ManufacturerDto
            {
                Id = manufacturer.Id,
                Name = manufacturer.Name,
                Email = manufacturer.Email,
                Ntn = manufacturer.Ntn,
                Stn = manufacturer.Stn,
                Country = manufacturer.Country,
                StateProvince = manufacturer.StateProvince,
                City = manufacturer.City,
                Address = manufacturer.Address,
                ContactNo = manufacturer.ContactNo,
                Description = manufacturer.Description,
                ContactPersonName1 = manufacturer.ContactPersonName1,
                ContactPersonEmail1 = manufacturer.ContactPersonEmail1,
                ContactPersonPhone1 = manufacturer.ContactPersonPhone1,
                ContactPersonName2 = manufacturer.ContactPersonName2,
                ContactPersonEmail2 = manufacturer.ContactPersonEmail2,
                ContactPersonPhone2 = manufacturer.ContactPersonPhone2,
                IsActive = manufacturer.IsActive,
                CreatedAt = manufacturer.CreatedAt,
                UpdatedAt = manufacturer.UpdatedAt
            };
        }
    }
}