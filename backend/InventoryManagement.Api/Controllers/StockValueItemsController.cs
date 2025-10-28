using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockValueItemsController : ControllerBase
    {
        private readonly IStockValueItemService _stockValueItemService;
        private readonly ILogger<StockValueItemsController> _logger;

        public StockValueItemsController(IStockValueItemService stockValueItemService, ILogger<StockValueItemsController> logger)
        {
            _stockValueItemService = stockValueItemService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetStockValueItems([FromQuery] StockValueSearchRequest request)
        {
            try
            {
                var items = await _stockValueItemService.GetStockValueItemsAsync(request);
                return Ok(items);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock value items");
                return StatusCode(500, new { message = "An error occurred while retrieving stock value items" });
            }
        }

        [HttpGet("report")]
        public async Task<IActionResult> GetGRNReport([FromQuery] StockValueDetailRequest request)
        {
            try
            {
                var report = await _stockValueItemService.GetGRNReportByBatchAsync(request);
                return Ok(report);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving GRN report");
                return StatusCode(500, new { message = "An error occurred while retrieving the GRN report" });
            }
        }
    }
}
