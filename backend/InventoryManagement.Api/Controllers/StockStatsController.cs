using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockStatsController : ControllerBase
    {
        private readonly IStockStatsService _stockStatsService;

        public StockStatsController(IStockStatsService stockStatsService)
        {
            _stockStatsService = stockStatsService;
        }

        [HttpPost("search")]
        public async Task<ActionResult<List<StockStatsItem>>> SearchStockStats([FromBody] StockStatsSearchRequest request)
        {
            try
            {
                var items = await _stockStatsService.SearchStockStatsAsync(request);
                return Ok(items);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error searching stock stats", error = ex.Message });
            }
        }
    }
}
