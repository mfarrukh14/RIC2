using Microsoft.AspNetCore.Mvc;
using InventoryManagement.API.Models;
using InventoryManagement.API.Services;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Controllers;

namespace InventoryManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PurchaseSummaryInvoiceController : BaseController
    {
        private readonly IPurchaseSummaryInvoiceService _purchaseSummaryInvoiceService;
        private readonly ILogger<PurchaseSummaryInvoiceController> _logger;

        public PurchaseSummaryInvoiceController(
            IUserSessionCacheService sessionCache,
            IPurchaseSummaryInvoiceService purchaseSummaryInvoiceService,
            ILogger<PurchaseSummaryInvoiceController> logger)
            : base(sessionCache)
        {
            _purchaseSummaryInvoiceService = purchaseSummaryInvoiceService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<PurchaseSummaryInvoiceResponse>> GetAll([FromQuery] PurchaseSummaryInvoiceFilterRequest? filter)
        {
            try
            {
                var response = await _purchaseSummaryInvoiceService.GetAllAsync(filter);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase summary invoice records");
                return StatusCode(500, new { message = "An error occurred while retrieving purchase summary invoice records", error = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<PurchaseSummaryInvoice>> GetById(int id)
        {
            try
            {
                var invoice = await _purchaseSummaryInvoiceService.GetByIdAsync(id);
                if (invoice == null)
                {
                    return NotFound(new { message = $"Purchase summary invoice with ID {id} not found" });
                }
                return Ok(invoice);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase summary invoice with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the purchase summary invoice", error = ex.Message });
            }
        }

        [HttpPost]
        public async Task<ActionResult<PurchaseSummaryInvoice>> Create([FromBody] PurchaseSummaryInvoiceCreateRequest request)
        {
            try
            {
                var invoice = await _purchaseSummaryInvoiceService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = invoice.Id }, invoice);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase summary invoice");
                return StatusCode(500, new { message = "An error occurred while creating the purchase summary invoice", error = ex.Message });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] PurchaseSummaryInvoiceUpdateRequest request)
        {
            try
            {
                var success = await _purchaseSummaryInvoiceService.UpdateAsync(id, request);
                if (!success)
                {
                    return NotFound(new { message = $"Purchase summary invoice with ID {id} not found" });
                }
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating purchase summary invoice with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the purchase summary invoice", error = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var success = await _purchaseSummaryInvoiceService.DeleteAsync(id);
                if (!success)
                {
                    return NotFound(new { message = $"Purchase summary invoice with ID {id} not found" });
                }
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting purchase summary invoice with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the purchase summary invoice", error = ex.Message });
            }
        }

        [HttpGet("lookup")]
        public async Task<ActionResult<PurchaseSummaryInvoiceLookupData>> GetLookupData()
        {
            try
            {
                var lookupData = await _purchaseSummaryInvoiceService.GetLookupDataAsync();
                return Ok(lookupData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase summary invoice lookup data");
                return StatusCode(500, new { message = "An error occurred while retrieving lookup data", error = ex.Message });
            }
        }
    }
}
