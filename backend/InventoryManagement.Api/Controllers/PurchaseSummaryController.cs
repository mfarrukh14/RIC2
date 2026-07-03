using Microsoft.AspNetCore.Mvc;
using InventoryManagement.API.Models;
using InventoryManagement.API.Services;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Controllers;

namespace InventoryManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PurchaseSummaryController : BaseController
    {
        private readonly IPurchaseSummaryService _purchaseSummaryService;
        private readonly ILogger<PurchaseSummaryController> _logger;

        public PurchaseSummaryController(
            IUserSessionCacheService sessionCache,
            IPurchaseSummaryService purchaseSummaryService,
            ILogger<PurchaseSummaryController> logger)
            : base(sessionCache)
        {
            _purchaseSummaryService = purchaseSummaryService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<PurchaseSummaryResponse>> GetAll([FromQuery] PurchaseSummaryFilterRequest? filter)
        {
            try
            {
                var response = await _purchaseSummaryService.GetAllAsync(filter);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase summary records");
                return StatusCode(500, new { message = "An error occurred while retrieving purchase summary records", error = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<PurchaseSummary>> GetById(int id)
        {
            try
            {
                var purchaseSummary = await _purchaseSummaryService.GetByIdAsync(id);
                if (purchaseSummary == null)
                {
                    return NotFound(new { message = $"Purchase summary with ID {id} not found" });
                }
                return Ok(purchaseSummary);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase summary with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the purchase summary", error = ex.Message });
            }
        }

        [HttpPost]
        public async Task<ActionResult<PurchaseSummary>> Create([FromBody] PurchaseSummaryCreateRequest request)
        {
            try
            {
                var purchaseSummary = await _purchaseSummaryService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = purchaseSummary.Id }, purchaseSummary);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase summary");
                return StatusCode(500, new { message = "An error occurred while creating the purchase summary", error = ex.Message });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] PurchaseSummaryUpdateRequest request)
        {
            try
            {
                var success = await _purchaseSummaryService.UpdateAsync(id, request);
                if (!success)
                {
                    return NotFound(new { message = $"Purchase summary with ID {id} not found" });
                }
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating purchase summary with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the purchase summary", error = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var success = await _purchaseSummaryService.DeleteAsync(id);
                if (!success)
                {
                    return NotFound(new { message = $"Purchase summary with ID {id} not found" });
                }
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting purchase summary with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the purchase summary", error = ex.Message });
            }
        }

        [HttpGet("lookup")]
        public async Task<ActionResult<PurchaseSummaryLookupData>> GetLookupData()
        {
            try
            {
                var lookupData = await _purchaseSummaryService.GetLookupDataAsync();
                return Ok(lookupData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase summary lookup data");
                return StatusCode(500, new { message = "An error occurred while retrieving lookup data", error = ex.Message });
            }
        }
    }
}
