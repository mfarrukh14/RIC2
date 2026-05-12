using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StoreAllocationToUserController : ControllerBase
    {
        private readonly IStoreAllocationToUserService _service;
        private readonly ILogger<StoreAllocationToUserController> _logger;

        public StoreAllocationToUserController(IStoreAllocationToUserService service, ILogger<StoreAllocationToUserController> logger)
        {
            _service = service;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<StoreAllocationToUser>>> GetAll()
        {
            try
            {
                var allocations = await _service.GetAllAsync();
                return Ok(allocations);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving all store allocations");
                return StatusCode(500, new { message = "An error occurred while retrieving allocations" });
            }
        }

        [HttpGet("employee-dropdown")]
        public async Task<ActionResult<IEnumerable<DropdownItem>>> GetEmployeeDropdown()
        {
            try
            {
                var employees = await _service.GetEmployeeDropdownAsync();
                return Ok(employees);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving employee dropdown");
                return StatusCode(500, new { message = "An error occurred while retrieving the employee dropdown" });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<StoreAllocationToUser>> GetById(int id)
        {
            try
            {
                var allocation = await _service.GetByIdAsync(id);
                
                if (allocation == null)
                {
                    return NotFound(new { message = $"Allocation with ID {id} not found" });
                }

                return Ok(allocation);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving allocation with ID: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the allocation" });
            }
        }

        [HttpPost]
        public async Task<ActionResult<StoreAllocationToUser>> Create([FromBody] StoreAllocationToUserCreateRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var allocation = await _service.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = allocation.Id }, allocation);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating store allocation");
                return StatusCode(500, new { message = "An error occurred while creating the allocation" });
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] StoreAllocationToUserUpdateRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                if (id != request.Id)
                {
                    return BadRequest(new { message = "ID mismatch" });
                }

                var existing = await _service.GetByIdAsync(id);
                if (existing == null)
                {
                    return NotFound(new { message = $"Allocation with ID {id} not found" });
                }

                await _service.UpdateAsync(id, request);
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating allocation with ID: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the allocation" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                var existing = await _service.GetByIdAsync(id);
                if (existing == null)
                {
                    return NotFound(new { message = $"Allocation with ID {id} not found" });
                }

                await _service.DeleteAsync(id);
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting allocation with ID: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the allocation" });
            }
        }
    }
}
