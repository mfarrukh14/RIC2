using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class GRNController : BaseController
    {
        private readonly IGRNService _grnService;
        private readonly ILogger<GRNController> _logger;

        public GRNController(IUserSessionCacheService sessionCache, IGRNService grnService, ILogger<GRNController> logger)
            : base(sessionCache)
        {
            _grnService = grnService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<List<GRN>>> GetAll()
        {
            try
            {
                var grns = await _grnService.GetAllAsync();
                return Ok(grns);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving GRNs");
                return StatusCode(500, new { message = "An error occurred while retrieving GRNs" });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<GRN>> GetById(int id)
        {
            try
            {
                var grn = await _grnService.GetByIdAsync(id);
                if (grn == null)
                {
                    return NotFound(new { message = $"GRN with ID {id} not found" });
                }
                return Ok(grn);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving GRN with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the GRN" });
            }
        }

        [HttpGet("po/{purchaseOrderId}")]
        public async Task<ActionResult<POForGRN>> GetPODetails(int purchaseOrderId)
        {
            try
            {
                var po = await _grnService.GetPODetailsAsync(purchaseOrderId);
                if (po == null)
                {
                    return NotFound(new { message = $"Purchase Order with ID {purchaseOrderId} not found" });
                }
                return Ok(po);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving PO details with ID {PurchaseOrderId}", purchaseOrderId);
                return StatusCode(500, new { message = "An error occurred while retrieving PO details" });
            }
        }

        [HttpPost]
        public async Task<ActionResult<GRN>> Create([FromBody] GRNCreateRequest request)
        {
            try
            {
                var grn = await _grnService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = grn.Id }, grn);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating GRN");
                return StatusCode(500, new { message = "An error occurred while creating the GRN" });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] GRNUpdateRequest request)
        {
            try
            {
                var result = await _grnService.UpdateAsync(id, request);
                if (!result)
                {
                    return NotFound(new { message = $"GRN with ID {id} not found" });
                }
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating GRN with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the GRN" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var result = await _grnService.DeleteAsync(id);
                if (!result)
                {
                    return NotFound(new { message = $"GRN with ID {id} not found" });
                }
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting GRN with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the GRN" });
            }
        }

        [HttpGet("lookup")]
        public async Task<ActionResult<GRNLookupData>> GetLookupData()
        {
            try
            {
                var lookupData = await _grnService.GetLookupDataAsync();
                return Ok(lookupData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving GRN lookup data");
                return StatusCode(500, new { message = "An error occurred while retrieving lookup data" });
            }
        }
    }
}
