using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RackRowController : ControllerBase
    {
        private readonly IRackRowService _rackRowService;
        private readonly ILogger<RackRowController> _logger;

        public RackRowController(IRackRowService rackRowService, ILogger<RackRowController> logger)
        {
            _rackRowService = rackRowService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var rows = await _rackRowService.GetAllRackRowsAsync();
                return Ok(rows);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack rows");
                return StatusCode(500, new { message = "An error occurred while retrieving rack rows" });
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            try
            {
                var row = await _rackRowService.GetRackRowByIdAsync(id);
                if (row == null)
                {
                    return NotFound(new { message = "Rack row not found" });
                }
                return Ok(row);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack row: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the rack row" });
            }
        }

        [HttpGet("byrack/{rackId}")]
        public async Task<IActionResult> GetByRackId(int rackId)
        {
            try
            {
                var rows = await _rackRowService.GetRackRowsByRackIdAsync(rackId);
                return Ok(rows);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving rack rows for rack: {RackId}", rackId);
                return StatusCode(500, new { message = "An error occurred while retrieving rack rows" });
            }
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] RackRowCreateRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest(new { message = "Name is required" });
                }

                var createdRow = await _rackRowService.CreateRackRowAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = createdRow.Id }, createdRow);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating rack row");
                return StatusCode(500, new { message = "An error occurred while creating the rack row" });
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] RackRowUpdateRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest(new { message = "Name is required" });
                }

                var success = await _rackRowService.UpdateRackRowAsync(id, request);
                if (!success)
                {
                    return NotFound(new { message = "Rack row not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating rack row: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the rack row" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                var success = await _rackRowService.DeleteRackRowAsync(id);
                if (!success)
                {
                    return NotFound(new { message = "Rack row not found" });
                }

                return NoContent();
            }
            catch (SqlException ex) when (ex.Message.Contains("Cannot delete rack row"))
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting rack row: {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the rack row" });
            }
        }
    }
}
