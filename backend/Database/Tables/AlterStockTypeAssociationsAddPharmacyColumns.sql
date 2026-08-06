IF COL_LENGTH('dbo.StockTypeAssociations', 'PharmacyStoreId') IS NULL
BEGIN
    ALTER TABLE dbo.StockTypeAssociations
    ADD PharmacyStoreId INT NULL;
END
GO

IF COL_LENGTH('dbo.StockTypeAssociations', 'StockTypes') IS NULL
BEGIN
    ALTER TABLE dbo.StockTypeAssociations
    ADD StockTypes INT NULL;
END
GO

IF COL_LENGTH('dbo.StockTypeAssociations', 'PatientTypes') IS NULL
BEGIN
    ALTER TABLE dbo.StockTypeAssociations
    ADD PatientTypes INT NULL;
END
GO
