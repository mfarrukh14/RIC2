using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RackColumnController : ControllerBase
    {
        private readonly IRackColumnService _rackColumnService;
        private readonly ILogger<RackColumnController> _logger;

        public RackColumnController(IRackColumnService rackColumnService, ILogger<RackColumnController> logger)
        {
            _rackColumnService = rackColumnService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var rackColumns = await _rackColumnService.GetAllRackColumnsAsync();
                return Ok(rackColumns);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack columns");
                return StatusCode(500, new { message = "An error occurred while retrieving rack columns" });
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            try
            {
                var rackColumn = await _rackColumnService.GetRackColumnByIdAsync(id);
                if (rackColumn == null)
                {
                    return NotFound(new { message = "Rack column not found" });
                }
                return Ok(rackColumn);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack column: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the rack column" });
            }
        }

        [HttpGet("byrack/{rackId}")]
        public async Task<IActionResult> GetByRackId(int rackId)
        {
            try
            {
                var rackColumns = await _rackColumnService.GetRackColumnsByRackIdAsync(rackId);
                return Ok(rackColumns);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack columns for rack: {RackId}", rackId);
                return StatusCode(500, new { message = "An error occurred while retrieving rack columns" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] RackColumnCreateRequest request)
        {
            try
            {
                var userId = Guid.Empty; // TODO: Get from authenticated user
                var id = await _rackColumnService.CreateRackColumnAsync(request, userId);
                return CreatedAtAction(nameof(GetById), new { id }, new { id });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating rack column");
                return StatusCode(500, new { message = "An error occurred while creating the rack column" });
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(Guid id, [FromBody] RackColumnUpdateRequest request)
        {
            try
            {
                if (id != request.Id)
                {
                    return BadRequest(new { message = "ID mismatch" });
                }

                var userId = Guid.Empty; // TODO: Get from authenticated user
                var success = await _rackColumnService.UpdateRackColumnAsync(request, userId);
                
                if (!success)
                {
                    return NotFound(new { message = "Rack column not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating rack column: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the rack column" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            try
            {
                var success = await _rackColumnService.DeleteRackColumnAsync(id);
                
                if (!success)
                {
                    return NotFound(new { message = "Rack column not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting rack column: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the rack column" });
            }
        }
    }
}
