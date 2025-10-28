namespace InventoryManagement.Api.Models
{
    public class StockBalanceReport
    {
        public string User { get; set; } = string.Empty;
        public DateTime FromDate { get; set; }
        public DateTime ToDate { get; set; }
        public string StoreName { get; set; } = string.Empty;
        public StockSummary Summary { get; set; } = new();
    }

    public class StockSummary
    {
        // Stock In
        public decimal OpeningStockPurchase { get; set; }
        public decimal OpeningStockSale { get; set; }
        public decimal PurchaseStockPurchase { get; set; }
        public decimal PurchaseStockSale { get; set; }
        public decimal PatientBillReturnPurchase { get; set; }
        public decimal PatientBillReturnSale { get; set; }
        public decimal BuyDemandReceivedStockPurchase { get; set; }
        public decimal BuyDemandReceivedStockSale { get; set; }
        public decimal ProcedureMedicinesReceivedStockPurchase { get; set; }
        public decimal ProcedureMedicinesReceivedStockSale { get; set; }
        public decimal ProcedureFeeReceivedPurchase { get; set; }
        public decimal ProcedureFeeReceivedSale { get; set; }
        public decimal OrdersReceivedPurchase { get; set; }
        public decimal OrdersReceivedSale { get; set; }
        public decimal AssetAllocationReceivedStockPurchase { get; set; }
        public decimal AssetAllocationReceivedStockSale { get; set; }
        public decimal CustomerChallanFormsReceivedPurchase { get; set; }
        public decimal CustomerChallanFormsReceivedSale { get; set; }
        public decimal StockAuditPurchase { get; set; }
        public decimal StockAuditSale { get; set; }
        public decimal SampleCollectionConsumptionItemsReceivedPurchase { get; set; }
        public decimal SampleCollectionConsumptionItemsReceivedSale { get; set; }
        public decimal StockWastageReceivedPurchase { get; set; }
        public decimal StockWastageReceivedSale { get; set; }
        public decimal StockReturnReceivedPurchase { get; set; }
        public decimal StockReturnReceivedSale { get; set; }

        // Stock Out
        public decimal SaleStockPurchase { get; set; }
        public decimal SaleStockSale { get; set; }
        public decimal PurchaseReturnPurchase { get; set; }
        public decimal PurchaseReturnSale { get; set; }
        public decimal StockExpiredAndDamagedPurchase { get; set; }
        public decimal StockExpiredAndDamagedSale { get; set; }
        public decimal SaleDemandIssuedStockPurchase { get; set; }
        public decimal SaleDemandIssuedStockSale { get; set; }
        public decimal ProcedureMedicinesPurchase { get; set; }
        public decimal ProcedureMedicinesSale { get; set; }
        public decimal ProcedureFeePurchase { get; set; }
        public decimal ProcedureFeeSale { get; set; }
        public decimal OrdersIssuedPurchase { get; set; }
        public decimal OrdersIssuedSale { get; set; }
        public decimal AssetAllocationPurchase { get; set; }
        public decimal AssetAllocationSale { get; set; }
        public decimal CustomerChallanFormsIssuedPurchase { get; set; }
        public decimal CustomerChallanFormsIssuedSale { get; set; }
        public decimal StockAuditOutPurchase { get; set; }
        public decimal StockAuditOutSale { get; set; }
        public decimal SampleCollectionConsumptionItemsIssuedPurchase { get; set; }
        public decimal SampleCollectionConsumptionItemsIssuedSale { get; set; }
        public decimal StockWastagePurchase { get; set; }
        public decimal StockWastageSale { get; set; }
        public decimal StockReturnPurchase { get; set; }
        public decimal StockReturnSale { get; set; }
        public decimal ClosingStockPurchase { get; set; }
        public decimal ClosingStockSale { get; set; }
    }

    public class StockBalanceSearchRequest
    {
        public DateTime? StartDate { get; set; }
        public DateTime? EndDate { get; set; }
        public string? Store { get; set; }
        public string? Branch { get; set; }
    }
}
