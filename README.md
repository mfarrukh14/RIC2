# RIC2 - Inventory & Store Management System

**Complete automated setup - Just clone and run!**

## 🚀 Quick Start (For Anyone Cloning This Project)

### Prerequisites
- **.NET 9 SDK** - [Download](https://dotnet.microsoft.com/download)
- **SQL Server LocalDB** (included with Visual Studio or install standalone)
- **Node.js 18+** - [Download](https://nodejs.org/)

### Option A: Automated Setup (Recommended)

**Run the setup script:**
```powershell
cd ric2
.\setup.ps1
```

The script will:
- ✅ Verify all prerequisites are installed
- ✅ Check project structure
- ✅ Offer to start backend/frontend with one command
- ✅ Show detailed instructions

### Option B: Manual Setup

**Step 1: Clone the Repository**
```powershell
git clone <repository-url>
cd ric2
```

**Step 2: Start Backend (Automatic Database Setup!)**
```powershell
cd backend\InventoryManagement.Api
dotnet run
```

**✨ That's it!** The backend will automatically:
- ✅ Create the database if it doesn't exist
- ✅ Create all 30+ tables with proper relationships
- ✅ Execute all ALTER scripts for schema modifications
- ✅ Install all 60+ stored procedures
- ✅ Start serving at `http://localhost:5100`

**First run:** ~15-20 seconds (database creation)  
**Subsequent runs:** ~2-3 seconds

**Step 3: Start Frontend**
```powershell
# Open a new terminal
cd frontend
npm install
npm run dev
```

Frontend available at: `http://localhost:5173`

**For detailed verification steps, see [SETUP_VERIFICATION.md](SETUP_VERIFICATION.md)**

---

## 🎯 Features

### ✅ Inventory Management
- Vendors, Manufacturers, Brands, Packings
- Items, Item Types, Item Units, Item Categories
- GRN (Goods Receipt Note)
- Inventory Transfers & Returns
- Purchase Summaries & Invoices
- Asset Allocation
- Sample Collection & Consumption
- Surgical Item Groups
- Contingent Bills

### ✅ Store Management  
- Store Hierarchy (Branches → Stores)
- Stock Operations & Tracking
- Stock Types & Associations
- Racks, Rows, Columns, Drawers
- Space Allocation
- Stock Audits & Adjustments
- Stock Consumption
- Store Allocation to Users

### ✅ Advanced Features
- **Stock with Least Expiry (MPL)**: Track items approaching expiration with minimum panic level alerts
- **Expired Stock Reports**: Monitor and manage expired inventory
- **Stock Flow Reports**: Track inventory movements
- **Stock Balance Reports**: Current stock positions
- **Stock Value Reports**: Financial valuation
- **Sales Summary Reports**: Daily sales, discounts, and stock analysis

---

## 📋 What Happens on First Run?

When you run `dotnet run` for the first time, the application automatically:

### Phase 1: Database Creation
- Checks if `InventoryManagementDB_SP` exists
- Creates database if not found

### Phase 2: Core Tables
Executes in order:
- Lookup tables (Countries, States, Cities, Branches, etc.)
- Manufacturers, Brands, Packings
- Item Types, Item Units
- Asset Allocations

### Phase 3: Feature Tables
Creates tables from `Database/Tables/`:
- Stores & Store Hierarchy
- Stock Types
- Item Categories
- Items
- Inventories (Inventory, InventoryDetails)
- Item Type Sale Levels
- Surgical Item Groups
- Sample Collection Items
- Purchase Summary & Invoices
- Return Inventory
- Contingent Bills
- Racks, Rack Drawers
- Space Allocations
- Stocks & Stock Audits
- Store Allocation to User
- Stock Type Associations

### Phase 4: Schema Modifications
Applies ALTER scripts:
- AlterStoreAllocationToUserTable.sql (EmployeeName field)
- AlterStoresTable.sql (Store hierarchy)
- AlterRackRowsTable.sql (Rack modifications)

### Phase 5: GRN & Transfer Tables
- GRN tables (depends on Stores and StockTypes)
- Transfer Inventory tables

### Phase 6: Stored Procedures
Installs 60+ stored procedures for all CRUD operations and reports

---

## 🔧 Configuration

### Backend (appsettings.json)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=InventoryManagementDB_SP;Trusted_Connection=true;MultipleActiveResultSets=true"
  }
}
```

**To use a different SQL Server:**
1. Update the connection string in `backend/InventoryManagement.Api/appsettings.json`
2. Ensure the SQL Server instance is running
3. Run `dotnet run` - database setup is automatic!

### Frontend API Configuration
Frontend automatically connects to `http://localhost:5100/api`

---

## 🌐 Access Points

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://localhost:5173 | React UI |
| Backend API | http://localhost:5100 | REST API |
| Swagger Docs | http://localhost:5100/swagger | Interactive API documentation |

---

## 💻 Development Mode

### Backend with Auto-reload
```powershell
cd backend\InventoryManagement.Api
dotnet watch run
```

### Frontend with Hot Reload
```powershell
cd frontend
npm run dev
```

---

## 🗂️ Project Structure

