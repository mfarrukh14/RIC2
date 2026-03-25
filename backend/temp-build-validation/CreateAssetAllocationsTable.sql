-- =============================================
-- Create AssetAllocations table and related tables for Asset/Items Allocation
-- =============================================

USE InventoryManagementDB_SP;
GO

-- Create Users table if it doesn't exist (for user allocation)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
BEGIN
    CREATE TABLE Users (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Email NVARCHAR(100),
        UserName NVARCHAR(50),
        Department NVARCHAR(100),
        Designation NVARCHAR(100),
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    
    -- Insert sample users
    INSERT INTO Users (Name, Email, UserName, Department, Designation) VALUES 
    ('John Doe', 'john.doe@example.com', 'jdoe', 'IT', 'System Administrator'),
    ('Jane Smith', 'jane.smith@example.com', 'jsmith', 'Finance', 'Accountant'),
    ('Mike Johnson', 'mike.johnson@example.com', 'mjohnson', 'Operations', 'Manager'),
    ('Sarah Wilson', 'sarah.wilson@example.com', 'swilson', 'HR', 'HR Executive');
END
GO

-- Create Rooms table if it doesn't exist (for room allocation)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Rooms' AND xtype='U')
BEGIN
    CREATE TABLE Rooms (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX),
        Floor NVARCHAR(50),
        Building NVARCHAR(100),
        Capacity INT,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    
    -- Insert sample rooms
    INSERT INTO Rooms (Name, Description, Floor, Building, Capacity) VALUES 
    ('Conference Room A', 'Main conference room', '1st Floor', 'Main Building', 12),
    ('Meeting Room B', 'Small meeting room', '2nd Floor', 'Main Building', 6),
    ('Training Hall', 'Large training facility', 'Ground Floor', 'Training Building', 50),
    ('Office 101', 'Individual office', '1st Floor', 'Office Block', 1),
    ('Office 102', 'Individual office', '1st Floor', 'Office Block', 1);
END
GO

-- Create InventoryItems table if it doesn't exist (for asset allocation)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='InventoryItems' AND xtype='U')
BEGIN
    CREATE TABLE InventoryItems (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX),
        SerialNumber NVARCHAR(100),
        Model NVARCHAR(100),
        BrandId INT,
        ItemTypeId INT,
        ItemUnitId INT,
        ManufacturerId INT,
        PurchaseDate DATETIME2,
        PurchasePrice DECIMAL(18,2),
        CurrentValue DECIMAL(18,2),
        Condition NVARCHAR(50), -- New, Good, Fair, Poor
        Status NVARCHAR(50), -- Available, Allocated, Under Maintenance, Disposed
        BranchId INT,
        IsActive BIT DEFAULT 1,
        CreatedById INT,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT,
        ModifiedOn DATETIME2 NULL,
        
        FOREIGN KEY (BrandId) REFERENCES Brands(Id),
        FOREIGN KEY (ItemTypeId) REFERENCES ItemTypes(Id),
        FOREIGN KEY (ItemUnitId) REFERENCES ItemUnits(Id),
        FOREIGN KEY (ManufacturerId) REFERENCES Manufacturers(Id),
        FOREIGN KEY (BranchId) REFERENCES Branches(Id)
    );
    
    -- Insert sample inventory items
    INSERT INTO InventoryItems (Name, Description, SerialNumber, Model, PurchaseDate, PurchasePrice, CurrentValue, Condition, Status, BranchId, CreatedById) VALUES 
    ('Dell Laptop', 'Dell Inspiron 15 3000', 'DL123456', 'Inspiron 15 3000', '2024-01-15', 51000, 45100, 'Good', 'Available', 1, 1),
    ('HP Printer', 'HP LaserJet Pro M404n', 'HP789012', 'LaserJet Pro M404n', '2024-02-10', 25100, 23000, 'Good', 'Available', 1, 1),
    ('Office Chair', 'Ergonomic office chair', 'OC345678', 'Executive', '2024-03-05', 15100, 14000, 'Good', 'Available', 1, 1),
    ('Desktop Computer', 'Dell OptiPlex 7090', 'DC901234', 'OptiPlex 7090', '2024-01-20', 75100, 70000, 'Good', 'Available', 1, 1),
    ('Projector', 'Epson PowerLite 1761W', 'EP567890', 'PowerLite 1761W', '2024-02-25', 45100, 42000, 'Good', 'Available', 1, 1);
END
GO

-- Create AssetAllocations table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='AssetAllocations' AND xtype='U')
BEGIN
    CREATE TABLE AssetAllocations (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Remarks NVARCHAR(MAX),
        AllocatedDate DATETIME2 NOT NULL,
        ReturnDate DATETIME2 NULL,
        UserId INT,
        DepartmentId INT,
        SubDepartmentId INT,
        RoomId INT,
        ItemId INT,
        BranchId INT,
        IsReturn BIT DEFAULT 0,
        ReturnRemarks NVARCHAR(MAX),
        Quantity INT NOT NULL DEFAULT 1,
        MedicineId INT, -- For future use if needed
        SubServiceId INT, -- For future use if needed
        StockTypeId INT, -- For future use if needed
        InventoryItemId INT,
        SysBatchNo NVARCHAR(MAX),
        BatchNo NVARCHAR(MAX),
        IsActive BIT DEFAULT 1,
        CreatedById INT,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT,
        ModifiedOn DATETIME2 NULL,
        IsDeleted BIT DEFAULT 0,
        
        FOREIGN KEY (UserId) REFERENCES Users(Id),
        FOREIGN KEY (RoomId) REFERENCES Rooms(Id),
        FOREIGN KEY (InventoryItemId) REFERENCES InventoryItems(Id),
        FOREIGN KEY (BranchId) REFERENCES Branches(Id)
    );
END
GO

-- Create Departments table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Departments' AND xtype='U')
BEGIN
    CREATE TABLE Departments (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX),
        Head NVARCHAR(100),
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL
    );
    
    -- Insert sample departments
    INSERT INTO Departments (Name, Description, Head) VALUES 
    ('Information Technology', 'IT Department', 'John Doe'),
    ('Human Resources', 'HR Department', 'Sarah Wilson'),
    ('Finance', 'Finance Department', 'Jane Smith'),
    ('Operations', 'Operations Department', 'Mike Johnson'),
    ('Administration', 'Administration Department', 'Admin Head');
END
GO

-- Create SubDepartments table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='SubDepartments' AND xtype='U')
BEGIN
    CREATE TABLE SubDepartments (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(MAX),
        DepartmentId INT,
        IsActive BIT DEFAULT 1,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedOn DATETIME2 NULL,
        
        FOREIGN KEY (DepartmentId) REFERENCES Departments(Id)
    );
    
    -- Insert sample sub-departments
    INSERT INTO SubDepartments (Name, Description, DepartmentId) VALUES 
    ('Software Development', 'Software Development Team', 1),
    ('Network Administration', 'Network Administration Team', 1),
    ('Recruitment', 'Recruitment Team', 2),
    ('Employee Relations', 'Employee Relations Team', 2),
    ('Accounts Payable', 'Accounts Payable Team', 3),
    ('Accounts Receivable', 'Accounts Receivable Team', 3);
END
GO

PRINT 'AssetAllocations tables created successfully!';