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
        sta.StoreId,
        s.StoreName AS StoreName,
        sta.StockTypeId,
        st.Name AS StockTypeName,
        sta.CreatedOn
    FROM dbo.StockTypeAssociations sta
    LEFT JOIN dbo.Stores s ON sta.StoreId = s.StoreId
    LEFT JOIN dbo.StockTypes st ON sta.StockTypeId = st.Id
    WHERE sta.IsActive = 1
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
        sta.StoreId,
        s.StoreName AS StoreName,
        sta.StockTypeId,
        st.Name AS StockTypeName,
        sta.CreatedOn
    FROM dbo.StockTypeAssociations sta
    LEFT JOIN dbo.Stores s ON sta.StoreId = s.StoreId
    LEFT JOIN dbo.StockTypes st ON sta.StockTypeId = st.Id
    WHERE sta.Id = @Id AND sta.IsActive = 1;
END
GO

-- =============================================
-- Insert Stock Type Association
-- =============================================
CREATE OR ALTER PROCEDURE StockTypeAssociation_Insert
    @StoreId INT,
    @StockTypeId INT,
    @CreatedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        INSERT INTO dbo.StockTypeAssociations (
            StoreId,
            StockTypeId,
            IsActive,
            CreatedById,
            CreatedOn
        )
        VALUES (
            @StoreId,
            @StockTypeId,
            1,
            @CreatedById,
            GETDATE()
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
    @StoreId INT,
    @StockTypeId INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        UPDATE dbo.StockTypeAssociations
        SET 
            StoreId = @StoreId,
            StockTypeId = @StockTypeId,
            ModifiedById = @ModifiedById,
            ModifiedOn = GETDATE()
        WHERE Id = @Id AND IsActive = 1;
        
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
        SET IsActive = 0
        WHERE Id = @Id;
        
        SELECT @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
