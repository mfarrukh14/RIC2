-- =============================================================================
-- dbo.Users is the LIVE user table (2243 rows, still being written to). This
-- script only ADDS a nullable QID column and backfills it on EXISTING rows via
-- UPDATE. No row is deleted, no other column is touched.
--
-- Match key: UserName. EmpID (new) turned out to be a plain sequential int
-- unrelated to old EmployeeNumber (CNIC-style strings) - not usable. CreatedOn
-- on the new side has been reset to a uniform recent timestamp (same pattern
-- seen on PharmacyMedicinesStocks) so it can't help disambiguate either.
-- UserName is unique on 2095/2243 new rows and 2103/2247 old rows; joining the
-- unique-only sets on both sides resolves 2079/2243 (92.7%). The remaining
-- rows share a duplicated username with another row and are left QID NULL
-- rather than guessed.
-- =============================================================================

IF COL_LENGTH('dbo.Users', 'QID') IS NULL
BEGIN
    ALTER TABLE dbo.Users ADD QID UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID('dbo.Users_Backfill_Backup', 'U') IS NOT NULL
    DROP TABLE dbo.Users_Backfill_Backup;
CREATE TABLE dbo.Users_Backfill_Backup (
    RowId INT NOT NULL,
    OldQID UNIQUEIDENTIFIER NULL,
    CapturedOn DATETIME NOT NULL DEFAULT GETUTCDATE()
);
INSERT INTO dbo.Users_Backfill_Backup (RowId, OldQID)
SELECT UserID, QID FROM dbo.Users;

;WITH NewUnique AS (
    SELECT UserName FROM dbo.Users GROUP BY UserName HAVING COUNT(*) = 1
),
OldUnique AS (
    SELECT Id, UserName FROM iHealthCure.dbo.Users
    WHERE UserName IN (SELECT UserName FROM iHealthCure.dbo.Users GROUP BY UserName HAVING COUNT(*) = 1)
)
UPDATE u
SET u.QID = o.Id
FROM dbo.Users u
JOIN NewUnique nu ON nu.UserName = u.UserName
JOIN OldUnique o ON o.UserName = u.UserName;

PRINT 'Users QID population:';
SELECT COUNT(*) AS Total, COUNT(QID) AS WithQid FROM dbo.Users;
