using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockTypeAssociationsController : ControllerBase
    {
        private readonly IStockTypeAssociationService _stockTypeAssociationService;
        private readonly ILogger<StockTypeAssociationsController> _logger;

        public StockTypeAssociationsController(
            IStockTypeAssociationService stockTypeAssociationService,
            ILogger<StockTypeAssociationsController> logger)
        {
            _stockTypeAssociationService = stockTypeAssociationService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<StockTypeAssociation>>> GetAllStockTypeAssociations()
        {
            try
            {
                var associations = await _stockTypeAssociationService.GetAllStockTypeAssociationsAsync();
                return Ok(associations);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock type associations");
                return StatusCode(500, "An error occurred while retrieving stock type associations");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<StockTypeAssociation>> GetStockTypeAssociationById(int id)
        {
            try
            {
                var association = await _stockTypeAssociationService.GetStockTypeAssociationByIdAsync(id);

                if (association == null)
                {
                    return NotFound($"Stock type association with ID {id} not found");
                }

                return Ok(association);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock type association with ID {Id}", id);
                return StatusCode(500, "An error occurred while retrieving the stock type association");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> CreateStockTypeAssociation([FromBody] StockTypeAssociationRequest request)
        {
            try
            {
                if (request.PharmacyStoreId <= 0)
                {
                    return BadRequest("Store is required");
                }

                if (request.StockTypes <= 0)
                {
                    return BadRequest("Stock type is required");
                }

                if (request.PatientTypes <= 0)
                {
                    return BadRequest("Patient type is required");
                }

                var id = await _stockTypeAssociationService.CreateStockTypeAssociationAsync(request);
                return CreatedAtAction(nameof(GetStockTypeAssociationById), new { id }, new { id });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating stock type association");
                return StatusCode(500, "An error occurred while creating the stock type association");
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> UpdateStockTypeAssociation(int id, [FromBody] StockTypeAssociationRequest request)
        {
            try
            {
                if (request.PharmacyStoreId <= 0)
                {
                    return BadRequest("Store is required");
                }

                if (request.StockTypes <= 0)
                {
                    return BadRequest("Stock type is required");
                }

                if (request.PatientTypes <= 0)
                {
                    return BadRequest("Patient type is required");
                }

                var success = await _stockTypeAssociationService.UpdateStockTypeAssociationAsync(id, request);

                if (!success)
                {
                    return NotFound($"Stock type association with ID {id} not found");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating stock type association with ID {Id}", id);
                return StatusCode(500, "An error occurred while updating the stock type association");
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteStockTypeAssociation(int id)
        {
            try
            {
                var success = await _stockTypeAssociationService.DeleteStockTypeAssociationAsync(id);

                if (!success)
                {
                    return NotFound($"Stock type association with ID {id} not found");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting stock type association with ID {Id}", id);
                return StatusCode(500, "An error occurred while deleting the stock type association");
            }
        }
    }
}
