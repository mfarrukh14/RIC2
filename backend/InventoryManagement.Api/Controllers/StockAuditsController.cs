using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StockAuditsController : BaseController
    {
        private readonly IStockAuditService _stockAuditService;

        public StockAuditsController(IUserSessionCacheService sessionCache, IStockAuditService stockAuditService)
            : base(sessionCache)
        {
            _stockAuditService = stockAuditService;
        }

        [HttpGet]
        public async Task<ActionResult<List<StockAuditListItem>>> GetAll([FromQuery] StockAuditListRequest request)
        {
            try
            {
                var audits = await _stockAuditService.GetAllAsync(request);
                return Ok(audits);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error retrieving stock audits", error = ex.Message });
            }
        }

        [HttpPost("search")]
        public async Task<ActionResult<PagedResult<StockAuditItem>>> SearchStockAuditItems([FromBody] StockAuditSearchRequest request)
        {
            try
            {
                var items = await _stockAuditService.SearchStockAuditItemsAsync(request);
                return Ok(items);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error searching stock audit items", error = ex.Message });
            }
        }

        [HttpPost]
        public async Task<ActionResult<StockAudit>> CreateStockAudit([FromBody] StockAuditRequest request)
        {
            try
            {
                var audit = await _stockAuditService.CreateStockAuditAsync(request);
                return Ok(audit);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error creating stock audit", error = ex.Message });
            }
        }
    }
}
