using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PurchaseOrderTypesController : ControllerBase
    {
        private readonly IPurchaseOrderTypeService _service;
        private readonly ILogger<PurchaseOrderTypesController> _logger;

        public PurchaseOrderTypesController(IPurchaseOrderTypeService service, ILogger<PurchaseOrderTypesController> logger)
        {
            _service = service;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IReadOnlyList<PurchaseOrderTypeDto>>> GetAll()
        {
            try
            {
                return Ok(await _service.GetAllAsync());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase order types");
                return StatusCode(500, new { message = "An error occurred while retrieving purchase order types." });
            }
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<PurchaseOrderTypeDto>> GetById(int id)
        {
            try
            {
                var purchaseOrderType = await _service.GetByIdAsync(id);
                if (purchaseOrderType == null)
                {
                    return NotFound(new { message = $"Purchase order type with ID {id} not found." });
                }

                return Ok(purchaseOrderType);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase order type with ID {PurchaseOrderTypeId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the purchase order type." });
            }
        }

        [HttpPost]
        public async Task<ActionResult<PurchaseOrderTypeDto>> Create([FromBody] PurchaseOrderTypeUpsertRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var created = await _service.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = created.PurchaseOrderTypeId }, created);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase order type");
                return StatusCode(500, new { message = "An error occurred while creating the purchase order type." });
            }
        }

        [HttpPut("{id:int}")]
        public async Task<ActionResult<PurchaseOrderTypeDto>> Update(int id, [FromBody] PurchaseOrderTypeUpsertRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var updated = await _service.UpdateAsync(id, request);
                if (updated == null)
                {
                    return NotFound(new { message = $"Purchase order type with ID {id} not found." });
                }

                return Ok(updated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating purchase order type with ID {PurchaseOrderTypeId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the purchase order type." });
            }
        }

        [HttpDelete("{id:int}")]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                var deleted = await _service.DeleteAsync(id);
                if (!deleted)
                {
                    return NotFound(new { message = $"Purchase order type with ID {id} not found." });
                }

                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                _logger.LogWarning(ex, "Delete blocked for purchase order type with ID {PurchaseOrderTypeId}", id);
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting purchase order type with ID {PurchaseOrderTypeId}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the purchase order type." });
            }
        }
    }
}