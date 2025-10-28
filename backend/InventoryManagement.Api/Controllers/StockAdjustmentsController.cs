using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockAdjustmentsController : ControllerBase
    {
        private readonly IStockAdjustmentService _stockAdjustmentService;
        private readonly ILogger<StockAdjustmentsController> _logger;

        public StockAdjustmentsController(
            IStockAdjustmentService stockAdjustmentService, 
            ILogger<StockAdjustmentsController> logger)
        {
            _stockAdjustmentService = stockAdjustmentService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<StockAdjustmentView>>> GetAll([FromQuery] StockAdjustmentSearchRequest? request)
        {
            try
            {
                var stockAdjustments = await _stockAdjustmentService.GetAllAsync(request);
                return Ok(stockAdjustments);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock adjustments");
                return StatusCode(500, new { message = "An error occurred while retrieving stock adjustments" });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<StockAdjustment>> GetById(int id)
        {
            try
            {
                var stockAdjustment = await _stockAdjustmentService.GetByIdAsync(id);
                
                if (stockAdjustment == null)
                {
                    return NotFound(new { message = $"Stock adjustment with ID {id} not found" });
                }

                return Ok(stockAdjustment);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock adjustment with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the stock adjustment" });
            }
        }

        [HttpPost]
        public async Task<ActionResult<StockAdjustment>> Create([FromBody] StockAdjustmentCreateRequest request)
        {
            try
            {
                if (request.Details == null || !request.Details.Any())
                {
                    return BadRequest(new { message = "At least one detail item is required" });
                }

                var stockAdjustment = await _stockAdjustmentService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = stockAdjustment.Id }, stockAdjustment);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating stock adjustment");
                return StatusCode(500, new { message = "An error occurred while creating the stock adjustment" });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<StockAdjustment>> Update(int id, [FromBody] StockAdjustmentUpdateRequest request)
        {
            try
            {
                if (id != request.Id)
                {
                    return BadRequest(new { message = "ID mismatch" });
                }

                if (request.Details == null || !request.Details.Any())
                {
                    return BadRequest(new { message = "At least one detail item is required" });
                }

                var stockAdjustment = await _stockAdjustmentService.UpdateAsync(request);
                return Ok(stockAdjustment);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating stock adjustment with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the stock adjustment" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var result = await _stockAdjustmentService.DeleteAsync(id);
                
                if (!result)
                {
                    return NotFound(new { message = $"Stock adjustment with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting stock adjustment with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the stock adjustment" });
            }
        }
    }
}
