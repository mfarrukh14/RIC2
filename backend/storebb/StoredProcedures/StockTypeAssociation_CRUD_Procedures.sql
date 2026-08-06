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
        st.Name AS StockTypeName,
        sta.PatientTypes,
        sta.CreatedOn
    FROM Inv.StockTypeAssociations sta
    LEFT JOIN Inv.PharmacyStores s ON sta.PharmacyStoreId = s.StoreId
    LEFT JOIN Inv.StockTypes st ON sta.StockTypes = st.Id
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
        st.Name AS StockTypeName,
        sta.PatientTypes,
        sta.CreatedOn
    FROM Inv.StockTypeAssociations sta
    LEFT JOIN Inv.PharmacyStores s ON sta.PharmacyStoreId = s.StoreId
    LEFT JOIN Inv.StockTypes st ON sta.StockTypes = st.Id
    WHERE sta.Id = @Id;
END
GO

-- =============================================
-- Insert Stock Type Association
-- =============================================
CREATE OR ALTER PROCEDURE StockTypeAssociation_Insert
    @PharmacyStoreId INT,
    @StockTypes INT,
    @PatientTypes INT,
    @CreatedById INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO Inv.StockTypeAssociations (
            PharmacyStoreId,
            StockTypes,
            PatientTypes,
            IsActive,
            CreatedById,
            CreatedOn
        )
        VALUES (
            @PharmacyStoreId,
            @StockTypes,
            @PatientTypes,
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
    @PharmacyStoreId INT,
    @StockTypes INT,
    @PatientTypes INT,
    @ModifiedById INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        UPDATE Inv.StockTypeAssociations
        SET
            PharmacyStoreId = @PharmacyStoreId,
            StockTypes = @StockTypes,
            PatientTypes = @PatientTypes,
            ModifiedById = @ModifiedById,
            ModifiedOn = GETDATE()
        WHERE Id = @Id;

        SELECT @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

-- =============================================
-- Delete Stock Type Association (permanent)
-- =============================================
CREATE OR ALTER PROCEDURE StockTypeAssociation_Delete
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DELETE FROM Inv.StockTypeAssociations
        WHERE Id = @Id;

        SELECT @@ROWCOUNT AS RowsAffected;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO
