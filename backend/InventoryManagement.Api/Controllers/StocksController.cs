using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StocksController : BaseController
    {
        private readonly IStockService _stockService;
        private readonly ILogger<StocksController> _logger;

        public StocksController(IUserSessionCacheService sessionCache, IStockService stockService, ILogger<StocksController> logger)
            : base(sessionCache)
        {
            _stockService = stockService;
            _logger = logger;
        }

        [HttpPost("search")]
        public async Task<ActionResult<PagedResult<Stock>>> Search([FromBody] StockSearchRequest request)
        {
            try
            {
                // A non-admin explicitly picking a store outside their allocation gets an
                // empty result, not another store's data - never trust the client's StoreId.
                if (!IsAdmin && request.StoreId.HasValue && !IsStoreAllowed(request.StoreId))
                {
                    return Ok(new PagedResult<Stock> { Items = new List<Stock>(), TotalCount = 0, PageNumber = request.PageNumber, PageSize = request.PageSize });
                }

                var stocks = await _stockService.SearchStocksAsync(request, IsAdmin, AllowedStoreIds);
                return Ok(stocks);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error searching stocks");
                return StatusCode(500, "An error occurred while searching stocks");
            }
        }

        [HttpPut("{id:int}/minimum-panic-level")]
        public async Task<ActionResult> UpdateMinimumPanicLevel(int id, [FromBody] UpdateMinimumPanicLevelRequest request)
        {
            try
            {
                var updated = await _stockService.UpdateMinimumPanicLevelAsync(id, request.MinimumPanicLevel);
                if (!updated)
                {
                    return NotFound(new { message = $"Stock record with ID {id} not found" });
                }
                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating minimum panic level for stock {Id}", id);
                return StatusCode(500, "An error occurred while updating the minimum panic level.");
            }
        }

        [HttpGet("quantities-by-store/{storeId:int}")]
        public async Task<ActionResult<StoreItemQuantities>> GetQuantitiesByStore(int storeId)
        {
            try
            {
                if (!IsStoreAllowed(storeId))
                {
                    return Ok(new StoreItemQuantities());
                }

                var quantities = await _stockService.GetQuantitiesByStoreAsync(storeId);
                return Ok(quantities);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving stock quantities for store {StoreId}", storeId);
                return StatusCode(500, "An error occurred while retrieving stock quantities.");
            }
        }
    }
}
