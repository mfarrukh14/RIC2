-- Seeds the Provisional/Final/Refund challan types used by the Retail Pharmacy
-- dispensing flow. Account.ChallanTypes already exists (migrated from the legacy
-- system) but was empty on HMS_Jun26.
IF NOT EXISTS (SELECT 1 FROM Account.ChallanTypes WHERE Name = 'Provisional')
    INSERT INTO Account.ChallanTypes (Name, Description) VALUES ('Provisional', 'Provisional');
IF NOT EXISTS (SELECT 1 FROM Account.ChallanTypes WHERE Name = 'Final')
    INSERT INTO Account.ChallanTypes (Name, Description) VALUES ('Final', 'Final');
IF NOT EXISTS (SELECT 1 FROM Account.ChallanTypes WHERE Name = 'Refund')
    INSERT INTO Account.ChallanTypes (Name, Description) VALUES ('Refund', 'Refund');
GO

PRINT 'Pharmacy challan types verified.';
GO
