# RIC2 Management System - Backend

**Unified API for Inventory & Store Management with Automatic Database Setup**

## 🚀 Quick Start

Run everything with ONE command:

```powershell
cd backend\InventoryManagement.Api
dotnet run
```

**That's it!** On first run, the API will automatically:
- ✅ Create database if it doesn't exist
- ✅ Create all 30+ tables
- ✅ Apply all schema modifications
- ✅ Install 60+ stored procedures
- ✅ Start serving at http://10.10.10.67:5100

**First run:** ~15-20 seconds  
**Subsequent runs:** ~2-3 seconds

### Development Mode (Auto-reload)

```powershell
cd backend\InventoryManagement.Api
dotnet watch run
```

## 📚 Complete Documentation

See **[Main README](../README.md)** for:
- Complete setup instructions
- Project structure
- API endpoints
- Troubleshooting guide
- Testing procedures

## 🔧 Quick Configuration

### Using Different SQL Server

Edit `InventoryManagement.Api/appsettings.json`:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_SERVER;Database=InventoryManagementDB_SP;Trusted_Connection=true;MultipleActiveResultSets=true"
  }
}
```

Then just run `dotnet run` - database setup is automatic!

## 🌐 Access Points

- **API**: http://10.10.10.67:5100
- **Swagger Documentation**: http://10.10.10.67:5100/swagger

## 🏗️ Architecture

### Automatic Database Initialization

The `DatabaseInitializationService` handles complete database setup:

1. **Database Creation**: Checks and creates database if needed
2. **Core Tables**: Manufacturers, Brands, Packings, Item Types, etc.
3. **Feature Tables**: Stores, Items, Inventories, Racks, Stocks, etc.
4. **Schema Modifications**: Applies all ALTER scripts
5. **Dependencies**: GRN and Transfer tables (depend on Stores/StockTypes)
6. **Stored Procedures**: Installs all 60+ procedures

### Service Layer Pattern

```
Controllers → Services → Stored Procedures → Database
```

All database operations use stored procedures (no Entity Framework).

## 📦 What This API Manages

### ✅ Inventory Management
- Vendors, Manufacturers, Brands, Packings
- Items, Item Types, Item Units, Item Categories
- Inventory Operations (GRN, Transfer, Return)
- Purchase Summaries & Invoices
- Asset Allocation
- Sample Collection & Surgical Items
- Contingent Bills

### ✅ Store Management
- Branches & Store Hierarchy
- Stock Operations & Tracking
- Stock Types & Associations
- Racks & Space Allocation
- Stock Audits & Adjustments
- Stock Consumption
- Store Allocation to Users

### ✅ Reports & Analytics
- Stock with Least Expiry (MPL)
- Expired Stock Reports
- Stock Flow & Balance Reports
- Stock Value Reports
- Sales Summary Reports

## 🔍 Key Features

- **Automatic Setup**: No manual SQL script execution needed
- **Idempotent**: Safe to run multiple times
- **CORS Enabled**: Works with frontend on different port
- **Swagger**: Interactive API documentation
- **Logging**: Comprehensive initialization logging
- **Error Handling**: Graceful handling of existing objects

## 📁 Database Scripts Location

```
backend/
├── Database/
│   ├── CreateDatabase.sql              # Database creation
│   ├── Create*.sql                     # Root-level table scripts
│   ├── Tables/                         # Feature tables
│   │   ├── Create*.sql                 # Table creation scripts
│   │   └── Alter*.sql                  # Schema modification scripts
│   └── StoredProcedures/               # All stored procedures
│       └── *.sql                       # 60+ procedure files
```

All scripts are executed automatically on first run!

## 🛠️ Technology Stack

- **.NET 9**: Latest framework
- **ASP.NET Core Web API**: REST API
- **Microsoft.Data.SqlClient**: Direct SQL access
- **SQL Server LocalDB**: Default database
- **Stored Procedures**: All data operations

## 🧪 Testing

### Quick Health Check
```powershell
# Check if API is running
curl http://10.10.10.67:5100/api/Branch

# Or visit Swagger
start http://10.10.10.67:5100/swagger
```

### Verify Database
```powershell
sqlcmd -S "(localdb)\MSSQLLocalDB" -d InventoryManagementDB_SP -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"
```

Should show 30+ tables.

## 🔄 Reset Database

If you need to start fresh:
```powershell
# Stop the API, then:
sqlcmd -S "(localdb)\MSSQLLocalDB" -Q "DROP DATABASE InventoryManagementDB_SP"

# Run API again - database will be recreated
dotnet run
```

## 📝 Adding New Features

### To Add a New Table:
1. Create `CreateYourTable.sql` in `Database/Tables/`
2. Add to `DatabaseInitializationService.cs` table script list
3. Run `dotnet run` - table is created automatically

### To Add a New Stored Procedure:
1. Create `YourProcedure.sql` in `Database/StoredProcedures/`
2. Run `dotnet run` - procedure is installed automatically

No manual SQL execution needed!
├── StoreManagement.Api/              # Store Management API (Future)
│   ├── Controllers/
│   ├── Models/
│   ├── Services/
│   └── Program.cs
├── Database/                         # Database scripts
│   ├── Tables/                       # Table creation scripts
│   └── StoredProcedures/             # All stored procedures
├── start.ps1                         # Quick startup script
└── RUN_INSTRUCTIONS.md               # Detailed run instructions

frontend/
├── src/
│   ├── components/                   # React components (Sidebar, etc.)
│   ├── pages/                        # Page components
│   └── services/                     # API service layer
├── public/                           # Static assets
└── package.json                      # Dependencies and scripts
```

