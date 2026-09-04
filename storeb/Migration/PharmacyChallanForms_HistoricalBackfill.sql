-- =============================================================================
-- Pharmacy.PharmacyChallanForms was never migrated at all - 0 rows vs 1,031 in
-- iHealthCure.dbo.PharmacyChallanForms. Column names/types match 1:1 between
-- old and new except GUID FK columns became int FKs. Since the target table
-- starts empty, this is a straight INSERT (no natural-key matching needed).
--
-- FK resolution - only columns with confirmed-existing QID mapping infra are
-- resolved; everything else is left NULL rather than guessed (same principle
-- used throughout this session's other migrations):
--   - StoreId    -> Pharmacy.PharmacyStores.QID (98.6% populated)
--   - BranchId   -> dbo.BranchQidMap.QID (established earlier this session)
--   - ActionById, PrescribedById, CheckInDoctorId -> dbo.Users.QID (these are
--     all iHealthCure User GUIDs; CheckInDoctorId is a doctor, who is a User
--     in this HMS) - backfilled at 92.7% by Users_AddQidAndBackfill.sql.
-- All other GUID FKs (PatientId, PrescribedInId, ChallanTypeId,
-- PatientPharmacyId, WorkingSessionId, CheckInDepartmentId,
-- CheckInSubDepartmentId, ClosingVoucherId, ClosingPharmacyChallanId,
-- ClosingPharmacyFinalChallanId, PaymentMethodId, ClosingVoucherIdInventory,
-- PatientAddressId, PatientPaymentId, ProcedureCheckInId, BranchLocationId,
-- PaymentTypeId, RefundingChallanId, SurgicalItemGroupId, SubServiceId,
-- CustomPanelOrganizationId, CustomPanelOrganizationPackageId,
-- PatientPanelOrganizationPackageId, ReceptionCounterId) point at subsystems
-- (Patients, Vouchers, WorkingSessions, etc.) that are out of scope for this
-- migration and have no ID correspondence - left NULL. QID is captured on
-- every row so these can be resolved later if/when those subsystems migrate.
-- =============================================================================

IF COL_LENGTH('Pharmacy.PharmacyChallanForms', 'QID') IS NULL
BEGIN
    ALTER TABLE Pharmacy.PharmacyChallanForms ADD QID UNIQUEIDENTIFIER NULL;
END
GO

IF OBJECT_ID('dbo.PharmacyChallanForms_HistoricalBackfill_Log', 'U') IS NOT NULL
    DROP TABLE dbo.PharmacyChallanForms_HistoricalBackfill_Log;
CREATE TABLE dbo.PharmacyChallanForms_HistoricalBackfill_Log (
    NewId INT NOT NULL,
    OldQID UNIQUEIDENTIFIER NOT NULL,
    InsertedOn DATETIME NOT NULL DEFAULT GETUTCDATE()
);

INSERT INTO Pharmacy.PharmacyChallanForms (
    PatientId, VisitNo, ChallanNo, ActionById, Timestamp, Amount, Discount,
    AlreadyPaid, PaidAmount, Total, Remaining, GrandTotal, DiscountType,
    PrintCount, BranchId, PrescribedInId, ChallanTypeId, IsFinalized,
    PatientPharmacyId, PrescribedById, Html, StoreId, RefundingChallanNo,
    WorkingSessionId, CheckInDoctorId, CheckInDepartmentId, CheckInSubDepartmentId,
    IsInPatient, ClosingVoucherId, ClosingPharmacyChallanId, ClosingPharmacyChallanNo,
    ClosingPharmacyFinalChallanId, ClosingPharmacyFinalChallanNo, IsClosingPharmacyChallanFinal,
    PaymentMethodId, ClosingVoucherIdInventory, TotalUnitBuyingPrice,
    IsPercentageServiceCharges, ServiceCharges, IsPercentageGST, GST, Keyword,
    Change, PatientAddressId, PaymentNumber, PatientPaymentId, ProcedureCheckInId,
    AppointmentNo, SubServiceName, BranchLocationId, ReferenceType, ReferenceNumber,
    BookingRemarks, PaymentTypeId, SubServiceDoctorName, RefundingChallanId,
    ManualPatientName, ManualPatientContactNo, IsProvisionalRefund, SurgicalItemGroupId,
    SubServiceId, CustomPanelOrganizationId, CustomPanelOrganizationPackageId,
    CustomPanelEmployeeNo, CustomPanelEntitleLetterA, CustomPanelEntitleLetterB,
    RetailCharges, RetailChargesType, GSTCharges, GSTChargesType,
    RetailChargesCalculatedAmount, GSTChargesCalculatedAmount, PatientPanelOrganizationPackageId,
    PatientFullName, IsSessionManagementEnabled, ReceptionCounterId, TaxAmount,
    DrivingLicenseNo, InsuranceNo,
    IsSendRequestToPharmacyForDispensingWithoutPricingForIsTakePharmacyBillInPharmacy,
    QID
)
OUTPUT inserted.Id, inserted.QID INTO dbo.PharmacyChallanForms_HistoricalBackfill_Log(NewId, OldQID)
SELECT
    NULL, src.VisitNo, src.ChallanNo, actionBy.UserID AS ActionById, src.Timestamp, src.Amount, src.Discount,
    src.AlreadyPaid, src.PaidAmount, src.Total, src.Remaining, src.GrandTotal, src.DiscountType,
    src.PrintCount, branchMap.BranchId, NULL, NULL, ISNULL(src.IsFinalized, 0),
    NULL, prescribedBy.UserID AS PrescribedById, src.Html, storeMap.Id AS StoreId, src.RefundingChallanNo,
    NULL, checkInDoctor.UserID AS CheckInDoctorId, NULL, NULL,
    ISNULL(src.IsInPatient, 0), NULL, NULL, src.ClosingPharmacyChallanNo,
    NULL, src.ClosingPharmacyFinalChallanNo, ISNULL(src.IsClosingPharmacyChallanFinal, 0),
    NULL, NULL, src.TotalUnitBuyingPrice,
    src.IsPercentageServiceCharges, src.ServiceCharges, src.IsPercentageGST, src.GST, src.Keyword,
    src.Change, NULL, src.PaymentNumber, NULL, NULL,
    src.AppointmentNo, src.SubServiceName, NULL, src.ReferenceType, src.ReferenceNumber,
    src.BookingRemarks, NULL, src.SubServiceDoctorName, NULL,
    src.ManualPatientName, src.ManualPatientContactNo, src.IsProvisionalRefund, NULL,
    NULL, NULL, NULL,
    src.CustomPanelEmployeeNo, src.CustomPanelEntitleLetterA, src.CustomPanelEntitleLetterB,
    src.RetailCharges, src.RetailChargesType, src.GSTCharges, src.GSTChargesType,
    src.RetailChargesCalculatedAmount, src.GSTChargesCalculatedAmount, NULL,
    src.PatientFullName, ISNULL(src.IsSessionManagementEnabled, 0), NULL, src.TaxAmount,
    src.DrivingLicenseNo, src.InsuranceNo,
    ISNULL(src.IsSendRequestToPharmacyForDispensingWithoutPricingForIsTakePharmacyBillInPharmacy, 0),
    src.Id
FROM iHealthCure.dbo.PharmacyChallanForms src
LEFT JOIN Pharmacy.PharmacyStores storeMap ON storeMap.QID = src.StoreId
LEFT JOIN dbo.BranchQidMap branchMap ON branchMap.QID = src.BranchId
LEFT JOIN dbo.Users actionBy ON actionBy.QID = src.ActionById
LEFT JOIN dbo.Users prescribedBy ON prescribedBy.QID = src.PrescribedById
LEFT JOIN dbo.Users checkInDoctor ON checkInDoctor.QID = src.CheckInDoctorId;

PRINT 'PharmacyChallanForms historical backfill inserted:';
SELECT COUNT(*) AS RowsInserted FROM dbo.PharmacyChallanForms_HistoricalBackfill_Log;
PRINT 'PharmacyChallanForms final counts:';
SELECT COUNT(*) AS Total, COUNT(QID) AS WithQid, COUNT(StoreId) AS WithStoreId, COUNT(BranchId) AS WithBranchId, COUNT(ActionById) AS WithActionBy FROM Pharmacy.PharmacyChallanForms;
