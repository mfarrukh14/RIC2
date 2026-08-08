using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PurchaseRequisitionsController : BaseController
    {
        private readonly IPurchaseRequisitionService _purchaseRequisitionService;
        private readonly ILogger<PurchaseRequisitionsController> _logger;

        public PurchaseRequisitionsController(IUserSessionCacheService sessionCache, IPurchaseRequisitionService purchaseRequisitionService, ILogger<PurchaseRequisitionsController> logger)
            : base(sessionCache)
        {
            _purchaseRequisitionService = purchaseRequisitionService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<PurchaseRequisitionListItem>>> GetAll([FromQuery] PurchaseRequisitionFilter filter)
        {
            try
            {
                var results = await _purchaseRequisitionService.GetAllAsync(filter);
                return Ok(results);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase requisitions");
                return StatusCode(500, new { message = "An error occurred while retrieving purchase requisitions." });
            }
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<PurchaseRequisitionDetails>> GetById(int id)
        {
            try
            {
                var pr = await _purchaseRequisitionService.GetByIdAsync(id);
                if (pr == null)
                {
                    return NotFound(new { message = $"Purchase requisition with ID {id} not found." });
                }
                return Ok(pr);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase requisition {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the purchase requisition." });
            }
        }

        [HttpGet("{id:int}/lifecycle")]
        public async Task<ActionResult<IReadOnlyList<PurchaseRequisitionLifeCycleEntry>>> GetLifeCycle(int id)
        {
            try
            {
                var entries = await _purchaseRequisitionService.GetLifeCycleAsync(id);
                return Ok(entries);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving purchase requisition life cycle {Id}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the purchase requisition life cycle." });
            }
        }

        [HttpPost]
        public async Task<ActionResult<PurchaseRequisitionDetails>> Create([FromBody] PurchaseRequisitionCreateRequest request)
        {
            try
            {
                if (request.Items == null || request.Items.Count == 0)
                {
                    return BadRequest(new { message = "At least one item is required." });
                }

                if (request.BranchId == 0)
                {
                    request.BranchId = BranchId ?? 1;
                }

                var created = await _purchaseRequisitionService.CreateAsync(request, UserId);
                return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating purchase requisition");
                return StatusCode(500, new { message = "An error occurred while creating the purchase requisition." });
            }
        }

        [HttpPost("{id:int}/forward")]
        public async Task<ActionResult<PurchaseRequisitionDetails>> Forward(int id, [FromBody] PurchaseRequisitionForwardRequest request)
        {
            try
            {
                var updated = await _purchaseRequisitionService.ForwardAsync(id, request, UserId);
                if (updated == null)
                {
                    return NotFound(new { message = $"Purchase requisition with ID {id} not found." });
                }
                return Ok(updated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error forwarding purchase requisition {Id}", id);
                return StatusCode(500, new { message = "An error occurred while forwarding the purchase requisition." });
            }
        }

        [HttpPost("{id:int}/status")]
        public async Task<ActionResult<PurchaseRequisitionDetails>> ChangeStatus(int id, [FromBody] PurchaseRequisitionStatusChangeRequest request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Status))
                {
                    return BadRequest(new { message = "Status is required." });
                }

                var updated = await _purchaseRequisitionService.ChangeStatusAsync(id, request, UserId);
                if (updated == null)
                {
                    return NotFound(new { message = $"Purchase requisition with ID {id} not found." });
                }
                return Ok(updated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error changing status of purchase requisition {Id}", id);
                return StatusCode(500, new { message = "An error occurred while changing the purchase requisition status." });
            }
        }

        [HttpGet("lookups/financial-years")]
        public async Task<ActionResult<IReadOnlyList<PurchaseRequisitionLookupItem>>> GetFinancialYears()
        {
            try
            {
                var results = await _purchaseRequisitionService.GetFinancialYearsAsync();
                return Ok(results);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving financial years");
                return StatusCode(500, new { message = "An error occurred while retrieving financial years." });
            }
        }

        [HttpGet("lookups/budget-heads")]
        public async Task<ActionResult<IReadOnlyList<PurchaseRequisitionLookupItem>>> GetBudgetHeads()
        {
            try
            {
                var results = await _purchaseRequisitionService.GetBudgetHeadsAsync();
                return Ok(results);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving budget heads");
                return StatusCode(500, new { message = "An error occurred while retrieving budget heads." });
            }
        }
    }
}
