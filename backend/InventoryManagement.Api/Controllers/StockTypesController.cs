using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockTypesController : BaseController
    {
        private readonly IStockTypeService _stockTypeService;
        private readonly ILogger<StockTypesController> _logger;

        public StockTypesController(IUserSessionCacheService sessionCache, IStockTypeService stockTypeService, ILogger<StockTypesController> logger)
            : base(sessionCache)
        {
            _stockTypeService = stockTypeService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<StockType>>> GetAllStockTypes()
        {
            try
            {
                var stockTypes = await _stockTypeService.GetAllStockTypesAsync();
                return Ok(stockTypes);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock types");
                return StatusCode(500, "An error occurred while retrieving stock types");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<StockType>> GetStockTypeById(int id)
        {
            try
            {
                var stockType = await _stockTypeService.GetStockTypeByIdAsync(id);

                if (stockType == null)
                {
                    return NotFound($"Stock type with ID {id} not found");
                }

                return Ok(stockType);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock type with ID {Id}", id);
                return StatusCode(500, "An error occurred while retrieving the stock type");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> CreateStockType([FromBody] StockTypeRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Stock type name is required");
                }

                var id = await _stockTypeService.CreateStockTypeAsync(request);
                return CreatedAtAction(nameof(GetStockTypeById), new { id }, new { id });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating stock type");
                return StatusCode(500, "An error occurred while creating the stock type");
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> UpdateStockType(int id, [FromBody] StockTypeRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Stock type name is required");
                }

                var success = await _stockTypeService.UpdateStockTypeAsync(id, request);

                if (!success)
                {
                    return NotFound($"Stock type with ID {id} not found");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating stock type with ID {Id}", id);
                return StatusCode(500, "An error occurred while updating the stock type");
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteStockType(int id)
        {
            try
            {
                var success = await _stockTypeService.DeleteStockTypeAsync(id);

                if (!success)
                {
                    return NotFound($"Stock type with ID {id} not found");
                }

                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting stock type with ID {Id}", id);
                return StatusCode(500, "An error occurred while deleting the stock type");
            }
        }
    }
}
