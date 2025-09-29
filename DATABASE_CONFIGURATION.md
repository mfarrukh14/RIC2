# Database Configuration and Storage Details

## Database Storage Location

### Physical Database Files
The database files are stored in your user profile directory:

```
Location: C:\Users\Pc\
Files:
- InventoryManagementDB_v2.mdf     (8.0 MB) - Primary database file
- InventoryManagementDB_v2_log.ldf (8.0 MB) - Transaction log file
```

### SQL Server Instance
- **Database Engine**: SQL Server LocalDB
- **Instance Name**: MSSQLLocalDB  
- **Version**: 15.0.4382.1
- **Owner**: DESKTOP-868CQOS\Pc
- **State**: Running
- **Pipe Name**: np:\\.\pipe\LOCALDB#2005C521\tsql\query

## Connection Strings

### Production Environment (`appsettings.json`):
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=InventoryManagementDB_v2;Trusted_Connection=true;TrustServerCertificate=true;"
  }
}
```

### Development Environment (`appsettings.Development.json`):
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=InventoryManagementDB_Dev_v2;Trusted_Connection=true;TrustServerCertificate=true;"
  }
}
```

## Database Schema

### Tables

#### Vendors Table
The main table storing vendor information with the following columns:

**Primary Key:**
- Id (int, Identity, Auto-increment)

**Basic Information:**
- Name (nvarchar(100), Required, Unique Index)
- Code (nvarchar(20), Unique Index)
- Type (nvarchar(50))
- Description (nvarchar(500))

**Address Information:**
- Address (nvarchar(200))
- City (nvarchar(50))
- State (nvarchar(50))
- PostalCode (nvarchar(20))
- Country (nvarchar(50))

**Contact Information:**
- ContactPersonName1 (nvarchar(100))
- ContactPersonType1 (nvarchar(50))
- Email1 (nvarchar(100), Unique Index)
- Phone1 (nvarchar(20))
- ContactPersonName2 (nvarchar(100))
- ContactPersonType2 (nvarchar(50))
- Email2 (nvarchar(100))
- Phone2 (nvarchar(20))

**Account Details:**
- VendorAccountNumber (nvarchar(50))
- TaxIdNumber (nvarchar(50))

**Bank Details:**
- BankName (nvarchar(100))
- AccountNumber (nvarchar(50))
- RoutingNumber (nvarchar(20))
- SwiftCode (nvarchar(20))
- IbanNumber (nvarchar(50))

**Additional Information:**
- CreditLimit (nvarchar(20))
- PaymentTerms (nvarchar(50))

**System Fields:**
- IsActive (bit, Default: true)
- CreatedAt (datetime2, Default: GETUTCDATE())
- UpdatedAt (datetime2, Nullable)

### Indexes
1. **Unique Index on Name**: Ensures vendor names are unique
2. **Unique Index on Code**: Ensures vendor codes are unique (when not null)
3. **Unique Index on Email1**: Ensures primary emails are unique (when not null)

### Seed Data
The database is automatically populated with 2 sample vendors:
1. **Tech Supplies Co.** (Code: TECH001)
2. **Office Essentials Ltd.** (Code: OFF001)

## Entity Framework Configuration

### Database Creation Strategy
- **Method**: Code First with `EnsureCreated()`
- **Location**: Program.cs startup
- **Behavior**: Creates database and tables automatically if they don't exist

### ORM Framework
- **Framework**: Entity Framework Core 9.0.0
- **Provider**: Microsoft.EntityFrameworkCore.SqlServer 9.0.0
- **Context**: InventoryContext
- **Models**: Vendor

## API Configuration

### Base URL
- **Backend**: http://localhost:5000
- **API Routes**: http://localhost:5000/api/vendors

### CORS Policy
- **Policy Name**: AllowAll
- **Allowed Origins**: All (*)
- **Allowed Methods**: All
- **Allowed Headers**: All

## Database Management Commands

### View LocalDB Instances
```bash
sqllocaldb info
```

### Get Instance Details
```bash
sqllocaldb info MSSQLLocalDB
```

### Connect via SQL Server Management Studio
- **Server Name**: (localdb)\MSSQLLocalDB
- **Database**: InventoryManagementDB_v2
- **Authentication**: Windows Authentication

### Backup Database Files Location
The .mdf and .ldf files can be copied from:
```
C:\Users\Pc\InventoryManagementDB_v2.mdf
C:\Users\Pc\InventoryManagementDB_v2_log.ldf
```

### Reset Database
To completely reset the database:
1. Stop the API application
2. Delete the database files from C:\Users\Pc\
3. Restart the API - it will recreate the database with seed data

## Security Considerations

### Current Security Level
- **Authentication**: None (development only)
- **Authorization**: None
- **Connection**: Windows Integrated Security
- **SSL**: TrustServerCertificate=true (development only)

### Production Recommendations
1. Implement proper authentication/authorization
2. Use dedicated SQL Server instance
3. Configure proper SSL certificates
4. Implement connection string encryption
5. Set up database backups
6. Configure proper CORS origins
7. Add input validation and SQL injection protection

## Performance Considerations

### Current Configuration
- **Connection Pooling**: Enabled by default
- **Query Logging**: Enabled in development
- **Database Size**: Small (< 16 MB total)

### Optimization Opportunities
1. Add database indexes for frequently queried fields
2. Implement pagination for large datasets
3. Add caching layer (Redis/Memory)
4. Optimize Entity Framework queries
5. Consider database partitioning for large tables