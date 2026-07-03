using Microsoft.AspNetCore.Mvc;
using InventoryManagement.API.Models;
using InventoryManagement.API.Services;
using InventoryManagement.Api.Services;
using InventoryManagement.Api.Controllers;

namespace InventoryManagement.API.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SurgicalItemGroupsController : BaseController
    {
        private readonly ISurgicalItemGroupService _service;
        private readonly ILogger<SurgicalItemGroupsController> _logger;

        public SurgicalItemGroupsController(
            IUserSessionCacheService sessionCache,
            ISurgicalItemGroupService service,
            ILogger<SurgicalItemGroupsController> logger)
            : base(sessionCache)
        {
            _service = service;
            _logger = logger;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<SurgicalItemGroup>>> GetAll()
        {
            try
            {
                var groups = await _service.GetAllAsync();
                return Ok(groups);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving surgical item groups");
                return StatusCode(500, "An error occurred while retrieving the data.");
            }
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<SurgicalItemGroup>> GetById(int id)
        {
            try
            {
                var group = await _service.GetByIdAsync(id);
                if (group == null)
                {
                    return NotFound($"Surgical item group with ID {id} not found.");
                }
                return Ok(group);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving surgical item group with id {Id}", id);
                return StatusCode(500, "An error occurred while retrieving the data.");
            }
        }

        [HttpPost]
        public async Task<ActionResult<int>> Create([FromBody] CreateSurgicalItemGroupRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var id = await _service.CreateAsync(request);
                return CreatedAtAction(nameof(GetById), new { id }, id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating surgical item group");
                return StatusCode(500, "An error occurred while creating the group.");
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> Update(int id, [FromBody] UpdateSurgicalItemGroupRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var success = await _service.UpdateAsync(id, request);
                if (!success)
                {
                    return NotFound($"Surgical item group with ID {id} not found.");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating surgical item group with id {Id}", id);
                return StatusCode(500, "An error occurred while updating the group.");
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> Delete(int id)
        {
            try
            {
                var success = await _service.DeleteAsync(id);
                if (!success)
                {
                    return NotFound($"Surgical item group with ID {id} not found.");
                }

                return NoContent();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting surgical item group with id {Id}", id);
                return StatusCode(500, "An error occurred while deleting the group.");
            }
        }

        [HttpGet("lookup")]
        public async Task<ActionResult<SurgicalItemGroupLookupData>> GetLookupData()
        {
            try
            {
                var lookupData = await _service.GetLookupDataAsync();
                return Ok(lookupData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error retrieving lookup data");
                return StatusCode(500, "An error occurred while retrieving lookup data.");
            }
        }
    }
}
