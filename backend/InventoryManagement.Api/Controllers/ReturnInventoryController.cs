using Microsoft.AspNetCore.Mvc;
using InventoryManagement.API.Models;
using InventoryManagement.API.Services;

namespace InventoryManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ReturnInventoryController : ControllerBase
    {
        private readonly IReturnInventoryService _returnInventoryService;
        private readonly ILogger<ReturnInventoryController> _logger;

        public ReturnInventoryController(
            IReturnInventoryService returnInventoryService,
            ILogger<ReturnInventoryController> logger)
        {
            _returnInventoryService = returnInventoryService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<List<ReturnInventory>>> GetAll([FromQuery] ReturnInventoryFilterRequest? filter)
        {
            try
            {
                var returns = await _returnInventoryService.GetAllAsync(filter);
                return Ok(returns);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving return inventory records");
                return StatusCode(500, new { message = "An error occurred while retrieving return inventory records", error = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ReturnInventory>> GetById(int id)
        {
            try
            {
                var returnInventory = await _returnInventoryService.GetByIdAsync(id);
                if (returnInventory == null)
                {
                    return NotFound(new { message = $"Return inventory with ID {id} not found" });
                }
                return Ok(returnInventory);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving return inventory with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the return inventory", error = ex.Message });
            }
        }

        [HttpPost]
        public async Task<ActionResult<ReturnInventory>> Create([FromBody] ReturnInventoryCreateRequest request)
        {
            try
            {
                var returnInventory = await _returnInventoryService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = returnInventory.Id }, returnInventory);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating return inventory");
                return StatusCode(500, new { message = "An error occurred while creating the return inventory", error = ex.Message });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] ReturnInventoryUpdateRequest request)
        {
            try
            {
                var success = await _returnInventoryService.UpdateAsync(id, request);
                if (!success)
                {
                    return NotFound(new { message = $"Return inventory with ID {id} not found" });
                }
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating return inventory with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the return inventory", error = ex.Message });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var success = await _returnInventoryService.DeleteAsync(id);
                if (!success)
                {
                    return NotFound(new { message = $"Return inventory with ID {id} not found" });
                }
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting return inventory with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the return inventory", error = ex.Message });
            }
        }

        [HttpGet("lookup")]
        public async Task<ActionResult<ReturnInventoryLookupData>> GetLookupData()
        {
            try
            {
                var lookupData = await _returnInventoryService.GetLookupDataAsync();
                return Ok(lookupData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving return inventory lookup data");
                return StatusCode(500, new { message = "An error occurred while retrieving lookup data", error = ex.Message });
            }
        }
    }
}
