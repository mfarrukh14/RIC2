-- dbo.Branch.QID holds the original iHealthCure.dbo.Branches.Id (GUID) for every
-- one of the 26 branches migrated in. This is the key to correctly re-deriving
-- the real per-row BranchId for every table MigrateFromIHealthCure_HMSMAIN_TF.sql
-- bulk-tagged to @MainBranchId=1 instead of preserving the source branch.
IF OBJECT_ID('dbo.BranchQidMap', 'U') IS NOT NULL
    DROP TABLE dbo.BranchQidMap;

CREATE TABLE dbo.BranchQidMap (
    QID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
    BranchId INT NOT NULL,
    BranchName NVARCHAR(500) NOT NULL
);

INSERT INTO dbo.BranchQidMap (QID, BranchId, BranchName)
SELECT QID, BranchId, BranchName FROM dbo.Branch WHERE QID IS NOT NULL;

SELECT * FROM dbo.BranchQidMap ORDER BY BranchId;
