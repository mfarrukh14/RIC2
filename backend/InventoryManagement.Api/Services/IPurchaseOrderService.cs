using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Services
{
    public interface IPurchaseOrderService
    {
        Task<PagedResult<PurchaseOrderSummary>> GetAllAsync(PurchaseOrderFilter filter);
        Task<PurchaseOrderDetails?> GetByIdAsync(int id);
        Task<PurchaseOrderDetails> CreateAsync(PurchaseOrderCreateRequest request, int userId);
        Task<bool> UpdateAsync(int id, PurchaseOrderUpdateRequest request, int userId);
        Task<bool> RejectAsync(int id, string remarks, int userId);
        Task<List<PurchaseOrderItemLogEntry>> GetItemLogAsync(int id);
        Task<List<PurchaseOrderAttachment>> GetAttachmentsAsync(int id);
        Task<PurchaseOrderAttachment> AddAttachmentAsync(int id, string? title, string fileName, string fileUrl, int userId);
        Task<PurchaseOrderAttachment?> GetAttachmentAsync(int attachmentId);
        Task<bool> DeleteAttachmentAsync(int attachmentId);
    }
}