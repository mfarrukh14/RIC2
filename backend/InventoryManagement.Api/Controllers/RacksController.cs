using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RacksController : ControllerBase
    {
        private readonly IRackService _rackService;
        private readonly ILogger<RacksController> _logger;

        public RacksController(IRackService rackService, ILogger<RacksController> logger)
        {
            _rackService = rackService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Rack>>> GetAll()
        {
            try
            {
                var racks = await _rackService.GetAllRacksAsync();
                return Ok(racks);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving racks");
                return StatusCode(500, "An error occurred while retrieving racks");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Rack>> GetById(int id)
        {
            try
            {
                var rack = await _rackService.GetRackByIdAsync(id);
                if (rack == null)
                    return NotFound($"Rack with ID {id} not found");

                return Ok(rack);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack with ID {RackId}", id);
                return StatusCode(500, "An error occurred while retrieving the rack");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> Create([FromBody] RackRequest request)
        {
            try
            {
                var userId = 1;
                var id = await _rackService.CreateRackAsync(request, userId);
                return CreatedAtAction(nameof(GetById), new { id }, new { id });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating rack");
                return StatusCode(500, "An error occurred while creating the rack");
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] RackRequest request)
        {
            try
            {
                request.Id = id;
                var userId = 1;
                await _rackService.UpdateRackAsync(request, userId);
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating rack with ID {RackId}", id);
                return StatusCode(500, "An error occurred while updating the rack");
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var userId = 1;
                await _rackService.DeleteRackAsync(id, userId);
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting rack with ID {RackId}", id);
                return StatusCode(500, "An error occurred while deleting the rack");
            }
        }
    }
}
