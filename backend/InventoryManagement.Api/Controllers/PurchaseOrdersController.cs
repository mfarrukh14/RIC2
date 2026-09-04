using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PurchaseOrdersController : BaseController
    {
        // Attachments are streamed back through this authenticated controller
        // rather than served as static files under wwwroot - every other piece
        // of data in this app is gated behind the X-User-Id session header
        // (see BaseController), and a plain static-file URL would bypass that
        // entirely for anyone who guessed/saved the link.
        private static readonly string AttachmentsRootFolder = Path.Combine("Uploads", "PurchaseOrderAttachments");

        private readonly IPurchaseOrderService _purchaseOrderService;
        private readonly IWebHostEnvironment _environment;
        private readonly ILogger<PurchaseOrdersController> _logger;

        public PurchaseOrdersController(
            IUserSessionCacheService sessionCache,
            IPurchaseOrderService purchaseOrderService,
            IWebHostEnvironment environment,
            ILogger<PurchaseOrdersController> logger)
            : base(sessionCache)
        {
            _purchaseOrderService = purchaseOrderService;
            _environment = environment;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<PurchaseOrderSummary>>> GetAll([FromQuery] PurchaseOrderFilter filter)
        {
            try
            {
                var purchaseOrders = await _purchaseOrderService.GetAllAsync(filter);
                return Ok(purchaseOrders);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase orders");
                return StatusCode(500, new { message = "An error occurred while retrieving purchase orders." });
            }
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<PurchaseOrderDetails>> GetById(int id)
        {
            try
            {
                var purchaseOrder = await _purchaseOrderService.GetByIdAsync(id);
                if (purchaseOrder == null)
                {
                    return NotFound(new { message = $"Purchase order with ID {id} not found." });
                }

                return Ok(purchaseOrder);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase order with ID {PurchaseOrderId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the purchase order." });
            }
        }

        [HttpPost]
        public async Task<ActionResult<PurchaseOrderDetails>> Create([FromBody] PurchaseOrderCreateRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return ValidationProblem(ModelState);
                }

                var purchaseOrder = await _purchaseOrderService.CreateAsync(request, UserId);
                return CreatedAtAction(nameof(GetById), new { id = purchaseOrder.PurchaseOrderId }, purchaseOrder);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase order");
                return StatusCode(500, new { message = "An error occurred while creating the purchase order." });
            }
        }

        [HttpPut("{id:int}")]
        public async Task<ActionResult> Update(int id, [FromBody] PurchaseOrderUpdateRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return ValidationProblem(ModelState);
                }

                var updated = await _purchaseOrderService.UpdateAsync(id, request, UserId);
                if (!updated)
                {
                    return NotFound(new { message = $"Purchase order with ID {id} not found." });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating purchase order with ID {PurchaseOrderId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the purchase order." });
            }
        }

        [HttpPost("{id:int}/reject")]
        public async Task<ActionResult> Reject(int id, [FromBody] PurchaseOrderRejectRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return ValidationProblem(ModelState);
                }

                var rejected = await _purchaseOrderService.RejectAsync(id, request.Remarks, UserId);
                if (!rejected)
                {
                    return NotFound(new { message = $"Purchase order with ID {id} not found." });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error rejecting purchase order with ID {PurchaseOrderId}", id);
                return StatusCode(500, new { message = "An error occurred while rejecting the purchase order." });
            }
        }

        [HttpGet("{id:int}/log")]
        public async Task<ActionResult<List<PurchaseOrderItemLogEntry>>> GetItemLog(int id)
        {
            try
            {
                var log = await _purchaseOrderService.GetItemLogAsync(id);
                return Ok(log);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving item log for purchase order {PurchaseOrderId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the purchase order log." });
            }
        }

        [HttpGet("{id:int}/attachments")]
        public async Task<ActionResult<List<PurchaseOrderAttachment>>> GetAttachments(int id)
        {
            try
            {
                var attachments = await _purchaseOrderService.GetAttachmentsAsync(id);
                return Ok(attachments);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving attachments for purchase order {PurchaseOrderId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving attachments." });
            }
        }

        [HttpPost("{id:int}/attachments")]
        [RequestSizeLimit(25_000_000)]
        public async Task<ActionResult<PurchaseOrderAttachment>> UploadAttachment(int id, [FromForm] string? title, IFormFile? file)
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { message = "No file was uploaded." });
            }

            try
            {
                var uploadsRoot = Path.Combine(_environment.ContentRootPath, AttachmentsRootFolder, id.ToString());
                Directory.CreateDirectory(uploadsRoot);

                var storedFileName = $"{Guid.NewGuid():N}_{Path.GetFileName(file.FileName)}";
                var physicalPath = Path.Combine(uploadsRoot, storedFileName);

                using (var stream = new FileStream(physicalPath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                var storedRelativePath = Path.Combine(id.ToString(), storedFileName).Replace('\\', '/');
                var attachment = await _purchaseOrderService.AddAttachmentAsync(id, title, file.FileName, storedRelativePath, UserId);
                return Ok(attachment);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error uploading attachment for purchase order {PurchaseOrderId}", id);
                return StatusCode(500, new { message = "An error occurred while uploading the attachment." });
            }
        }

        [HttpGet("attachments/{attachmentId:int}/download")]
        public async Task<IActionResult> DownloadAttachment(int attachmentId)
        {
            try
            {
                var attachment = await _purchaseOrderService.GetAttachmentAsync(attachmentId);
                if (attachment == null)
                {
                    return NotFound(new { message = $"Attachment with ID {attachmentId} not found." });
                }

                var physicalPath = Path.Combine(_environment.ContentRootPath, AttachmentsRootFolder, attachment.FileUrl);
                if (!System.IO.File.Exists(physicalPath))
                {
                    return NotFound(new { message = "Attachment file is missing from disk." });
                }

                var bytes = await System.IO.File.ReadAllBytesAsync(physicalPath);
                return File(bytes, "application/octet-stream", attachment.FileName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error downloading attachment {AttachmentId}", attachmentId);
                return StatusCode(500, new { message = "An error occurred while downloading the attachment." });
            }
        }

        [HttpDelete("attachments/{attachmentId:int}")]
        public async Task<ActionResult> DeleteAttachment(int attachmentId)
        {
            try
            {
                var attachment = await _purchaseOrderService.GetAttachmentAsync(attachmentId);
                if (attachment == null)
                {
                    return NotFound(new { message = $"Attachment with ID {attachmentId} not found." });
                }

                var deleted = await _purchaseOrderService.DeleteAttachmentAsync(attachmentId);
                if (!deleted)
                {
                    return NotFound(new { message = $"Attachment with ID {attachmentId} not found." });
                }

                var physicalPath = Path.Combine(_environment.ContentRootPath, AttachmentsRootFolder, attachment.FileUrl);
                if (System.IO.File.Exists(physicalPath))
                {
                    System.IO.File.Delete(physicalPath);
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting attachment {AttachmentId}", attachmentId);
                return StatusCode(500, new { message = "An error occurred while deleting the attachment." });
            }
        }
    }
}