```
ric2/
├── backend/
│   ├── InventoryManagement.Api/          # Main API Project
│   │   ├── Controllers/                  # REST API Controllers
│   │   ├── Models/                       # Entity Models
│   │   ├── Services/                     # Business Logic
│   │   │   ├── DatabaseInitializationService.cs  # Auto database setup
│   │   │   └── *Service.cs              # Feature services
│   │   ├── DTOs/                         # Data Transfer Objects
│   │   ├── Program.cs                    # App entry point
│   │   └── appsettings.json             # Configuration
│   ├── Database/
│   │   ├── CreateDatabase.sql           # Database creation
│   │   ├── Create*.sql                  # Core table scripts
│   │   ├── Tables/                      # Feature tables
│   │   │   ├── Create*.sql              # Table creation
│   │   │   └── Alter*.sql               # Schema modifications
│   │   └── StoredProcedures/            # All stored procedures
│   │       ├── *_GetAll.sql
│   │       ├── *_GetById.sql
│   │       ├── *_Insert.sql
│   │       ├── *_Update.sql
│   │       ├── *_Delete.sql
│   │       └── *_Procedures.sql         # Multiple procedures
│   └── README.md
├── frontend/
│   ├── src/
│   │   ├── components/                  # Reusable components
│   │   ├── pages/                       # Page components
│   │   │   ├── StoreAllocationToUserPage.jsx
│   │   │   ├── StockWithExpiryPage.jsx
│   │   │   └── ...
│   │   ├── services/                    # API services
│   │   │   ├── branchApi.js
│   │   │   ├── storeApi.js
│   │   │   ├── stockWithExpiryApi.js
│   │   │   └── ...
│   │   ├── App.jsx                      # Main app component
│   │   └── main.jsx                     # Entry point
│   ├── package.json
│   └── vite.config.js
└── README.md                            # This file
```

---

## 🔍 Key API Endpoints

### Inventory Management
- `/api/Vendor` - Vendor management
- `/api/Manufacturer` - Manufacturer management
- `/api/Brand` - Brand management
- `/api/Item` - Item management
- `/api/ItemType` - Item type management
- `/api/GRN` - Goods receipt notes
- `/api/Inventory` - Inventory operations

### Store Management
- `/api/Branch` - Branch management
- `/api/Store` - Store management
- `/api/Stock` - Stock operations
- `/api/Rack` - Rack management
- `/api/SpaceAllocation` - Space allocation
- `/api/StoreAllocationToUser` - User store assignments

### Reports & Analytics
- `/api/StockWithExpiry` - Items approaching expiration
- `/api/ExpiredStock` - Expired stock report
- `/api/StockBalance` - Stock balance report
- `/api/StockFlow` - Stock movement report
- `/api/StockValueItems` - Stock valuation
- `/api/SaleSummaryDaily` - Daily sales report

*See Swagger documentation at `/swagger` for complete API reference*

---

## 🛠️ Troubleshooting

### Backend Won't Start

**Issue:** Database connection error
```
Solution: Ensure SQL Server LocalDB is installed
- Visual Studio includes it by default
- Standalone: Download "SQL Server Express LocalDB"
```

**Issue:** Port 5100 already in use
```powershell
Solution: Change port in Properties/launchSettings.json
```

### Frontend Issues

**Issue:** API calls failing
```
Solution: Ensure backend is running on http://localhost:5100
Check browser console for CORS errors
```

**Issue:** `npm install` fails
```powershell
Solution: Clear npm cache and retry
npm cache clean --force
npm install
```

### Database Issues

**Issue:** "Database already exists" errors on subsequent runs
```
Solution: This is normal! The app detects existing database and skips creation
```

**Issue:** Want to reset database completely
```powershell
Solution: Delete database and rerun
sqlcmd -S "(localdb)\MSSQLLocalDB" -Q "DROP DATABASE InventoryManagementDB_SP"
dotnet run
```

---

## 🧪 Testing the Setup

After starting both backend and frontend:

1. **Check Backend Health:**
   - Visit http://localhost:5100/swagger
   - Try the `/api/Branch/` GET endpoint
   - Should return list of branches

2. **Check Frontend:**
   - Visit http://localhost:5173
   - Navigate to "Stock with Least Expiry"
   - Dropdowns should populate from database

3. **Check Database:**
   ```powershell
   sqlcmd -S "(localdb)\MSSQLLocalDB" -d InventoryManagementDB_SP -Q "SELECT COUNT(*) as TableCount FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'"
   ```
   Should show 30+ tables

---

## 📚 Additional Documentation

- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Quick reference card for common commands and operations
- **[SETUP_VERIFICATION.md](SETUP_VERIFICATION.md)** - Step-by-step verification guide
- **[Backend Architecture](backend/README.md)** - Detailed backend documentation
- **[Database Schema](backend/Database/README.md)** - Database structure
- **[API Documentation](http://localhost:5100/swagger)** - Interactive API docs (when running)

---

## 🤝 Contributing

This project uses:
- **Backend:** ASP.NET Core 9.0, SQL Server, Stored Procedures
- **Frontend:** React 18, Vite, Tailwind CSS, Axios
- **Architecture:** Clean architecture with service layer pattern

---

## 📝 License

MIT License - See LICENSE file for details

---

## ✨ Summary

**Clone → Run → Ready!**

No manual database setup required. No SQL scripts to run manually. Just `dotnet run` and everything is configured automatically.
