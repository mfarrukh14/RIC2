using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StocksController : ControllerBase
    {
        private readonly IStockService _stockService;
        private readonly ILogger<StocksController> _logger;

        public StocksController(IStockService stockService, ILogger<StocksController> logger)
        {
            _stockService = stockService;
            _logger = logger;
        }

        [HttpPost("search")]
        public async Task<ActionResult<IEnumerable<Stock>>> Search([FromBody] StockSearchRequest request)
        {
            try
            {
                var stocks = await _stockService.SearchStocksAsync(request);
                return Ok(stocks);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching stocks");
                return StatusCode(500, "An error occurred while searching stocks");
            }
        }
    }
}
