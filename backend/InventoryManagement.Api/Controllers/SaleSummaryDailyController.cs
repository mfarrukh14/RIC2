using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Models;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SaleSummaryDailyController : BaseController
    {
        private readonly ISaleSummaryDailyService _saleSummaryDailyService;
        private readonly ILogger<SaleSummaryDailyController> _logger;

        public SaleSummaryDailyController(IUserSessionCacheService sessionCache, ISaleSummaryDailyService saleSummaryDailyService, ILogger<SaleSummaryDailyController> logger)
            : base(sessionCache)
        {
            _saleSummaryDailyService = saleSummaryDailyService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> GetSaleSummary([FromQuery] SaleSummarySearchRequest request)
        {
            try
            {
                var summaries = await _saleSummaryDailyService.GetSaleSummaryAsync(request);
                return Ok(summaries);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sale summary");
                return StatusCode(500, new { message = "An error occurred while retrieving sale summary" });
            }
        }

        [HttpGet("summary")]
        public async Task<IActionResult> GetSaleSummarySummary([FromQuery] SaleSummarySearchRequest request)
        {
            try
            {
                var summary = await _saleSummaryDailyService.GetSaleSummarySummaryAsync(request);
                return Ok(summary);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving sale summary totals");
                return StatusCode(500, new { message = "An error occurred while retrieving sale summary totals" });
            }
        }
    }
}
