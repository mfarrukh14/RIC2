using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DemandRequestStatusesController : BaseController
    {
        private readonly IDemandRequestStatusService _service;
        private readonly ILogger<DemandRequestStatusesController> _logger;

        public DemandRequestStatusesController(IUserSessionCacheService sessionCache, IDemandRequestStatusService service, ILogger<DemandRequestStatusesController> logger)
            : base(sessionCache)
        {
            _service = service;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IReadOnlyList<DemandRequestStatusDto>>> GetAll()
        {
            try
            {
                return Ok(await _service.GetAllAsync());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand request statuses");
                return StatusCode(500, new { message = "An error occurred while retrieving demand request statuses." });
            }
        }

        [HttpGet("{id:int}")]
        public async Task<ActionResult<DemandRequestStatusDto>> GetById(int id)
        {
            try
            {
                var status = await _service.GetByIdAsync(id);
                if (status == null)
                {
                    return NotFound(new { message = $"Demand request status with ID {id} not found." });
                }

                return Ok(status);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving demand request status with ID {DemandRequestStatusId}", id);
                return StatusCode(500, new { message = "An error occurred while retrieving the demand request status." });
            }
        }

        [HttpPost]
        public async Task<ActionResult<DemandRequestStatusDto>> Create([FromBody] DemandRequestStatusUpsertRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var created = await _service.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id = created.DemandRequestStatusId }, created);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating demand request status");
                return StatusCode(500, new { message = "An error occurred while creating the demand request status." });
            }
        }

        [HttpPut("{id:int}")]
        public async Task<ActionResult<DemandRequestStatusDto>> Update(int id, [FromBody] DemandRequestStatusUpsertRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var updated = await _service.UpdateAsync(id, request);
                if (updated == null)
                {
                    return NotFound(new { message = $"Demand request status with ID {id} not found." });
                }

                return Ok(updated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating demand request status with ID {DemandRequestStatusId}", id);
                return StatusCode(500, new { message = "An error occurred while updating the demand request status." });
            }
        }
    }
}