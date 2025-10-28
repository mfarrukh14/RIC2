using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockFlowController : ControllerBase
    {
        private readonly IStockFlowService _stockFlowService;
        private readonly ILogger<StockFlowController> _logger;

        public StockFlowController(IStockFlowService stockFlowService, ILogger<StockFlowController> logger)
        {
            _stockFlowService = stockFlowService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetStockFlow([FromQuery] StockFlowSearchRequest request)
        {
            try
            {
                var stockFlows = await _stockFlowService.GetStockFlowAsync(request);
                return Ok(stockFlows);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock flow");
                return StatusCode(500, new { message = "An error occurred while retrieving stock flow data" });
            }
        }
    }
}
