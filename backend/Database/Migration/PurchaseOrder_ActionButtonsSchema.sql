-- Schema additions backing the 6 Purchase Order action buttons (Edit, Print,
-- Reload, Reject, Vendor Attached Documents, View Log). Print/Edit/Reload need
-- no schema changes (all data already exists on Inv.PurchaseOrders/Items and
-- Inv.Vendors). Reject, View Log, and Vendor Attached Documents do.

-- 1. Reject: Inv.PurchaseOrderStatus already exists live (Id, PurchaseOrderId,
-- Status, Notes, CreatedById, CreatedOn) and is a perfect fit for logging a
-- reject action with remarks - no new table needed there. But the PO header
-- itself has nowhere to hold the rejection remarks for quick display, so add
-- one column.
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Inv.PurchaseOrders') AND name = 'RejectionRemarks'
)
BEGIN
    ALTER TABLE Inv.PurchaseOrders ADD RejectionRemarks NVARCHAR(MAX) NULL;
END
GO

-- 2. View Log: item-level substitution history. Populated by the future
-- Update endpoint whenever a PO's item list changes (item added/removed on
-- edit) - append-only, no delete/edit ever needed on this table.
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('Inv.PurchaseOrderItemLog'))
BEGIN
    CREATE TABLE Inv.PurchaseOrderItemLog (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderId INT NOT NULL,
        ItemType NVARCHAR(50) NULL,
        PreviousItemName NVARCHAR(255) NULL,
        CurrentItemName NVARCHAR(255) NULL,
        CreatedOn DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ModifiedById INT NULL,
        CONSTRAINT FK_PurchaseOrderItemLog_PurchaseOrder FOREIGN KEY (PurchaseOrderId)
            REFERENCES Inv.PurchaseOrders(PurchaseOrderId)
    );
END
GO

-- 3. Vendor Attached Documents: no file-upload mechanism exists anywhere yet
-- in this app. Files are stored on disk under wwwroot/uploads/purchase-order-attachments
-- and this table just tracks metadata. No IsActive flag - delete here is a
-- real hard delete of both the row and the file (this codebase's standing
-- convention per [[hard_delete_and_active_visibility_rule]]), not a
-- soft-delete/active-toggle entity, so there's nothing to preserve.
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID('Inv.PurchaseOrderAttachments'))
BEGIN
    CREATE TABLE Inv.PurchaseOrderAttachments (
        Id INT IDENTITY(1,1) PRIMARY KEY,
        PurchaseOrderId INT NOT NULL,
        Title NVARCHAR(255) NULL,
        FileName NVARCHAR(255) NOT NULL,
        FileUrl NVARCHAR(500) NOT NULL,
        UploadedById INT NULL,
        CreatedOn DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_PurchaseOrderAttachments_PurchaseOrder FOREIGN KEY (PurchaseOrderId)
            REFERENCES Inv.PurchaseOrders(PurchaseOrderId)
    );
END
GO
