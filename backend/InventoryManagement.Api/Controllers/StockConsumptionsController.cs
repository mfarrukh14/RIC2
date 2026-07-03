using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockConsumptionsController : BaseController
    {
        private readonly IStockConsumptionService _stockConsumptionService;
        private readonly ILogger<StockConsumptionsController> _logger;

        public StockConsumptionsController(
            IUserSessionCacheService sessionCache,
            IStockConsumptionService stockConsumptionService,
            ILogger<StockConsumptionsController> logger)
            : base(sessionCache)
        {
            _stockConsumptionService = stockConsumptionService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<StockConsumptionView>>> GetAll([FromQuery] StockConsumptionSearchRequest? request)
        {
            try
            {
                var stockConsumptions = await _stockConsumptionService.GetAllAsync(request);
                return Ok(stockConsumptions);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock consumptions");
                return StatusCode(500, new { message = "An error occurred while retrieving stock consumptions" });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<StockConsumption>> GetById(Guid id)
        {
            try
            {
                var stockConsumption = await _stockConsumptionService.GetByIdAsync(id);
                
                if (stockConsumption == null)
                {
                    return NotFound(new { message = $"Stock consumption with ID {id} not found" });
                }

                return Ok(stockConsumption);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock consumption with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the stock consumption" });
            }
        }

        [HttpPost]
        public async Task<ActionResult<StockConsumption>> Create([FromBody] StockConsumptionCreateRequest request)
        {
            try
            {
                if (request.Details == null || !request.Details.Any())
                {
                    return BadRequest(new { message = "At least one detail item is required" });
                }

                var stockConsumption = await _stockConsumptionService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = stockConsumption.Id }, stockConsumption);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating stock consumption");
                return StatusCode(500, new { message = "An error occurred while creating the stock consumption" });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult<StockConsumption>> Update(Guid id, [FromBody] StockConsumptionUpdateRequest request)
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

                var stockConsumption = await _stockConsumptionService.UpdateAsync(request);
                return Ok(stockConsumption);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating stock consumption with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the stock consumption" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(Guid id)
        {
            try
            {
                var result = await _stockConsumptionService.DeleteAsync(id);
                
                if (!result)
                {
                    return NotFound(new { message = $"Stock consumption with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting stock consumption with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the stock consumption" });
            }
        }
    }
}
