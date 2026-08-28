using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ManufacturersController : BaseController
    {
        private readonly IManufacturerService _manufacturerService;

        public ManufacturersController(IUserSessionCacheService sessionCache, IManufacturerService manufacturerService)
            : base(sessionCache)
        {
            _manufacturerService = manufacturerService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Manufacturer>>> GetAllManufacturers()
        {
            try
            {
                if (BranchId is not int branchId)
                {
                    return BadRequest("Current session has no branch assigned.");
                }

                var manufacturers = await _manufacturerService.GetAllManufacturersAsync(branchId);
                return Ok(manufacturers);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Manufacturer>> GetManufacturer(int id)
        {
            try
            {
                var manufacturer = await _manufacturerService.GetManufacturerByIdAsync(id);
                if (manufacturer == null)
                {
                    return NotFound($"Manufacturer with ID {id} not found.");
                }
                return Ok(manufacturer);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> CreateManufacturer([FromBody] CreateManufacturerRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Manufacturer name is required.");
                }

                request.BranchId = BranchId;
                var manufacturerId = await _manufacturerService.CreateManufacturerAsync(request);
                return CreatedAtAction(nameof(GetManufacturer), new { id = manufacturerId }, manufacturerId);
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateManufacturer(int id, [FromBody] UpdateManufacturerRequest request)
        {
            try
            {
                if (id != request.Id)
                {
                    return BadRequest("ID mismatch between route and request body.");
                }

                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Manufacturer name is required.");
                }

                request.BranchId = BranchId;
                var success = await _manufacturerService.UpdateManufacturerAsync(request);
                if (!success)
                {
                    return NotFound($"Manufacturer with ID {id} not found.");
                }

                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteManufacturer(int id, [FromQuery] int modifiedById = 1)
        {
            try
            {
                var success = await _manufacturerService.DeleteManufacturerAsync(id, modifiedById);
                if (!success)
                {
                    return NotFound($"Manufacturer with ID {id} not found.");
                }

                return NoContent();
            }
            catch (InvalidOperationException ex)
            {
                return Conflict(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}