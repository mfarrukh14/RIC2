using Microsoft.AspNetCore.Mvc;
using InventoryManagement.API.Models;
using InventoryManagement.API.Services;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Controllers;

namespace InventoryManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SampleCollectionConsumptionItemsController : BaseController
    {
        private readonly ISampleCollectionConsumptionItemService _service;
        private readonly ILogger<SampleCollectionConsumptionItemsController> _logger;

        public SampleCollectionConsumptionItemsController(
            IUserSessionCacheService sessionCache,
            ISampleCollectionConsumptionItemService service,
            ILogger<SampleCollectionConsumptionItemsController> logger)
            : base(sessionCache)
        {
            _service = service;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<SampleCollectionConsumptionItem>>> GetAll()
        {
            try
            {
                var items = await _service.GetAllAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sample collection consumption items");
                return StatusCode(500, "An error occurred while retrieving the data.");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<SampleCollectionConsumptionItem>> GetById(int id)
        {
            try
            {
                var item = await _service.GetByIdAsync(id);
                if (item == null)
                {
                    return NotFound($"Sample collection consumption item with ID {id} not found.");
                }
                return Ok(item);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sample collection consumption item with id {Id}", id);
                return StatusCode(500, "An error occurred while retrieving the data.");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> Create([FromBody] CreateSampleCollectionConsumptionItemRequest request)
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
                _logger.LogError(ex, "Error creating sample collection consumption item");
                return StatusCode(500, "An error occurred while creating the item.");
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] UpdateSampleCollectionConsumptionItemRequest request)
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
                    return NotFound($"Sample collection consumption item with ID {id} not found.");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating sample collection consumption item with id {Id}", id);
                return StatusCode(500, "An error occurred while updating the item.");
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
                    return NotFound($"Sample collection consumption item with ID {id} not found.");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting sample collection consumption item with id {Id}", id);
                return StatusCode(500, "An error occurred while deleting the item.");
            }
        }

        [HttpGet("lookup")]
        public async Task<ActionResult<SampleCollectionConsumptionItemLookupData>> GetLookupData()
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
