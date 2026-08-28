-- =============================================
-- Fix Inv.SpaceAllocations schema
-- =============================================
-- The live Inv.SpaceAllocations table was created by the stale FixSpaceAllocations.sql /
-- Tables\CreateSpaceAllocationsTable.sql scripts against a pre-Inv-schema design: it uses
-- UNIQUEIDENTIFIER for Id/ItemId/FeeId/MedicineId/RackRowId/RackColumnId/RackDrawerId/
-- CreatedById/ModifiedById and FKs to a "dbo.Stores" table that no longer exists (stores are
-- Pharmacy.PharmacyStores / Inv.PharmacyStores now). Every sibling rack-location table
-- (Inv.Racks/RackRows/RackColumns/RackDrawrs) is int-based, and the checked-in
-- SpaceAllocation_Procedures.sql plus SpaceAllocationService.cs already assume an all-int
-- schema - the live table was simply never brought in line, which is why
-- SpaceAllocation_GetAll was never deployable against it. Table has 0 rows, so recreating it
-- is non-destructive.
IF OBJECT_ID('Inv.SpaceAllocations', 'U') IS NOT NULL
    DROP TABLE Inv.SpaceAllocations;
GO

CREATE TABLE Inv.SpaceAllocations (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    StoreId INT NOT NULL,
    ItemId INT NOT NULL,
    FeeId INT NULL,
    MedicineId INT NULL,
    RackId INT NOT NULL,
    RackRowId INT NULL,
    RackColumnId INT NULL,
    RackDrawerId INT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedById INT NULL,
    CreatedOn DATETIME NOT NULL DEFAULT GETDATE(),
    ModifiedById INT NULL,
    ModifiedOn DATETIME NULL,
    CONSTRAINT FK_SpaceAllocations_StoreId_PharmacyStores FOREIGN KEY (StoreId) REFERENCES Pharmacy.PharmacyStores(Id),
    CONSTRAINT FK_SpaceAllocations_RackId_Racks FOREIGN KEY (RackId) REFERENCES Inv.Racks(Id),
    CONSTRAINT FK_SpaceAllocations_RackRowId_RackRows FOREIGN KEY (RackRowId) REFERENCES Inv.RackRows(Id),
    CONSTRAINT FK_SpaceAllocations_RackColumnId_RackColumns FOREIGN KEY (RackColumnId) REFERENCES Inv.RackColumns(Id),
    CONSTRAINT FK_SpaceAllocations_RackDrawerId_RackDrawrs FOREIGN KEY (RackDrawerId) REFERENCES Inv.RackDrawrs(Id),
    CONSTRAINT FK_SpaceAllocations_ItemId_Items FOREIGN KEY (ItemId) REFERENCES Inv.Items(Id),
    CONSTRAINT FK_SpaceAllocations_MedicineId_Medicines FOREIGN KEY (MedicineId) REFERENCES Pharmacy.Medicines(MedicineId),
    CONSTRAINT FK_SpaceAllocations_FeeId_Fees FOREIGN KEY (FeeId) REFERENCES Account.Fees(Id)
);
GO

PRINT 'Inv.SpaceAllocations recreated with int-based schema (matching Inv.Racks/RackRows/RackColumns/RackDrawrs and SpaceAllocationService.cs)';
GO
