-- =============================================
-- Stock Type Association CRUD Stored Procedures
-- =============================================

-- =============================================
-- Get All Stock Type Associations
-- =============================================
-- NOTE: Inv.StockTypeAssociations has two parallel column pairs -
-- StoreId/StockTypeId (NOT NULL, always populated - written directly by
-- SeedDemoData.sql and any other non-app inserts) and the legacy
-- PharmacyStoreId/StockTypes/PatientTypes (nullable - only this proc's own
-- Insert/Update ever wrote them, and only for app-created rows). Reading only
-- the legacy trio crashed on any row that didn't come through this app's own
-- create/update flow (4 of 5 live rows). COALESCE falls back to the
-- always-populated columns so no row is silently dropped or crashes the read.
CREATE OR ALTER PROCEDURE StockTypeAssociation_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        sta.Id,
        COALESCE(sta.PharmacyStoreId, sta.StoreId) AS PharmacyStoreId,
        s.StoreName AS StoreName,
        COALESCE(sta.StockTypes, sta.StockTypeId) AS StockTypes,
        st.Name AS StockTypeName,
        sta.PatientTypes,
        sta.CreatedOn
    FROM Inv.StockTypeAssociations sta
    LEFT JOIN Inv.PharmacyStores s ON COALESCE(sta.PharmacyStoreId, sta.StoreId) = s.StoreId
    LEFT JOIN Inv.StockTypes st ON COALESCE(sta.StockTypes, sta.StockTypeId) = st.Id
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
        COALESCE(sta.PharmacyStoreId, sta.StoreId) AS PharmacyStoreId,
        s.StoreName AS StoreName,
        COALESCE(sta.StockTypes, sta.StockTypeId) AS StockTypes,
        st.Name AS StockTypeName,
        sta.PatientTypes,
        sta.CreatedOn
    FROM Inv.StockTypeAssociations sta
    LEFT JOIN Inv.PharmacyStores s ON COALESCE(sta.PharmacyStoreId, sta.StoreId) = s.StoreId
    LEFT JOIN Inv.StockTypes st ON COALESCE(sta.StockTypes, sta.StockTypeId) = st.Id
    WHERE sta.Id = @Id;
END
GO

-- =============================================
-- Insert Stock Type Association
-- =============================================
-- Writes both column pairs: StoreId/StockTypeId are NOT NULL with no default,
-- so leaving them unset (as this proc previously did) would fail the insert
-- outright the first time anyone actually used it. Keeping both in sync means
-- rows this proc creates work correctly whichever pair a reader uses.
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
            StoreId,
            StockTypeId,
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
            StoreId = @PharmacyStoreId,
            StockTypeId = @StockTypes,
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
