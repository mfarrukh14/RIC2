IF COL_LENGTH('dbo.PurchaseOrderTypes', 'Description') IS NULL
BEGIN
    ALTER TABLE dbo.PurchaseOrderTypes
    ADD Description NVARCHAR(500) NULL;
END
GO

UPDATE dbo.PurchaseOrderTypes
SET Description = Name
WHERE Description IS NULL OR LTRIM(RTRIM(Description)) = '';
GO