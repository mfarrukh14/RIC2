using InventoryManagement.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace InventoryManagement.Api.Data
{
    public class InventoryContext : DbContext
    {
        public InventoryContext(DbContextOptions<InventoryContext> options) : base(options)
        {
        }

        public DbSet<Vendor> Vendors { get; set; }
        public DbSet<Manufacturer> Manufacturers { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure Vendor entity
            modelBuilder.Entity<Vendor>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                
                entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
                entity.Property(e => e.Code).HasMaxLength(20);
                entity.Property(e => e.Type).HasMaxLength(50);
                entity.Property(e => e.Description).HasMaxLength(500);
                entity.Property(e => e.Address).HasMaxLength(200);
                entity.Property(e => e.City).HasMaxLength(50);
                entity.Property(e => e.State).HasMaxLength(50);
                entity.Property(e => e.PostalCode).HasMaxLength(20);
                entity.Property(e => e.Country).HasMaxLength(50);
                
                entity.Property(e => e.ContactPersonName1).HasMaxLength(100);
                entity.Property(e => e.ContactPersonType1).HasMaxLength(50);
                entity.Property(e => e.Email1).HasMaxLength(100);
                entity.Property(e => e.Phone1).HasMaxLength(20);
                
                entity.Property(e => e.ContactPersonName2).HasMaxLength(100);
                entity.Property(e => e.ContactPersonType2).HasMaxLength(50);
                entity.Property(e => e.Email2).HasMaxLength(100);
                entity.Property(e => e.Phone2).HasMaxLength(20);
                
                entity.Property(e => e.VendorAccountNumber).HasMaxLength(50);
                entity.Property(e => e.TaxIdNumber).HasMaxLength(50);
                entity.Property(e => e.BankName).HasMaxLength(100);
                entity.Property(e => e.AccountNumber).HasMaxLength(50);
                entity.Property(e => e.RoutingNumber).HasMaxLength(20);
                entity.Property(e => e.SwiftCode).HasMaxLength(20);
                entity.Property(e => e.IbanNumber).HasMaxLength(50);
                entity.Property(e => e.CreditLimit).HasMaxLength(20);
                entity.Property(e => e.PaymentTerms).HasMaxLength(50);
                
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
                entity.Property(e => e.IsActive).HasDefaultValue(true);

                entity.HasIndex(e => e.Name).IsUnique();
                entity.HasIndex(e => e.Code).IsUnique().HasFilter("[Code] IS NOT NULL");
                entity.HasIndex(e => e.Email1).IsUnique().HasFilter("[Email1] IS NOT NULL");
            });

            // Configure Manufacturer entity
            modelBuilder.Entity<Manufacturer>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                
                entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
                entity.Property(e => e.Email).HasMaxLength(100);
                entity.Property(e => e.Ntn).HasMaxLength(50);
                entity.Property(e => e.Stn).HasMaxLength(20);
                entity.Property(e => e.Country).HasMaxLength(50);
                entity.Property(e => e.StateProvince).HasMaxLength(50);
                entity.Property(e => e.City).HasMaxLength(50);
                entity.Property(e => e.Address).HasMaxLength(200);
                entity.Property(e => e.ContactNo).HasMaxLength(20);
                entity.Property(e => e.Description).HasMaxLength(500);
                
                entity.Property(e => e.ContactPersonName1).HasMaxLength(100);
                entity.Property(e => e.ContactPersonEmail1).HasMaxLength(100);
                entity.Property(e => e.ContactPersonPhone1).HasMaxLength(20);
                entity.Property(e => e.ContactPersonName2).HasMaxLength(100);
                entity.Property(e => e.ContactPersonEmail2).HasMaxLength(100);
                entity.Property(e => e.ContactPersonPhone2).HasMaxLength(20);
                
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("GETUTCDATE()");
                entity.Property(e => e.IsActive).HasDefaultValue(true);

                entity.HasIndex(e => e.Name).IsUnique();
                entity.HasIndex(e => e.Email).IsUnique().HasFilter("[Email] IS NOT NULL");
                entity.HasIndex(e => e.Ntn).IsUnique().HasFilter("[Ntn] IS NOT NULL");
            });

            // Seed data for Manufacturers
            modelBuilder.Entity<Manufacturer>().HasData(
                new Manufacturer
                {
                    Id = 1,
                    Name = "Nisa SF Pvt Ltd",
                    Email = "info@nisasf.com",
                    Ntn = "NTN123456",
                    Stn = "STN789",
                    Country = "Pakistan",
                    StateProvince = "Sindh",
                    City = "Shahzadpur",
                    Address = "10-km Mundko Shahzadpur road District Shahzadpur, Pakistan",
                    ContactNo = "03915455461",
                    Description = "Leading medical equipment manufacturer",
                    ContactPersonName1 = "Ahmed Ali",
                    ContactPersonEmail1 = "ahmed@nisasf.com",
                    ContactPersonPhone1 = "03915455461",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Manufacturer
                {
                    Id = 2,
                    Name = "Beijing Domax Medical",
                    Email = "info@domaxmedical.com",
                    Ntn = "NTN987654",
                    Stn = "STN321",
                    Country = "China",
                    StateProvince = "Beijing",
                    City = "Beijing",
                    Address = "A12-7, Jingtianongnanci street, tongzhou district, Beijing",
                    ContactNo = "0086-10-56771179",
                    Description = "Advanced medical device manufacturer",
                    ContactPersonName1 = "Li Wei",
                    ContactPersonEmail1 = "li.wei@domaxmedical.com",
                    ContactPersonPhone1 = "0086-10-56771179",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            );

            // Seed data
            modelBuilder.Entity<Vendor>().HasData(
                new Vendor
                {
                    Id = 1,
                    Name = "Tech Supplies Co.",
                    Code = "TECH001",
                    Type = "Supplier",
                    Description = "Leading supplier of technology equipment",
                    ContactPersonName1 = "John Smith",
                    ContactPersonType1 = "Sales Manager",
                    Phone1 = "+1-555-0101",
                    Email1 = "john@techsupplies.com",
                    Address = "123 Tech Street",
                    City = "San Francisco",
                    State = "CA",
                    PostalCode = "94105",
                    Country = "USA",
                    VendorAccountNumber = "ACC-TECH001",
                    TaxIdNumber = "TAX123456789",
                    BankName = "Tech Bank",
                    AccountNumber = "1234567890",
                    RoutingNumber = "987654321",
                    CreditLimit = "50000",
                    PaymentTerms = "NET 30",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Vendor
                {
                    Id = 2,
                    Name = "Office Essentials Ltd.",
                    Code = "OFF001",
                    Type = "Distributor",
                    Description = "Complete office supply solutions",
                    ContactPersonName1 = "Sarah Johnson",
                    ContactPersonType1 = "Account Manager",
                    Phone1 = "+1-555-0102",
                    Email1 = "sarah@officeessentials.com",
                    Address = "456 Business Ave",
                    City = "New York",
                    State = "NY",
                    PostalCode = "10001",
                    Country = "USA",
                    VendorAccountNumber = "ACC-OFF001",
                    TaxIdNumber = "TAX987654321",
                    BankName = "Business Bank",
                    AccountNumber = "0987654321",
                    RoutingNumber = "123456789",
                    CreditLimit = "25000",
                    PaymentTerms = "NET 15",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            );
        }
    }
}