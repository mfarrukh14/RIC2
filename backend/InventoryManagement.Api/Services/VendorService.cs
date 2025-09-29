using InventoryManagement.Api.Data;
using InventoryManagement.Api.DTOs;
using InventoryManagement.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace InventoryManagement.Api.Services
{
    public class VendorService : IVendorService
    {
        private readonly InventoryContext _context;

        public VendorService(InventoryContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<VendorDto>> GetAllVendorsAsync()
        {
            var vendors = await _context.Vendors
                .OrderBy(v => v.Name)
                .ToListAsync();

            return vendors.Select(MapToDto);
        }

        public async Task<VendorDto?> GetVendorByIdAsync(int id)
        {
            var vendor = await _context.Vendors.FindAsync(id);
            return vendor == null ? null : MapToDto(vendor);
        }

        public async Task<VendorDto> CreateVendorAsync(CreateVendorDto createVendorDto)
        {
            var vendor = new Vendor
            {
                Name = createVendorDto.Name,
                Code = createVendorDto.Code,
                Type = createVendorDto.Type,
                Description = createVendorDto.Description,
                Address = createVendorDto.Address,
                City = createVendorDto.City,
                State = createVendorDto.State,
                PostalCode = createVendorDto.PostalCode,
                Country = createVendorDto.Country,
                ContactPersonName1 = createVendorDto.ContactPersonName1,
                ContactPersonType1 = createVendorDto.ContactPersonType1,
                Email1 = createVendorDto.Email1,
                Phone1 = createVendorDto.Phone1,
                ContactPersonName2 = createVendorDto.ContactPersonName2,
                ContactPersonType2 = createVendorDto.ContactPersonType2,
                Email2 = createVendorDto.Email2,
                Phone2 = createVendorDto.Phone2,
                VendorAccountNumber = createVendorDto.VendorAccountNumber,
                TaxIdNumber = createVendorDto.TaxIdNumber,
                BankName = createVendorDto.BankName,
                AccountNumber = createVendorDto.AccountNumber,
                RoutingNumber = createVendorDto.RoutingNumber,
                SwiftCode = createVendorDto.SwiftCode,
                IbanNumber = createVendorDto.IbanNumber,
                CreditLimit = createVendorDto.CreditLimit,
                PaymentTerms = createVendorDto.PaymentTerms,
                IsActive = createVendorDto.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            _context.Vendors.Add(vendor);
            await _context.SaveChangesAsync();

            return MapToDto(vendor);
        }

        public async Task<VendorDto?> UpdateVendorAsync(int id, UpdateVendorDto updateVendorDto)
        {
            var vendor = await _context.Vendors.FindAsync(id);
            if (vendor == null)
                return null;

            vendor.Name = updateVendorDto.Name;
            vendor.Code = updateVendorDto.Code;
            vendor.Type = updateVendorDto.Type;
            vendor.Description = updateVendorDto.Description;
            vendor.Address = updateVendorDto.Address;
            vendor.City = updateVendorDto.City;
            vendor.State = updateVendorDto.State;
            vendor.PostalCode = updateVendorDto.PostalCode;
            vendor.Country = updateVendorDto.Country;
            vendor.ContactPersonName1 = updateVendorDto.ContactPersonName1;
            vendor.ContactPersonType1 = updateVendorDto.ContactPersonType1;
            vendor.Email1 = updateVendorDto.Email1;
            vendor.Phone1 = updateVendorDto.Phone1;
            vendor.ContactPersonName2 = updateVendorDto.ContactPersonName2;
            vendor.ContactPersonType2 = updateVendorDto.ContactPersonType2;
            vendor.Email2 = updateVendorDto.Email2;
            vendor.Phone2 = updateVendorDto.Phone2;
            vendor.VendorAccountNumber = updateVendorDto.VendorAccountNumber;
            vendor.TaxIdNumber = updateVendorDto.TaxIdNumber;
            vendor.BankName = updateVendorDto.BankName;
            vendor.AccountNumber = updateVendorDto.AccountNumber;
            vendor.RoutingNumber = updateVendorDto.RoutingNumber;
            vendor.SwiftCode = updateVendorDto.SwiftCode;
            vendor.IbanNumber = updateVendorDto.IbanNumber;
            vendor.CreditLimit = updateVendorDto.CreditLimit;
            vendor.PaymentTerms = updateVendorDto.PaymentTerms;
            vendor.IsActive = updateVendorDto.IsActive;
            vendor.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return MapToDto(vendor);
        }

        public async Task<bool> DeleteVendorAsync(int id)
        {
            var vendor = await _context.Vendors.FindAsync(id);
            if (vendor == null)
                return false;

            _context.Vendors.Remove(vendor);
            await _context.SaveChangesAsync();

            return true;
        }

        private static VendorDto MapToDto(Vendor vendor)
        {
            return new VendorDto
            {
                Id = vendor.Id,
                Name = vendor.Name,
                Code = vendor.Code,
                Type = vendor.Type,
                Description = vendor.Description,
                Address = vendor.Address,
                City = vendor.City,
                State = vendor.State,
                PostalCode = vendor.PostalCode,
                Country = vendor.Country,
                ContactPersonName1 = vendor.ContactPersonName1,
                ContactPersonType1 = vendor.ContactPersonType1,
                Email1 = vendor.Email1,
                Phone1 = vendor.Phone1,
                ContactPersonName2 = vendor.ContactPersonName2,
                ContactPersonType2 = vendor.ContactPersonType2,
                Email2 = vendor.Email2,
                Phone2 = vendor.Phone2,
                VendorAccountNumber = vendor.VendorAccountNumber,
                TaxIdNumber = vendor.TaxIdNumber,
                BankName = vendor.BankName,
                AccountNumber = vendor.AccountNumber,
                RoutingNumber = vendor.RoutingNumber,
                SwiftCode = vendor.SwiftCode,
                IbanNumber = vendor.IbanNumber,
                CreditLimit = vendor.CreditLimit,
                PaymentTerms = vendor.PaymentTerms,
                IsActive = vendor.IsActive,
                CreatedAt = vendor.CreatedAt,
                UpdatedAt = vendor.UpdatedAt
            };
        }
    }
}