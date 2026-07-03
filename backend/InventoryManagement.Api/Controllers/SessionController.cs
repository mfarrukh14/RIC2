using InventoryManagement.Api.DTOs;
using InventoryManagement.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace InventoryManagement.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SessionController : ControllerBase
    {
        private readonly IUserSessionCacheService _sessionCache;
        private readonly ILogger<SessionController> _logger;

        public SessionController(IUserSessionCacheService sessionCache, ILogger<SessionController> logger)
        {
            _sessionCache = sessionCache;
            _logger = logger;
        }

        // POST /api/session
        // Body: { "userId": 3, "isLogin": 1 }  -> caches the user's data
        // Body: { "userId": 3, "isLogin": 0 }  -> clears the cached data
        [HttpPost]
        public async Task<IActionResult> SetLoginStatus([FromBody] SessionLoginRequest request)
        {
            if (request.UserId <= 0)
            {
                return BadRequest(new { message = "userId must be a positive integer" });
            }

            if (request.IsLogin != 0 && request.IsLogin != 1)
            {
                return BadRequest(new { message = "isLogin must be 0 (logout) or 1 (login)" });
            }

            if (request.IsLogin == 0)
            {
                _sessionCache.Logout(request.UserId);
                return Ok(new { message = "Logged out", userId = request.UserId });
            }

            try
            {
                var session = await _sessionCache.LoginAsync(request.UserId);
                if (session == null)
                {
                    return NotFound(new { message = $"No user found with UserId {request.UserId}" });
                }

                return Ok(session);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error logging in UserId {UserId}", request.UserId);
                return StatusCode(500, new { message = "An error occurred while logging in" });
            }
        }

        // GET /api/session/{userId} - reads back whatever is currently cached for that user.
        [HttpGet("{userId:int}")]
        public IActionResult GetSession(int userId)
        {
            if (!_sessionCache.TryGet(userId, out var session))
            {
                return NotFound(new { message = $"UserId {userId} is not logged in" });
            }

            return Ok(session);
        }
    }
}
