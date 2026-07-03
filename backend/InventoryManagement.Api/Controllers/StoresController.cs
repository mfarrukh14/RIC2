using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StoresController : BaseController
    {
        private readonly IStoreService _storeService;

        public StoresController(IUserSessionCacheService sessionCache, IStoreService storeService)
            : base(sessionCache)
        {
            _storeService = storeService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var stores = await _storeService.GetAllAsync();
                return Ok(stores);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while retrieving stores.", error = ex.Message });
            }
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            try
            {
                var store = await _storeService.GetByIdAsync(id);
                if (store == null)
                {
                    return NotFound(new { message = $"Store with ID {id} not found." });
                }
                return Ok(store);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "An error occurred while retrieving the store.", error = ex.Message });
            }
        }
    }
}
