using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PackingsController : ControllerBase
    {
        private readonly IPackingService _packingService;

        public PackingsController(IPackingService packingService)
        {
            _packingService = packingService;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Packing>>> GetAllPackings()
        {
            try
            {
                var packings = await _packingService.GetAllPackingsAsync();
                return Ok(packings);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Packing>> GetPacking(int id)
        {
            try
            {
                var packing = await _packingService.GetPackingByIdAsync(id);
                if (packing == null)
                {
                    return NotFound($"Packing with ID {id} not found.");
                }
                return Ok(packing);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> CreatePacking([FromBody] CreatePackingRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Packing name is required.");
                }

                var packingId = await _packingService.CreatePackingAsync(request);
                return CreatedAtAction(nameof(GetPacking), new { id = packingId }, packingId);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdatePacking(int id, [FromBody] UpdatePackingRequest request)
        {
            try
            {
                if (id != request.Id)
                {
                    return BadRequest("ID mismatch between route and request body.");
                }

                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest("Packing name is required.");
                }

                var success = await _packingService.UpdatePackingAsync(request);
                if (!success)
                {
                    return NotFound($"Packing with ID {id} not found.");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeletePacking(int id, [FromQuery] int modifiedById = 1)
        {
            try
            {
                var success = await _packingService.DeletePackingAsync(id, modifiedById);
                if (!success)
                {
                    return NotFound($"Packing with ID {id} not found.");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}