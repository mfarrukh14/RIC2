using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PurchaseOrderStatusesController : ControllerBase
    {
        private readonly IPurchaseOrderStatusService _service;
        private readonly ILogger<PurchaseOrderStatusesController> _logger;

        public PurchaseOrderStatusesController(IPurchaseOrderStatusService service, ILogger<PurchaseOrderStatusesController> logger)
        {
            _service = service;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IReadOnlyList<PurchaseOrderStatusDto>>> GetAll()
        {
            try
            {
                return Ok(await _service.GetAllAsync());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase order statuses");
                return StatusCode(500, new { message = "An error occurred while retrieving purchase order statuses." });
            }
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<PurchaseOrderStatusDto>> GetById(int id)
        {
            try
            {
                var status = await _service.GetByIdAsync(id);
                if (status == null)
                {
                    return NotFound(new { message = $"Purchase order status with ID {id} not found." });
                }

                return Ok(status);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase order status with ID {PurchaseOrderStatusId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the purchase order status." });
            }
        }

        [HttpPost]
        public async Task<ActionResult<PurchaseOrderStatusDto>> Create([FromBody] PurchaseOrderStatusUpsertRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var created = await _service.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = created.PurchaseOrderStatusId }, created);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase order status");
                return StatusCode(500, new { message = "An error occurred while creating the purchase order status." });
            }
        }

        [HttpPut("{id:int}")]
        public async Task<ActionResult<PurchaseOrderStatusDto>> Update(int id, [FromBody] PurchaseOrderStatusUpsertRequest request)
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
                    return NotFound(new { message = $"Purchase order status with ID {id} not found." });
                }

                return Ok(updated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating purchase order status with ID {PurchaseOrderStatusId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the purchase order status." });
            }
        }
    }
}