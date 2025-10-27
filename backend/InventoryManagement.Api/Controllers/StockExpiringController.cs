using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockExpiringController : ControllerBase
    {
        private readonly IStockExpiringService _stockExpiringService;
        private readonly ILogger<StockExpiringController> _logger;

        public StockExpiringController(
            IStockExpiringService stockExpiringService,
            ILogger<StockExpiringController> logger)
        {
            _stockExpiringService = stockExpiringService;
            _logger = logger;
        }

        [HttpPost("search")]
        public async Task<ActionResult<IEnumerable<StockExpiringItem>>> GetExpiringStock([FromBody] StockExpiringRequest request)
        {
            try
            {
                var items = await _stockExpiringService.GetExpiringStockAsync(request);
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving expiring stock");
                return StatusCode(500, "An error occurred while retrieving expiring stock");
            }
        }
    }
}
