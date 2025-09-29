using InventoryManagement.Api.DTOs;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ManufacturersController : ControllerBase
    {
        private readonly IManufacturerService _manufacturerService;

        public ManufacturersController(IManufacturerService manufacturerService)
        {
            _manufacturerService = manufacturerService;
        }

        /// <summary>
        /// Get all manufacturers
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ManufacturerDto>>> GetManufacturers()
        {
            var manufacturers = await _manufacturerService.GetAllManufacturersAsync();
            return Ok(manufacturers);
        }

        /// <summary>
        /// Get a manufacturer by ID
        /// </summary>
        [HttpGet("{id}")]
        public async Task<ActionResult<ManufacturerDto>> GetManufacturer(int id)
        {
            var manufacturer = await _manufacturerService.GetManufacturerByIdAsync(id);
            if (manufacturer == null)
                return NotFound($"Manufacturer with ID {id} not found");

            return Ok(manufacturer);
        }

        /// <summary>
        /// Create a new manufacturer
        /// </summary>
        [HttpPost]
        public async Task<ActionResult<ManufacturerDto>> CreateManufacturer(CreateManufacturerDto createManufacturerDto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var manufacturer = await _manufacturerService.CreateManufacturerAsync(createManufacturerDto);
                return CreatedAtAction(nameof(GetManufacturer), new { id = manufacturer.Id }, manufacturer);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        /// <summary>
        /// Update a manufacturer
        /// </summary>
        [HttpPut("{id}")]
        public async Task<ActionResult<ManufacturerDto>> UpdateManufacturer(int id, UpdateManufacturerDto updateManufacturerDto)
        {
            if (!ModelState.IsValid)
                return BadRequest(ModelState);

            try
            {
                var manufacturer = await _manufacturerService.UpdateManufacturerAsync(id, updateManufacturerDto);
                if (manufacturer == null)
                    return NotFound($"Manufacturer with ID {id} not found");

                return Ok(manufacturer);
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        /// <summary>
        /// Delete a manufacturer
        /// </summary>
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteManufacturer(int id)
        {
            var success = await _manufacturerService.DeleteManufacturerAsync(id);
            if (!success)
                return NotFound($"Manufacturer with ID {id} not found");

            return NoContent();
        }
    }
}