## Quick Start

### Easy Method (Using Startup Script)
```powershell
cd c:\Users\Pc\Desktop\MyArchive\code\ric2\backend
.\start.ps1
```
Then select option 1 or 2 from the menu.

### Manual Method
```powershell
# Navigate to backend folder (NOT into InventoryManagement.Api)
cd c:\Users\Pc\Desktop\MyArchive\code\ric2\backend

# Run the API
dotnet run --project InventoryManagement.Api/InventoryManagement.Api.csproj
```

### Development with Auto-Reload
```powershell
cd c:\Users\Pc\Desktop\MyArchive\code\ric2\backend
dotnet watch run --project InventoryManagement.Api/InventoryManagement.Api.csproj
```

## Features

### Inventory Management Module
- ✅ **Vendors Management**: Complete CRUD operations
- ✅ **Manufacturers Management**: Complete CRUD operations
- ✅ **Brands Management**: Complete CRUD operations
- ✅ **Relational Data**: Countries, States, Cities, Branches integration
- ✅ **Stored Procedures**: All database operations via stored procedures
- ✅ **RESTful API**: Well-documented endpoints with Swagger
- ✅ **Data Validation**: Input validation and error handling

### Database Schema
- **Countries**: Master data for countries
- **StateOrProvinces**: States/provinces linked to countries
- **Cities**: Cities linked to states/provinces
- **Branches**: Business branches
- **TaxPayerCategories**: Tax classification
- **AccountCOAs**: Chart of accounts
- **Vendors**: Vendor information with contact details
- **Manufacturers**: Manufacturer information with registered owner details
- **Brands**: Brand information linked to branches

## Getting Started

### Prerequisites
- .NET 9 SDK
- SQL Server LocalDB
- Node.js (for frontend)

### Backend Setup
1. Navigate to backend directory:
   ```bash
   cd backend
   ```

2. Create the database:
   ```bash
   sqlcmd -S "(localdb)\MSSQLLocalDB" -i "Database\CreateDatabase.sql"
   ```

3. Run the application:
   ```bash
   cd InventoryManagement.Api
   dotnet run
   ```

4. Access Swagger UI: `http://10.10.10.67:5100/swagger`

### Frontend Setup
1. Navigate to frontend directory:
   ```bash
   cd frontend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start development server:
   ```bash
   npm run dev
   ```

4. Access application: `http://10.10.10.67:5173`

## API Endpoints

### Vendors
- `GET /api/vendors` - Get all vendors
- `GET /api/vendors/{id}` - Get vendor by ID
- `POST /api/vendors` - Create new vendor
- `PUT /api/vendors/{id}` - Update vendor
- `DELETE /api/vendors/{id}` - Delete vendor (soft delete)

### Manufacturers
- `GET /api/manufacturers` - Get all manufacturers
- `GET /api/manufacturers/{id}` - Get manufacturer by ID
- `POST /api/manufacturers` - Create new manufacturer
- `PUT /api/manufacturers/{id}` - Update manufacturer
- `DELETE /api/manufacturers/{id}` - Delete manufacturer (soft delete)

### Brands
- `GET /api/brands` - Get all brands
- `GET /api/brands/{id}` - Get brand by ID
- `POST /api/brands` - Create new brand
- `PUT /api/brands/{id}` - Update brand
- `DELETE /api/brands/{id}` - Delete brand (soft delete)

## Database Connection

The application uses SQL Server LocalDB with the following connection string:
```
Server=(localdb)\\MSSQLLocalDB;Database=InventoryManagementDB_SP;Trusted_Connection=true;TrustServerCertificate=true;
```

## Technology Stack

### Backend
- **.NET 9**: Latest .NET framework
- **ASP.NET Core Web API**: RESTful API development
- **Microsoft.Data.SqlClient**: Database connectivity
- **SQL Server LocalDB**: Development database
- **Swagger/OpenAPI**: API documentation

### Frontend
- **React 18**: Latest React version
- **Vite**: Modern build tool
- **JavaScript/JSX**: Development language

## Best Practices Implemented

- **Clean Architecture**: Separation of concerns
- **Stored Procedures**: Enhanced security and performance
- **Input Validation**: Data integrity and security
- **Error Handling**: Comprehensive exception management
- **CORS Configuration**: Cross-origin resource sharing
- **Swagger Documentation**: API documentation and testing
- **Soft Deletes**: Data preservation with IsActive flags
- **Audit Trails**: CreatedBy, CreatedOn, ModifiedBy, ModifiedOn tracking

## Security Features

- **SQL Injection Prevention**: Parameterized stored procedures
- **Input Validation**: Server-side validation
- **CORS Policy**: Controlled cross-origin access
- **Error Handling**: Secure error responses

## Future Enhancements

- [ ] Authentication and Authorization (JWT)
- [ ] Role-based access control
- [ ] Advanced inventory tracking
- [ ] Reporting and analytics
- [ ] Email notifications
- [ ] File upload capabilities
- [ ] Audit logging
- [ ] Performance optimization
- [ ] Unit and integration testing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.