using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SpaceAllocationController : ControllerBase
    {
        private readonly ISpaceAllocationService _spaceAllocationService;
        private readonly ILogger<SpaceAllocationController> _logger;

        public SpaceAllocationController(ISpaceAllocationService spaceAllocationService, ILogger<SpaceAllocationController> logger)
        {
            _spaceAllocationService = spaceAllocationService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var allocations = await _spaceAllocationService.GetAllSpaceAllocationsAsync();
                return Ok(allocations);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving space allocations");
                return StatusCode(500, new { message = "An error occurred while retrieving space allocations" });
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            try
            {
                var allocation = await _spaceAllocationService.GetSpaceAllocationByIdAsync(id);
                if (allocation == null)
                {
                    return NotFound(new { message = "Space allocation not found" });
                }
                return Ok(allocation);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving space allocation: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the space allocation" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] SpaceAllocationCreateRequest request)
        {
            try
            {
                var created = await _spaceAllocationService.CreateSpaceAllocationAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating space allocation");
                return StatusCode(500, new { message = "An error occurred while creating the space allocation" });
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] SpaceAllocationUpdateRequest request)
        {
            try
            {
                var success = await _spaceAllocationService.UpdateSpaceAllocationAsync(id, request);
                if (!success)
                {
                    return NotFound(new { message = "Space allocation not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating space allocation: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the space allocation" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            try
            {
                var success = await _spaceAllocationService.DeleteSpaceAllocationAsync(id);
                if (!success)
                {
                    return NotFound(new { message = "Space allocation not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting space allocation: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the space allocation" });
            }
        }
    }
}
