# RIC2 - Inventory & Store Management System

**Unified system for managing inventory and store operations**

## 🚀 Quick Start

### Backend (ONE Command)

```powershell
cd backend
dotnet run --project InventoryManagement.Api
```

**That's it!** API runs on http://localhost:5000 and handles EVERYTHING (Inventory + Store Management).

### Frontend

```powershell
cd frontend
npm install
npm run dev
```

Frontend runs on http://localhost:5173

---

## What You Get

### ✅ Inventory Management
- Vendors, Manufacturers, Brands
- Items & Categories
- GRN, Transfers, Returns
- Purchase Reports
- Asset Allocation

### ✅ Store Management  
- Stock Operations
- Racks & Storage
- Sales Reports
- Space Allocation

**All in ONE unified API!**

---

## Prerequisites

- **.NET 9 SDK** - [Download](https://dotnet.microsoft.com/download)
- **SQL Server LocalDB** (comes with Visual Studio)
- **Node.js 18+** - [Download](https://nodejs.org/)

---

## Development Mode

```powershell
# Backend with auto-reload
cd backend
dotnet watch run --project InventoryManagement.Api

# Frontend with hot reload
cd frontend
npm run dev
```

---

## Access Points

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://localhost:5173 | React UI |
| Backend API | http://localhost:5000 | REST API |
| Swagger | http://localhost:5000/swagger | API Docs |

---
- ✅ Executes all 60+ stored procedures
- ✅ Starts serving at `http://localhost:5000`

**First run:** ~10 seconds  
**Subsequent runs:** ~2 seconds

#### Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

Frontend available at: `http://localhost:5173`

## 📖 Documentation

- **[Backend Setup Guide](backend/SETUP_GUIDE.md)** - Comprehensive backend documentation
- **[SQL Server Setup](backend/SQL_SERVER_SETUP.md)** - SQL Server LocalDB installation & troubleshooting
- **[Backend README](backend/README.md)** - Backend architecture details
- **[Frontend README](frontend/README.md)** - Frontend documentation

## 🔧 Configuration

### Database Connection

Default connection (SQL Server LocalDB):
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\MSSQLLocalDB;Database=InventoryManagementDB_SP;Trusted_Connection=true;MultipleActiveResultSets=true"
  }
}
```

To use a different SQL Server, update `backend/InventoryManagement.Api/appsettings.json`

### API URLs

- **HTTP:** `http://localhost:5000`
- **HTTPS:** `https://localhost:5001`  
- **Swagger UI:** `http://localhost:5000/swagger`

### Frontend URL

- **Development:** `http://localhost:5173`
- CORS enabled for all origins
- Swagger documentation (available at `/swagger` in development)
- Seed data with sample vendors

## Frontend (React with Tailwind CSS)

### Prerequisites
- Node.js (v16 or higher)
- npm

### Setup Instructions

1. **Navigate to the frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Update API URL (if needed):**
   Edit `src/services/api.js` and update the `API_BASE_URL` if your backend is running on a different port.

4. **Start the development server:**
   ```bash
   npm run dev
   ```

The frontend will be available at `http://localhost:5173`.

### Features

- Modern React with JSX
- Tailwind CSS for styling
- Responsive design
- Full CRUD operations for vendors
- Form validation
- Loading states and error handling
- Modal forms for add/edit operations

### Components

- **VendorList**: Displays all vendors in a card layout with actions
- **VendorForm**: Modal form for creating and editing vendors
- **App**: Main application component managing state

## Running the Full Application

1. **Start the backend:**
   ```bash
   cd backend/InventoryManagement.Api
   dotnet run
   ```

2. **Start the frontend (in a new terminal):**
   ```bash
   cd frontend
   npm run dev
   ```

3. **Open your browser and navigate to:** `http://localhost:5173`

## Development Notes

### Backend
- Uses LocalDB by default (no additional SQL Server installation required)
- Database is created automatically with seed data
- CORS is configured to allow all origins for development
- Entity Framework migrations are not used - using EnsureCreated() for simplicity

### Frontend
- Tailwind CSS is configured and ready to use
- Heroicons are included for UI icons
- Axios is configured for API calls with proper error handling
- Form validation is handled both client-side and server-side

### Future Enhancements
- Add authentication and authorization
- Implement proper Entity Framework migrations
- Add inventory items management
- Add vendor categories
- Add search and filtering capabilities
- Add data export functionality
- Add audit logging
- Add unit and integration tests

## Troubleshooting

### Backend Issues
- If you get database connection errors, ensure SQL Server LocalDB is installed
- Check the connection string in `appsettings.json`
- Make sure the correct port is specified in the connection string

### Frontend Issues
- If API calls fail, check that the backend is running and accessible
- Verify the `API_BASE_URL` in `src/services/api.js` matches your backend URL
- Check browser console for CORS errors
