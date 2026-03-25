-- =============================================
-- Stock Type Association CRUD Stored Procedures
-- =============================================

-- =============================================
-- Get All Stock Type Associations
-- =============================================
CREATE OR ALTER PROCEDURE StockTypeAssociation_GetAll
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sta.Id,
        sta.PharmacyStoreId,
        s.StoreName AS StoreName,
        sta.StockTypes,
        st.StockTypeName AS StockTypeName,
        sta.PatientTypes,
        sta.CreatedOn
    FROM dbo.StockTypeAssociations sta
    LEFT JOIN dbo.Stores s ON sta.PharmacyStoreId = s.StoreId
    LEFT JOIN dbo.StockTypes st ON sta.StockTypes = st.StockTypeId
    WHERE sta.IsDeleted = 0
    ORDER BY sta.CreatedOn DESC;
END
GO

-- =============================================
-- Get Stock Type Association By Id
-- =============================================
CREATE OR ALTER PROCEDURE StockTypeAssociation_GetById
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        sta.Id,
        sta.PharmacyStoreId,
        s.StoreName AS StoreName,
        sta.StockTypes,
        st.StockTypeName AS StockTypeName,
        sta.PatientTypes,
        sta.CreatedOn
    FROM dbo.StockTypeAssociations sta
    LEFT JOIN dbo.Stores s ON sta.PharmacyStoreId = s.StoreId
    LEFT JOIN dbo.StockTypes st ON sta.StockTypes = st.StockTypeId
    WHERE sta.Id = @Id AND sta.IsDeleted = 0;
END
GO

-- =============================================
-- Insert Stock Type Association
-- =============================================
CREATE OR ALTER PROCEDURE StockTypeAssociation_Insert
    @PharmacyStoreId INT,
    @StockTypes INT,
    @PatientTypes INT,
    @CreatedById UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        INSERT INTO dbo.StockTypeAssociations (
            PharmacyStoreId,
            StockTypes,
            PatientTypes,
            CreatedById,
            CreatedOn,
            IsDeleted,
            IsActive
        )
        VALUES (
            @PharmacyStoreId,
            @StockTypes,
            @PatientTypes,
            @CreatedById,
            GETDATE(),
            0,
            1
        );
        
        SELECT SCOPE_IDENTITY() AS Id;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- =============================================
-- Update Stock Type Association
-- =============================================
CREATE OR ALTER PROCEDURE StockTypeAssociation_Update
    @Id INT,
    @PharmacyStoreId INT,
    @StockTypes INT,
    @PatientTypes INT,
    @ModifiedById UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        UPDATE dbo.StockTypeAssociations
        SET 
            PharmacyStoreId = @PharmacyStoreId,
            StockTypes = @StockTypes,
            PatientTypes = @PatientTypes,
            ModifiedById = @ModifiedById,
            ModifiedOn = GETDATE()
        WHERE Id = @Id AND IsDeleted = 0;
        
        SELECT @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- =============================================
-- Delete Stock Type Association (Soft Delete)
-- =============================================
CREATE OR ALTER PROCEDURE StockTypeAssociation_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        UPDATE dbo.StockTypeAssociations
        SET IsDeleted = 1
        WHERE Id = @Id;
        
        SELECT @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
