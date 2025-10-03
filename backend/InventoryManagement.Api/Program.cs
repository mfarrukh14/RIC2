using InventoryManagement.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add services (using stored procedures instead of Entity Framework)
builder.Services.AddScoped<IVendorService, VendorServiceSP>();
builder.Services.AddScoped<IManufacturerService, ManufacturerServiceSP>();
builder.Services.AddScoped<IBrandService, BrandServiceSP>();
builder.Services.AddScoped<IPackingService, PackingServiceSP>();
builder.Services.AddScoped<IItemTypeService, ItemTypeServiceSP>();
builder.Services.AddScoped<IItemUnitService, ItemUnitServiceSP>();
builder.Services.AddScoped<IAssetAllocationService, AssetAllocationService>();
builder.Services.AddScoped<IItemService, ItemService>();
builder.Services.AddScoped<IInventoryService, InventoryService>();
builder.Services.AddScoped<IGRNService, GRNService>();
builder.Services.AddScoped<ITransferInventoryService, TransferInventoryService>();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("AllowAll");

app.UseAuthorization();

app.MapControllers();

app.Run();