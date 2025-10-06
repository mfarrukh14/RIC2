using InventoryManagement.API.Models;

namespace InventoryManagement.API.Services
{
    public interface IPurchaseSummaryInvoiceService
    {
        Task<PurchaseSummaryInvoiceResponse> GetAllAsync(PurchaseSummaryInvoiceFilterRequest? filter = null);
        Task<PurchaseSummaryInvoice?> GetByIdAsync(int id);
        Task<PurchaseSummaryInvoice> CreateAsync(PurchaseSummaryInvoiceCreateRequest request);
        Task<bool> UpdateAsync(int id, PurchaseSummaryInvoiceUpdateRequest request);
        Task<bool> DeleteAsync(int id);
        Task<PurchaseSummaryInvoiceLookupData> GetLookupDataAsync();
    }
}
