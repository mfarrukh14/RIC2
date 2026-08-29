using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace InventoryManagement.Api.Controllers
{
    // Debug-only utility for switching which database this running backend
    // instance talks to, without editing appsettings.json and restarting.
    // Global for the whole process (every connected user), not per-session -
    // every Service is registered Scoped and reads IConfiguration fresh per
    // request, so mutating the shared IConfiguration here takes effect on the
    // very next API call from anyone.
    //
    // Only a small server-side allowlist of known databases can be selected -
    // the frontend never supplies a raw connection string, so this can't be
    // used to point the app at an arbitrary external SQL server.
    [ApiController]
    [Route("api/[controller]")]
    public class SystemController : ControllerBase
    {
        private static readonly Dictionary<string, string> KnownDatabases = new(StringComparer.OrdinalIgnoreCase)
        {
            ["HMSMAIN_TF"] = "Server=10.10.10.103;Database=HMSMAIN_TF;User Id=sa;Password=RIC@12345;encrypt=false;TrustServerCertificate=True",
            ["IPPHMSLOCAL"] = "Server=10.10.10.103;Database=IPPHMSLOCAL;User Id=sa;Password=RIC@12345;encrypt=false;TrustServerCertificate=True"
        };

        private readonly IConfiguration _configuration;
        private readonly ILogger<SystemController> _logger;

        public SystemController(IConfiguration configuration, ILogger<SystemController> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        [HttpGet("database")]
        public ActionResult<object> GetCurrentDatabase()
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection") ?? string.Empty;
            var builder = new SqlConnectionStringBuilder(connectionString);

            var matchedName = KnownDatabases
                .FirstOrDefault(kv => string.Equals(kv.Value, connectionString, StringComparison.OrdinalIgnoreCase))
                .Key;

            return Ok(new
            {
                databaseName = builder.InitialCatalog,
                serverName = builder.DataSource,
                selection = matchedName, // null if the active connection isn't one of the known quick-switch targets
                availableDatabases = KnownDatabases.Keys
            });
        }

        private const string DefaultDatabase = "HMSMAIN_TF";

        [HttpPost("database")]
        public ActionResult<object> SwitchDatabase([FromBody] SwitchDatabaseRequest? request)
        {
            // No (or blank) "database" in the body means "use the default" rather
            // than an error - keeps this endpoint callable with an empty payload.
            var database = string.IsNullOrWhiteSpace(request?.Database) ? DefaultDatabase : request.Database;

            if (!KnownDatabases.TryGetValue(database, out var connectionString))
            {
                return BadRequest(new { message = $"Unknown database '{database}'. Valid options: {string.Join(", ", KnownDatabases.Keys)}" });
            }

            _configuration["ConnectionStrings:DefaultConnection"] = connectionString;
            _logger.LogWarning("Active database switched to {Database} via debug endpoint. This affects every connected user.", database);

            return Ok(new { message = $"Active database switched to {database}.", selection = database });
        }
    }

    public class SwitchDatabaseRequest
    {
        public string? Database { get; set; }
    }
}
