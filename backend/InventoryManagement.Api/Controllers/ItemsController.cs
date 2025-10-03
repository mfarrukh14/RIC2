using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ItemsController : ControllerBase
    {
        private readonly IItemService _itemService;
        private readonly ILogger<ItemsController> _logger;

        public ItemsController(IItemService itemService, ILogger<ItemsController> logger)
        {
            _itemService = itemService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<Item>>> GetAll()
        {
            try
            {
                var items = await _itemService.GetAllAsync();
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving items");
                return StatusCode(500, new { message = "An error occurred while retrieving items" });
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<Item>> GetById(int id)
        {
            try
            {
                var item = await _itemService.GetByIdAsync(id);
                
                if (item == null)
                {
                    return NotFound(new { message = $"Item with ID {id} not found" });
                }

                return Ok(item);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving item with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the item" });
            }
        }

        [HttpPost]
        public async Task<ActionResult<Item>> Create([FromBody] ItemCreateRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest(new { message = "Item name is required" });
                }

                var id = await _itemService.CreateAsync(request);
                var item = await _itemService.GetByIdAsync(id);
                
                return CreatedAtAction(nameof(GetById), new { id }, item);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating item");
                return StatusCode(500, new { message = "An error occurred while creating the item" });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] ItemUpdateRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Name))
                {
                    return BadRequest(new { message = "Item name is required" });
                }

                var success = await _itemService.UpdateAsync(id, request);
                
                if (!success)
                {
                    return NotFound(new { message = $"Item with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating item with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while updating the item" });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var success = await _itemService.DeleteAsync(id);
                
                if (!success)
                {
                    return NotFound(new { message = $"Item with ID {id} not found" });
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting item with ID {Id}", id);
                return StatusCode(500, new { message = "An error occurred while deleting the item" });
            }
        }

        [HttpGet("categories")]
        public async Task<ActionResult<IEnumerable<Category>>> GetCategories()
        {
            try
            {
                var categories = await _itemService.GetCategoriesAsync();
                return Ok(categories);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving categories");
                return StatusCode(500, new { message = "An error occurred while retrieving categories" });
            }
        }

        [HttpGet("subcategories")]
        public async Task<ActionResult<IEnumerable<SubCategory>>> GetSubCategories()
        {
            try
            {
                var subCategories = await _itemService.GetSubCategoriesAsync();
                return Ok(subCategories);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sub-categories");
                return StatusCode(500, new { message = "An error occurred while retrieving sub-categories" });
            }
        }

        [HttpGet("prices")]
        public async Task<ActionResult<IEnumerable<Price>>> GetPrices()
        {
            try
            {
                var prices = await _itemService.GetPricesAsync();
                return Ok(prices);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving prices");
                return StatusCode(500, new { message = "An error occurred while retrieving prices" });
            }
        }

        [HttpGet("taxrates")]
        public async Task<ActionResult<IEnumerable<TaxRate>>> GetTaxRates()
        {
            try
            {
                var taxRates = await _itemService.GetTaxRatesAsync();
                return Ok(taxRates);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving tax rates");
                return StatusCode(500, new { message = "An error occurred while retrieving tax rates" });
            }
        }

        [HttpGet("taxdescriptions")]
        public async Task<ActionResult<IEnumerable<TaxDescription>>> GetTaxDescriptions()
        {
            try
            {
                var taxDescriptions = await _itemService.GetTaxDescriptionsAsync();
                return Ok(taxDescriptions);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving tax descriptions");
                return StatusCode(500, new { message = "An error occurred while retrieving tax descriptions" });
            }
        }

        [HttpGet("taxtypes")]
        public async Task<ActionResult<IEnumerable<TaxType>>> GetTaxTypes()
        {
            try
            {
                var taxTypes = await _itemService.GetTaxTypesAsync();
                return Ok(taxTypes);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving tax types");
                return StatusCode(500, new { message = "An error occurred while retrieving tax types" });
            }
        }
    }
}