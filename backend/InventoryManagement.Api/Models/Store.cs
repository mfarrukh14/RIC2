namespace InventoryManagement.Api.Models
{
    public class Store
    {
        public int StoreId { get; set; }
        public string StoreName { get; set; } = string.Empty;
        public string? StoreCode { get; set; }
        public string? Description { get; set; }
        
        // Store Configuration
        public string? StoreType { get; set; }
        public string? ReceiptType { get; set; }
        public string? POSType { get; set; }
        public int? ParentStoreId { get; set; }
        public string? ParentStoreName { get; set; }
        public int? BuildingId { get; set; }
        public string? BuildingName { get; set; }
        public int? FloorId { get; set; }
        public string? FloorName { get; set; }
        public int? RoomId { get; set; }
        public string? RoomName { get; set; }
        
        // Contact Information
        public string? Email { get; set; }
        public string? CellNumber { get; set; }
        
        // Queue Settings
        public string? QueuePatientCallStatusValue { get; set; }
        public bool? MarkTokenAsAutoCollectedOnDispense { get; set; }
        public bool? DisplayRequestsWithoutTokenIssued { get; set; }
        public string? EnglishNote { get; set; }
        public string? UrduNote { get; set; }
        
        // Financial Settings
        public bool? ServiceCharges { get; set; }
        public bool? GST { get; set; }
        public string? PricingType { get; set; }
        public bool? DisableRetailSale { get; set; }
        public string? GSTN { get; set; }
        public string? NTN { get; set; }
        
        // Day Closing
        public string? DayClosing { get; set; }
        public int? ClosingCashAccountId { get; set; }
        public string? ClosingCashAccountName { get; set; }
        public int? ClosingRevenueAccountId { get; set; }
        public string? ClosingRevenueAccountName { get; set; }
        public int? ClosingInventoryAccountId { get; set; }
        public string? ClosingInventoryAccountName { get; set; }
        public int? ClosingInventoryExpenseAccountId { get; set; }
        public string? ClosingInventoryExpenseAccountName { get; set; }
        public int? ClosingTaxExpenseAccountId { get; set; }
        public string? ClosingTaxExpenseAccountName { get; set; }
        public int? PayableAccountId { get; set; }
        public string? PayableAccountName { get; set; }
        public int? AdvanceTaxPercentageAccountId { get; set; }
        public string? AdvanceTaxPercentageAccountName { get; set; }
        public int? RevenueDiscountAccountId { get; set; }
        public string? RevenueDiscountAccountName { get; set; }
        
        // Address Details
        public string? Address { get; set; }
        public string? Latitude { get; set; }
        public string? Longitude { get; set; }
        public string? Country { get; set; }
        public string? StateOrProvince { get; set; }
        public string? City { get; set; }
        
        // Store Image
        public string? StoreImage { get; set; }

        // Branch (always the creating user's own branch - set server-side, never from the client)
        public int BranchId { get; set; }
        public string? BranchName { get; set; }

        // Audit
        public bool IsActive { get; set; } = true;
        public int? CreatedById { get; set; }
        public DateTime CreatedOn { get; set; }
        public int? ModifiedById { get; set; }
        public DateTime? ModifiedOn { get; set; }
    }


    public class PharmacyStoreViewModel
    {
        public int RowNumber { get; set; }

        public int Id { get; set; }

        public string? Name { get; set; }

        public string? Description { get; set; }

        public int? CreatedBy { get; set; }

        public DateTime? CreatedOn { get; set; }

        public DateTime? ModifiedOn { get; set; }

        public int? POSType { get; set; }

        public int? ReceiptType { get; set; }

        public int? PatientReceiptCopy { get; set; }

        public int? AccountantReceiptCopy { get; set; }

        public int? DepartmentReceiptCopy { get; set; }

        public string? IsActiveHtml { get; set; }

        public bool IsActive { get; set; }

        public bool IsActivebit { get; set; }

        public int? ParentId { get; set; }

        public string? ParentName { get; set; }

        public int? RoomId { get; set; }

        public string? RoomName { get; set; }

        public int? BuildingId { get; set; }

        public string? BuildingName { get; set; }

        public int? FloorId { get; set; }

        public string? FloorName { get; set; }

        public int? DayClosingInventoryAccountId { get; set; }

        public int? DayClosingInventoryExpenseAccountId { get; set; }

        public int? DayClosingTaxExpenseAccountId { get; set; }

        public int? PayableAccountId { get; set; }

        public bool? IsPercentageServiceCharges { get; set; }

        public decimal? ServiceCharges { get; set; }

        public bool? IsPercentageGST { get; set; }

        public decimal? GST { get; set; }

        public string? EnglishNote { get; set; }

        public string? UrduNote { get; set; }

        public string? GSTN { get; set; }

        public string? NTN { get; set; }

        public string? Html { get; set; }

        public bool? DayClosingWise { get; set; }

        public int? DayClosingCashAccountId { get; set; }

        public int? DayClosingRevenueAccountId { get; set; }

        public string? Address { get; set; }

        public decimal? Latitude { get; set; }

        public decimal? Longitude { get; set; }

        public int? CityId { get; set; }

        public int? StateOrProvinceId { get; set; }

        public int? CountryId { get; set; }

        public string? Country { get; set; }

        public string? City { get; set; }

        public string? StateOrProvince { get; set; }

        public string? ImagePath { get; set; }

        public string? CellNumber { get; set; }

        public string? Email { get; set; }

        public int? PricingType { get; set; }

        public int? AdvanceTaxPercentageAccountId { get; set; }

        public bool? IsDisableRetailSale { get; set; }

        public int? RevenueDiscountAccountId { get; set; }
    }
    public class StoreCreateRequest
    {
        public string StoreName { get; set; } = string.Empty;
        public string? StoreCode { get; set; }
        public string? Description { get; set; }
        public string? StoreType { get; set; }
        public string? ReceiptType { get; set; }
        public string? POSType { get; set; }
        public int? ParentStoreId { get; set; }
        public int? BuildingId { get; set; }
        public int? FloorId { get; set; }
        public int? RoomId { get; set; }
        public string? Email { get; set; }
        public string? CellNumber { get; set; }
        public string? QueuePatientCallStatusValue { get; set; }
        public bool? MarkTokenAsAutoCollectedOnDispense { get; set; }
        public bool? DisplayRequestsWithoutTokenIssued { get; set; }
        public string? EnglishNote { get; set; }
        public string? UrduNote { get; set; }
        public bool? ServiceCharges { get; set; }
        public bool? GST { get; set; }
        public string? PricingType { get; set; }
        public bool? DisableRetailSale { get; set; }
        public string? GSTN { get; set; }
        public string? NTN { get; set; }
        public string? DayClosing { get; set; }
        public int? ClosingCashAccountId { get; set; }
        public int? ClosingRevenueAccountId { get; set; }
        public int? ClosingInventoryAccountId { get; set; }
        public int? ClosingInventoryExpenseAccountId { get; set; }
        public int? ClosingTaxExpenseAccountId { get; set; }
        public int? PayableAccountId { get; set; }
        public int? AdvanceTaxPercentageAccountId { get; set; }
        public int? RevenueDiscountAccountId { get; set; }
        public string? Address { get; set; }
        public string? Latitude { get; set; }
        public string? Longitude { get; set; }
        public string? Country { get; set; }
        public string? StateOrProvince { get; set; }
        public string? City { get; set; }
        public string? StoreImage { get; set; }
        // Set server-side from the caller's session in StoreController - any value sent by the client is ignored.
        public int BranchId { get; set; }
        public bool IsActive { get; set; } = true;
    }

    public class StoreUpdateRequest
    {
        public int StoreId { get; set; }
        public string StoreName { get; set; } = string.Empty;
        public string? StoreCode { get; set; }
        public string? Description { get; set; }
        public string? StoreType { get; set; }
        public string? ReceiptType { get; set; }
        public string? POSType { get; set; }
        public int? ParentStoreId { get; set; }
        public int? BuildingId { get; set; }
        public int? FloorId { get; set; }
        public int? RoomId { get; set; }
        public string? Email { get; set; }
        public string? CellNumber { get; set; }
        public string? QueuePatientCallStatusValue { get; set; }
        public bool? MarkTokenAsAutoCollectedOnDispense { get; set; }
        public bool? DisplayRequestsWithoutTokenIssued { get; set; }
        public string? EnglishNote { get; set; }
        public string? UrduNote { get; set; }
        public bool? ServiceCharges { get; set; }
        public bool? GST { get; set; }
        public string? PricingType { get; set; }
        public bool? DisableRetailSale { get; set; }
        public string? GSTN { get; set; }
        public string? NTN { get; set; }
        public string? DayClosing { get; set; }
        public int? ClosingCashAccountId { get; set; }
        public int? ClosingRevenueAccountId { get; set; }
        public int? ClosingInventoryAccountId { get; set; }
        public int? ClosingInventoryExpenseAccountId { get; set; }
        public int? ClosingTaxExpenseAccountId { get; set; }
        public int? PayableAccountId { get; set; }
        public int? AdvanceTaxPercentageAccountId { get; set; }
        public int? RevenueDiscountAccountId { get; set; }
        public string? Address { get; set; }
        public string? Latitude { get; set; }
        public string? Longitude { get; set; }
        public string? Country { get; set; }
        public string? StateOrProvince { get; set; }
        public string? City { get; set; }
        public string? StoreImage { get; set; }
        // Set server-side from the caller's session in StoreController - any value sent by the client is ignored.
        public int BranchId { get; set; }
        public bool IsActive { get; set; }
    }
}
