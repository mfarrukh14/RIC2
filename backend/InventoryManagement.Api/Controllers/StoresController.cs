using Microsoft.AspNetCore.Mvc;
using InventoryManagement.Api.Models;
using InventoryManagement.Api.Services;

namespace InventoryManagement.Api.Controllers
{
    // Duplicate of StoreController (singular route "api/Store") - no frontend
    // caller currently uses this plural "api/Stores" route, but scoped anyway
    // so it can't become an unscoped back door to every store's data.
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
                var scoped = StoreScopeHelper.FilterStores(stores, IsAdmin, AllowedStoreIds, s => s.Id);
                return Ok(scoped);
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
