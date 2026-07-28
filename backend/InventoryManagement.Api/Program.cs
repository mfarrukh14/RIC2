using InventoryManagement.Api.Services;
using InventoryManagement.API.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

var preferredContentRoot = File.Exists(Path.Combine(AppContext.BaseDirectory, "appsettings.json"))
    ? AppContext.BaseDirectory
    : Directory.GetCurrentDirectory();

var builder = WebApplication.CreateBuilder(new WebApplicationOptions
{
    Args = args,
    ContentRootPath = preferredContentRoot
});
var corsOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();

var explicitUrls = builder.Configuration["ASPNETCORE_URLS"] ?? builder.Configuration["urls"];

if (string.IsNullOrWhiteSpace(explicitUrls))
{
    // Default to port 5100, but allow ASPNETCORE_URLS/urls to override it for local side-by-side runs.
    builder.WebHost.ConfigureKestrel(options =>
    {
        options.ListenAnyIP(5100);
    });
}

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add database initialization service
builder.Services.AddSingleton<IDatabaseInitializationService, DatabaseInitializationService>();

// In-memory cache of logged-in users; singleton so it's shared and thread-safe across concurrent requests.
builder.Services.AddSingleton<IUserSessionCacheService, UserSessionCacheService>();

// Add services (using stored procedures instead of Entity Framework)
builder.Services.AddScoped<IVendorService, VendorServiceSP>();
builder.Services.AddScoped<IManufacturerService, ManufacturerServiceSP>();
builder.Services.AddScoped<IBrandService, BrandServiceSP>();
builder.Services.AddScoped<IPackingService, PackingServiceSP>();
builder.Services.AddScoped<IItemTypeService, ItemTypeServiceSP>();
builder.Services.AddScoped<IItemUnitService, ItemUnitServiceSP>();
builder.Services.AddScoped<IAssetAllocationService, AssetAllocationService>();
builder.Services.AddScoped<ILocationService, LocationService>();
builder.Services.AddScoped<IItemService, ItemService>();
builder.Services.AddScoped<IInventoryService, InventoryService>();
builder.Services.AddScoped<IGRNService, GRNService>();
builder.Services.AddScoped<ITransferInventoryService, TransferInventoryService>();
builder.Services.AddScoped<IReturnInventoryService, ReturnInventoryService>();
builder.Services.AddScoped<IPurchaseSummaryService, PurchaseSummaryService>();
builder.Services.AddScoped<IPurchaseSummaryInvoiceService, PurchaseSummaryInvoiceService>();
builder.Services.AddScoped<ISampleCollectionConsumptionItemService, SampleCollectionConsumptionItemService>();
builder.Services.AddScoped<ISurgicalItemGroupService, SurgicalItemGroupService>();
builder.Services.AddScoped<IItemTypeSaleLevelService, ItemTypeSaleLevelService>();
builder.Services.AddScoped<IContingentBillService, ContingentBillService>();
builder.Services.AddScoped<IStockTypeService, StockTypeService>();
builder.Services.AddScoped<IStockTypeAssociationService, StockTypeAssociationService>();
builder.Services.AddScoped<IStockExpiringService, StockExpiringService>();
builder.Services.AddScoped<IRackService, RackService>();
builder.Services.AddScoped<IStockService, StockService>();
builder.Services.AddScoped<IStockAuditService, StockAuditService>();
builder.Services.AddScoped<IStockStatsService, StockStatsService>();
builder.Services.AddScoped<IStockAdjustmentService, StockAdjustmentService>();
builder.Services.AddScoped<IStockConsumptionService, StockConsumptionService>();
builder.Services.AddScoped<IStoreService, StoreService>();
builder.Services.AddScoped<IStockFlowService, StockFlowService>();
builder.Services.AddScoped<IExpiredStockService, ExpiredStockService>();
builder.Services.AddScoped<IStockValueItemService, StockValueItemService>();
builder.Services.AddScoped<IStockDetailRecordService, StockDetailRecordService>();
builder.Services.AddScoped<IStockBalanceReportService, StockBalanceReportService>();
builder.Services.AddScoped<ISaleSummaryDailyService, SaleSummaryDailyService>();
builder.Services.AddScoped<ISaleSummaryItemDiscountService, SaleSummaryItemDiscountService>();
builder.Services.AddScoped<ISaleSummaryStockNoDiscountService, SaleSummaryStockNoDiscountService>();
builder.Services.AddScoped<IRackDrawerService, RackDrawerService>();
builder.Services.AddScoped<IRackColumnService, RackColumnService>();
builder.Services.AddScoped<IRackRowService, RackRowService>();
builder.Services.AddScoped<ISpaceAllocationService, SpaceAllocationService>();
builder.Services.AddScoped<IStoreAllocationToUserService, StoreAllocationToUserService>();
builder.Services.AddScoped<IStockWithExpiryService, StockWithExpiryService>();
builder.Services.AddScoped<IBranchService, BranchService>();
builder.Services.AddScoped<IDemandRequestService, DemandRequestService>();
builder.Services.AddScoped<IDemandRequestStatusService, DemandRequestStatusService>();
builder.Services.AddScoped<IDemandWiseValueService, DemandWiseValueService>();
builder.Services.AddScoped<IPurchaseOrderService, PurchaseOrderService>();
builder.Services.AddScoped<IPurchaseOrderTypeService, PurchaseOrderTypeService>();
builder.Services.AddScoped<IPurchaseOrderStatusService, PurchaseOrderStatusService>();
builder.Services.AddScoped<IEstimatedPurchaseOrderService, EstimatedPurchaseOrderService>();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        if (corsOrigins is { Length: > 0 })
        {
            policy.WithOrigins(corsOrigins)
                  .AllowAnyMethod()
                  .AllowAnyHeader();
            return;
        }

        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Initialize database on startup unless explicitly skipped for local recovery runs.
var databaseInitializationEnabled = builder.Configuration.GetValue("DatabaseInitialization:Enabled", builder.Environment.IsDevelopment());
var skipDatabaseInitialization = string.Equals(
    Environment.GetEnvironmentVariable("SKIP_DB_INIT"),
    "1",
    StringComparison.OrdinalIgnoreCase);

if (databaseInitializationEnabled && !skipDatabaseInitialization)
{
    using var scope = app.Services.CreateScope();
    var dbInitService = scope.ServiceProvider.GetRequiredService<IDatabaseInitializationService>();
    await dbInitService.InitializeDatabaseAsync();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Enable CORS - must come before UseAuthorization
app.UseCors("AllowAll");

app.Use(async (context, next) =>
{
    try
    {
        await next();
    }
    catch (Exception exception)
    {
        if (context.Response.HasStarted)
        {
            throw;
        }

        var logger = context.RequestServices.GetRequiredService<ILoggerFactory>()
            .CreateLogger("UnhandledException");

        logger.LogError(
            exception,
            "Unhandled exception while processing {Method} {Path}",
            context.Request.Method,
            context.Request.Path);

        var (statusCode, title, detail) = exception switch
        {
            SqlException => (
                StatusCodes.Status503ServiceUnavailable,
                "Database connectivity failure",
                "The API could not reach its SQL Server dependency from this host."),
            _ => (
                StatusCodes.Status500InternalServerError,
                "Unhandled server error",
                "The request failed before the API could produce a response.")
        };

        context.Response.Clear();
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/problem+json";

        var problem = new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Detail = detail,
            Instance = context.Request.Path
        };

        problem.Extensions["traceId"] = context.TraceIdentifier;

        await context.Response.WriteAsJsonAsync(problem);
    }
});

app.UseAuthorization();

app.MapControllers();

app.Run();