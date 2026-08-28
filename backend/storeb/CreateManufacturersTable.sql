-- Create Manufacturers table based on the provided schema
USE InventoryManagementDB_SP;
GO

-- Create Manufacturers table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Manufacturers' AND xtype='U')
BEGIN
    CREATE TABLE Manufacturers (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        Name NVARCHAR(MAX) NOT NULL,
        Description NVARCHAR(MAX) NULL,
        Email NVARCHAR(MAX) NULL,
        Address NVARCHAR(MAX) NULL,
        CNo NVARCHAR(MAX) NULL,
        NTN NVARCHAR(MAX) NULL,
        STN NVARCHAR(MAX) NULL,
        CPName1 NVARCHAR(MAX) NULL,
        CPEmail1 NVARCHAR(MAX) NULL,
        CPContactNumber1 NVARCHAR(MAX) NULL,
        CPName2 NVARCHAR(MAX) NULL,
        CPEmail2 NVARCHAR(MAX) NULL,
        CPContactNumber2 NVARCHAR(MAX) NULL,
        CountryId INT NULL,
        StateOrProvinceId INT NULL,
        CityId INT NULL,
        BranchId INT NULL,
        IsActive BIT DEFAULT 1,
        CreatedById INT NULL,
        CreatedOn DATETIME2 DEFAULT GETUTCDATE(),
        ModifiedById INT NULL,
        ModifiedOn DATETIME2 NULL,
        RegisteredOwner NVARCHAR(MAX) NULL,
        
        -- Foreign Key Constraints
        FOREIGN KEY (CountryId) REFERENCES Countries(Id),
        FOREIGN KEY (StateOrProvinceId) REFERENCES StateOrProvinces(Id),
        FOREIGN KEY (CityId) REFERENCES Cities(Id),
        FOREIGN KEY (BranchId) REFERENCES Branches(Id)
    );
    
    -- Insert sample manufacturers
    INSERT INTO Manufacturers (
        Name, Description, Email, Address, CNo, NTN, STN,
        CPName1, CPEmail1, CPContactNumber1,
        CountryId, StateOrProvinceId, CityId,
        RegisteredOwner, IsActive, CreatedById, CreatedOn
    ) VALUES 
    (
        'Nisa SF Pvt Ltd',
        'Leading medical equipment manufacturer',
        'info@nisasf.com',
        '10-km Mundko Shahzadpur road District Shahzadpur, Pakistan',
        '03915455461',
        'NTN123456',
        'STN789',
        'Ahmed Ali',
        'ahmed@nisasf.com',
        '03915455461',
        1, -- Pakistan
        1, -- Sindh
        2, -- Shahzadpur
        'Ahmed Ali',
        1,
        1,
        GETUTCDATE()
    ),
    (
        'Beijing Domax Medical',
        'Advanced medical device manufacturer',
        'info@domaxmedical.com',
        'A12-7, Jingtianongnanci street, tongzhou district, Beijing',
        '0086-10-56771179',
        'NTN987654',
        'STN321',
        'Li Wei',
        'li.wei@domaxmedical.com',
        '0086-10-56771179',
        4, -- China
        5, -- Beijing
        6, -- Beijing City
        'Li Wei',
        1,
        1,
        GETUTCDATE()
    );
END
GO

PRINT 'Manufacturers table created and sample data inserted successfully!';