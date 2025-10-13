# RIC2 Management System - Backend

**Unified API for Inventory & Store Management**

## Quick Start

Run everything with ONE command:

```powershell
cd backend
dotnet run --project InventoryManagement.Api
```

**That's it!** The API runs on http://localhost:5000 and handles both Inventory AND Store Management.

### Development Mode (Auto-reload)

```powershell
cd backend
dotnet watch run --project InventoryManagement.Api
```

## Access Points

- **API**: http://localhost:5000
- **Swagger Documentation**: http://localhost:5000/swagger

## What This API Handles

This is a **unified API** that manages everything:

### ✅ Inventory Management
- Vendors, Manufacturers, Brands
- Items, Item Types, Categories, Units
- Inventory Receiving (GRN)
- Transfer & Return Inventory
- Purchase Summaries
- Sample Collection
- Surgical Groups
- Contingent Bills
- Asset Allocation

### ✅ Store Management
- Stock Operations
- Racks & Storage
- Sales Reports
- Space Allocation
- Store Allocations

**No separate services needed** - everything runs in one unified API!
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

4. Access Swagger UI: `http://localhost:5000/swagger`

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

4. Access application: `http://localhost:5173`

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