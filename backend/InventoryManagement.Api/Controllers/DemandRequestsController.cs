using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DemandRequestsController : BaseController
    {
        private readonly IDemandRequestService _demandRequestService;
        private readonly ILogger<DemandRequestsController> _logger;

        public DemandRequestsController(IUserSessionCacheService sessionCache, IDemandRequestService demandRequestService, ILogger<DemandRequestsController> logger)
            : base(sessionCache)
        {
            _demandRequestService = demandRequestService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<PagedResult<DemandRequestSummary>>> GetAll([FromQuery] DemandRequestFilter filter)
        {
            try
            {
                var results = await _demandRequestService.GetAllAsync(filter);
                return Ok(results);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand requests");
                return StatusCode(500, new { message = "An error occurred while retrieving demand requests." });
            }
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<DemandRequestDetails>> GetById(int id)
        {
            try
            {
                var demandRequest = await _demandRequestService.GetByIdAsync(id);
                if (demandRequest == null)
                {
                    return NotFound(new { message = $"Demand request with ID {id} not found." });
                }

                return Ok(demandRequest);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand request with ID {DemandRequestId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the demand request." });
            }
        }

        [HttpGet("{id:int}/lifecycle")]
        public async Task<ActionResult<IReadOnlyList<DemandRequestLifeCycleEntry>>> GetLifeCycle(int id)
        {
            try
            {
                var demandRequest = await _demandRequestService.GetByIdAsync(id);
                if (demandRequest == null)
                {
                    return NotFound(new { message = $"Demand request with ID {id} not found." });
                }

                var entries = await _demandRequestService.GetLifeCycleAsync(id);
                return Ok(entries);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand life cycle for ID {DemandRequestId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the demand life cycle." });
            }
        }

        [HttpGet("{id:int}/itemlogs")]
        public async Task<ActionResult<IReadOnlyList<DemandRequestItemLogEntry>>> GetItemLogs(int id)
        {
            try
            {
                var demandRequest = await _demandRequestService.GetByIdAsync(id);
                if (demandRequest == null)
                {
                    return NotFound(new { message = $"Demand request with ID {id} not found." });
                }

                var entries = await _demandRequestService.GetItemLogsAsync(id);
                return Ok(entries);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand request item logs for ID {DemandRequestId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the demand request item logs." });
            }
        }

        [HttpPost]
        public async Task<ActionResult<DemandRequestDetails>> Create([FromBody] DemandRequestCreateRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                if (request.DateTo < request.DateFrom)
                {
                    return BadRequest(new { message = "DateTo must be greater than or equal to DateFrom." });
                }

                if (request.Items == null || request.Items.Count == 0)
                {
                    return BadRequest(new { message = "At least one demand item is required." });
                }

                var created = await _demandRequestService.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = created.DemandRequestId }, created);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating demand request");
                return StatusCode(500, new { message = "An error occurred while creating the demand request." });
            }
        }

        [HttpPost("{id:int}/receive")]
        public async Task<ActionResult<DemandRequestDetails>> Receive(int id, [FromBody] DemandRequestReceiveRequest request)
        {
            try
            {
                var updated = await _demandRequestService.ReceiveAsync(id, request);
                if (updated == null)
                {
                    return NotFound(new { message = $"Demand request with ID {id} not found." });
                }

                return Ok(updated);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error receiving demand request with ID {DemandRequestId}", id);
                return StatusCode(500, new { message = "An error occurred while receiving the demand request." });
            }
        }

        [HttpPut("{id:int}")]
        public async Task<ActionResult<DemandRequestDetails>> Update(int id, [FromBody] DemandRequestUpdateRequest request)
        {
            try
            {
                var updated = await _demandRequestService.UpdateAsync(id, request);
                if (updated == null)
                {
                    return NotFound(new { message = $"Demand request with ID {id} not found." });
                }

                return Ok(updated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating demand request with ID {DemandRequestId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the demand request." });
            }
        }

        [HttpPost("{id:int}/approve")]
        public async Task<ActionResult<DemandRequestDetails>> Approve(int id, [FromBody] DemandRequestUpdateRequest request)
        {
            try
            {
                var updated = await _demandRequestService.ApproveAsync(id, request);
                if (updated == null)
                {
                    return NotFound(new { message = $"Demand request with ID {id} not found." });
                }

                return Ok(updated);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error approving demand request with ID {DemandRequestId}", id);
                return StatusCode(500, new { message = "An error occurred while approving the demand request." });
            }
        }

        [HttpPost("{id:int}/dispatch")]
        public async Task<ActionResult<DemandRequestDetails>> Dispatch(int id, [FromBody] DemandRequestDispatchRequest request)
        {
            try
            {
                var updated = await _demandRequestService.DispatchAsync(id, request);
                if (updated == null)
                {
                    return NotFound(new { message = $"Demand request with ID {id} not found." });
                }

                return Ok(updated);
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error dispatching demand request with ID {DemandRequestId}", id);
                return StatusCode(500, new { message = "An error occurred while dispatching the demand request." });
            }
        }

        [HttpPost("{id:int}/reject")]
        public async Task<ActionResult<DemandRequestDetails>> Reject(int id, [FromBody] DemandRequestRejectRequest request)
        {
            try
            {
                var updated = await _demandRequestService.RejectAsync(id, request);
                if (updated == null)
                {
                    return NotFound(new { message = $"Demand request with ID {id} not found." });
                }

                return Ok(updated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error rejecting demand request with ID {DemandRequestId}", id);
                return StatusCode(500, new { message = "An error occurred while rejecting the demand request." });
            }
        }
    }
}