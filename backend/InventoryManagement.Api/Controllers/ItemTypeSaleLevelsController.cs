using Microsoft.AspNetCore.Mvc;
using InventoryManagement.API.Models;
using InventoryManagement.API.Services;

namespace InventoryManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ItemTypeSaleLevelsController : ControllerBase
    {
        private readonly IItemTypeSaleLevelService _service;
        private readonly ILogger<ItemTypeSaleLevelsController> _logger;

        public ItemTypeSaleLevelsController(
            IItemTypeSaleLevelService service,
            ILogger<ItemTypeSaleLevelsController> logger)
        {
            _service = service;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<ItemTypeSaleLevel>>> GetAll()
        {
            try
            {
                var levels = await _service.GetAllAsync();
                return Ok(levels);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving item type sale levels");
                return StatusCode(500, "An error occurred while retrieving the data.");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<ItemTypeSaleLevel>> GetById(int id)
        {
            try
            {
                var level = await _service.GetByIdAsync(id);
                if (level == null)
                {
                    return NotFound($"Item type sale level with ID {id} not found.");
                }
                return Ok(level);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving item type sale level with id {Id}", id);
                return StatusCode(500, "An error occurred while retrieving the data.");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> Create([FromBody] CreateItemTypeSaleLevelRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var id = await _service.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id }, id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating item type sale level");
                return StatusCode(500, "An error occurred while creating the level.");
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] UpdateItemTypeSaleLevelRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var success = await _service.UpdateAsync(id, request);
                if (!success)
                {
                    return NotFound($"Item type sale level with ID {id} not found.");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating item type sale level with id {Id}", id);
                return StatusCode(500, "An error occurred while updating the level.");
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var success = await _service.DeleteAsync(id);
                if (!success)
                {
                    return NotFound($"Item type sale level with ID {id} not found.");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting item type sale level with id {Id}", id);
                return StatusCode(500, "An error occurred while deleting the level.");
            }
        }

        [HttpGet("lookup")]
        public async Task<ActionResult<ItemTypeSaleLevelLookupData>> GetLookupData()
        {
            try
            {
                var lookupData = await _service.GetLookupDataAsync();
                return Ok(lookupData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving lookup data");
                return StatusCode(500, "An error occurred while retrieving lookup data.");
            }
        }
    }
}
