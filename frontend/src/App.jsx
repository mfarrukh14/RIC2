import React, { useState } from 'react';
import Sidebar from './components/Sidebar';
import VendorList from './components/VendorList';
import VendorForm from './components/VendorForm';
import ManufacturerList from './components/ManufacturerList';
import ManufacturerForm from './components/ManufacturerForm';
import BrandList from './components/BrandList';
import BrandForm from './components/BrandForm';
import PackingsPage from './pages/PackingsPage';
import ItemTypesPage from './pages/ItemTypesPage';
import ItemUnitsPage from './pages/ItemUnitsPage';
import ItemsPage from './pages/ItemsPage';
import InventoryListPage from './pages/InventoryListPage';
import GRNPage from './pages/GRNPage';
import TransferInventoryPage from './pages/TransferInventoryPage';
import ReturnInventoryPage from './pages/ReturnInventoryPage';
import PurchaseSummaryPage from './pages/PurchaseSummaryPage';
import PurchaseSummaryInvoicePage from './pages/PurchaseSummaryInvoicePage';
import SampleCollectionPage from './pages/SampleCollectionPage';
import SurgicalGroupPage from './pages/SurgicalGroupPage';
import ItemTypeSaleLevelPage from './pages/ItemTypeSaleLevelPage';
import ContingentBillsPage from './pages/ContingentBillsPage';
import ItemCategoryPage from './pages/ItemCategoryPage';
import AssetAllocationsPage from './pages/AssetAllocationsPage';
import AssetAllocationReportPage from './pages/AssetAllocationReportPage';
import StockTypePage from './pages/StockTypePage';
import StockTypeAssociationPage from './pages/StockTypeAssociationPage';
import StockExpiringPage from './pages/StockExpiringPage';
import RackPage from './pages/RackPage';
import RackDrawersPage from './pages/RackDrawersPage';
import RackColumnsPage from './pages/RackColumnsPage';
import RackRowsPage from './pages/RackRowsPage';
import SpaceAllocationsPage from './pages/SpaceAllocationsPage';
import StoreManagementPage from './pages/StoreManagementPage';
import StockPage from './pages/StockPage';
import StockAuditPage from './pages/StockAuditPage';
import StockStatsPage from './pages/StockStatsPage';
import StockAdjustmentPage from './pages/StockAdjustmentPage';
import StockConsumptionPage from './pages/StockConsumptionPage';
import StockFlowPage from './pages/StockFlowPage';
import ExpiredStockPage from './pages/ExpiredStockPage';
import StockValueWRTItemsPage from './pages/StockValueWRTItemsPage';
import StockDetailRecordPage from './pages/StockDetailRecordPage';
import StockBalanceReportPage from './pages/StockBalanceReportPage';
import SaleSummaryDailyPage from './pages/SaleSummaryDailyPage';
import SaleSummaryItemDiscountPage from './pages/SaleSummaryItemDiscountPage';
import SaleSummaryStockNoDiscountPage from './pages/SaleSummaryStockNoDiscountPage';
import StoreAllocationToUserPage from './pages/StoreAllocationToUserPage';
import StockWithExpiryPage from './pages/StockWithExpiryPage';
import PlaceDemandPage from './pages/PlaceDemandPage';
import DemandWiseValuePage from './pages/DemandWiseValuePage';
import EstimatedPurchaseOrderPage from './pages/EstimatedPurchaseOrderPage';
import PurchaseOrderPage from './pages/PurchaseOrderPage';
import PurchaseOrderTypePage from './pages/PurchaseOrderTypePage';
import PurchaseOrderStatusPage from './pages/PurchaseOrderStatusPage';
import PendingDemandsPage from './pages/PendingDemandsPage';
import ApprovedDemandsPage from './pages/ApprovedDemandsPage';
import ReceiveStockPage from './pages/ReceiveStockPage';
import ReceivedStockStatusPage from './pages/ReceivedStockStatusPage';
import DemandRequestStatusPage from './pages/DemandRequestStatusPage';
import StockTransitionsPage from './pages/StockTransitionsPage';
import PlaceholderSection from './components/PlaceholderSection';
import LoginPage from './pages/LoginPage';
import { useSession } from './context/SessionContext';
import {
  HomeIcon,
  CubeIcon,
  FolderIcon,
  BeakerIcon,
  ScaleIcon,
  DocumentIcon
} from '@heroicons/react/24/outline';

function App() {
  const { session, initializing } = useSession();
  const [activeSection, setActiveSection] = useState('vendors');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [showVendorForm, setShowVendorForm] = useState(false);
  const [editingVendor, setEditingVendor] = useState(null);
  const [showManufacturerForm, setShowManufacturerForm] = useState(false);
  const [editingManufacturer, setEditingManufacturer] = useState(null);
  const [showBrandForm, setShowBrandForm] = useState(false);
  const [editingBrand, setEditingBrand] = useState(null);
  const [showPackingForm, setShowPackingForm] = useState(false);
  const [editingPacking, setEditingPacking] = useState(null);

  const handleSectionChange = (section) => {
    setActiveSection(section);
    setShowVendorForm(false);
    setEditingVendor(null);
    setShowManufacturerForm(false);
    setEditingManufacturer(null);
    setShowBrandForm(false);
    setEditingBrand(null);
    setShowPackingForm(false);
    setEditingPacking(null);
  };

  const handleToggleSidebar = () => {
    setSidebarCollapsed(!sidebarCollapsed);
  };

  const handleAddVendor = () => {
    setEditingVendor(null);
    setShowVendorForm(true);
  };

  const handleEditVendor = (vendor) => {
    setEditingVendor(vendor);
    setShowVendorForm(true);
  };

  const handleCloseVendorForm = () => {
    setShowVendorForm(false);
    setEditingVendor(null);
  };

  const handleSaveVendor = () => {
    setShowVendorForm(false);
    setEditingVendor(null);
    // The VendorList component will refresh automatically
  };

  const handleAddManufacturer = () => {
    setEditingManufacturer(null);
    setShowManufacturerForm(true);
  };

  const handleEditManufacturer = (manufacturer) => {
    setEditingManufacturer(manufacturer);
    setShowManufacturerForm(true);
  };

  const handleCloseManufacturerForm = () => {
    setShowManufacturerForm(false);
    setEditingManufacturer(null);
  };

  const handleSaveManufacturer = () => {
    setShowManufacturerForm(false);
    setEditingManufacturer(null);
    // The ManufacturerList component will refresh automatically
  };

  const handleAddBrand = () => {
    setEditingBrand(null);
    setShowBrandForm(true);
  };

  const handleEditBrand = (brand) => {
    setEditingBrand(brand);
    setShowBrandForm(true);
  };

  const handleCloseBrandForm = () => {
    setShowBrandForm(false);
    setEditingBrand(null);
  };

  const handleSaveBrand = () => {
    setShowBrandForm(false);
    setEditingBrand(null);
    // The BrandList component will refresh automatically
  };

  const handleAddPacking = () => {
    setEditingPacking(null);
    setShowPackingForm(true);
  };

  const handleEditPacking = (packing) => {
    setEditingPacking(packing);
    setShowPackingForm(true);
  };

  const handleClosePackingForm = () => {
    setShowPackingForm(false);
    setEditingPacking(null);
  };

  const handleSavePacking = () => {
    setShowPackingForm(false);
    setEditingPacking(null);
    // The PackingList component will refresh automatically
  };



  const renderPlaceholderWithPadding = (title, description, icon) => (
    <div className="p-6">
      <PlaceholderSection title={title} description={description} icon={icon} />
    </div>
  );

  const renderMainContent = () => {
    // If vendor form is open, show it instead of the section content
    if (showVendorForm) {
      return (
        <VendorForm
          vendor={editingVendor}
          onSave={handleSaveVendor}
          onCancel={handleCloseVendorForm}
          isEditing={!!editingVendor}
        />
      );
    }

    // If manufacturer form is open, show it instead of the section content
    if (showManufacturerForm) {
      return (
        <ManufacturerForm
          manufacturer={editingManufacturer}
          onSave={handleSaveManufacturer}
          onCancel={handleCloseManufacturerForm}
          isEditing={!!editingManufacturer}
        />
      );
    }

    // If brand form is open, show it instead of the section content
    if (showBrandForm) {
      return (
        <BrandForm
          brand={editingBrand}
          onSave={handleSaveBrand}
          onCancel={handleCloseBrandForm}
          isEditing={!!editingBrand}
        />
      );
    }

    // If packing form is open, show it instead of the section content
    if (showPackingForm) {
      return (
        <PackingForm
          packing={editingPacking}
          onSave={handleSavePacking}
          onCancel={handleClosePackingForm}
          isEditing={!!editingPacking}
        />
      );
    }

    switch (activeSection) {
      case 'dashboard':
        return (
          <div className="p-6">
            <PlaceholderSection
              title="Dashboard"
              description="Overview of your inventory management system with key metrics and recent activities."
              icon={HomeIcon}
            />
          </div>
        );

      case 'vendors':
        return (
          <div className="p-6">
            <VendorList
              onEdit={handleEditVendor}
              onAdd={handleAddVendor}
            />
          </div>
        );

      case 'add-inventory':
        return <InventoryListPage />;

      case 'add-items':
        return <ItemsPage />;

      case 'asset-allocation':
        return <AssetAllocationsPage />;

      case 'asset-allocation-report':
        return <AssetAllocationReportPage />;

      case 'item-units':
        return <ItemUnitsPage />;

      case 'item-types':
        return <ItemTypesPage />;

      case 'item-category':
        return <ItemCategoryPage />;

      case 'packing-types':
        return <PackingsPage />;

      case 'brands':
        return (
          <div className="p-6">
            <BrandList
              onEdit={handleEditBrand}
              onAdd={handleAddBrand}
            />
          </div>
        );

      case 'manufacturers':
        return (
          <div className="p-6">
            <ManufacturerList
              onEdit={handleEditManufacturer}
              onAdd={handleAddManufacturer}
            />
          </div>
        );

      case 'inventory-receiving':
        return <GRNPage />;

      case 'transfer-inventory':
        return <TransferInventoryPage />;

      case 'return-inventory':
        return <ReturnInventoryPage />;

      case 'purchase-summary':
        return <PurchaseSummaryPage />;

      case 'purchase-summary-wrt':
        return <PurchaseSummaryInvoicePage />;

      case 'sample-collection':
        return <SampleCollectionPage />;

      case 'surgical-group':
        return <SurgicalGroupPage />;

      case 'item-type-sale-level':
        return <ItemTypeSaleLevelPage />;

      case 'contingent-bill':
        return <ContingentBillsPage />;

      case 'stock-type':
        return <StockTypePage />;

      case 'stock-type-association':
        return <StockTypeAssociationPage />;

      case 'stock-expiring':
        return <StockExpiringPage />;

      case 'racks':
        return <RackPage />;

      case 'rack-drawers':
        return <RackDrawersPage />;

      case 'rack-columns':
        return <RackColumnsPage />;

      case 'rack-rows':
        return <RackRowsPage />;

      case 'space-allocation':
        return <SpaceAllocationsPage />;

      case 'store-management':
        return <StoreManagementPage />;

      case 'stores-allocation-to-user':
        return <StoreAllocationToUserPage />;

      case 'stock-with-least-expiry':
        return <StockWithExpiryPage />;

      case 'stock':
        return <StockPage />;

      case 'stock-audit':
        return <StockAuditPage />;

      case 'stock-stats':
        return <StockStatsPage />;

      case 'stock-adjustment':
        return <StockAdjustmentPage />;

      case 'stock-consumption':
        return <StockConsumptionPage />;

      case 'stock-flow':
        return <StockFlowPage />;

      case 'stock-expired':
        return <ExpiredStockPage />;

      case 'stock-value-wrt-items':
        return <StockValueWRTItemsPage />;

      case 'stock-detail-record':
        return <StockDetailRecordPage />;

      case 'stock-balance-report':
        return <StockBalanceReportPage />;

      case 'sale-summary-daily':
        return <SaleSummaryDailyPage />;

      case 'sale-summary-wrt-items-discount':
        return <SaleSummaryItemDiscountPage />;

      case 'sale-summary-wrt-stock-no-discount':
        return <SaleSummaryStockNoDiscountPage />;

      case 'place-demand':
        return <PlaceDemandPage />;

      case 'demand-wise-value':
        return <DemandWiseValuePage />;

      case 'estimated-purchase-order':
        return <EstimatedPurchaseOrderPage />;

      case 'purchase-order':
        return <PurchaseOrderPage />;

      case 'purchase-order-type':
        return <PurchaseOrderTypePage />;

      case 'purchase-order-status':
        return <PurchaseOrderStatusPage />;

      case 'pending-demands':
        return <PendingDemandsPage />;

      case 'approved-demands':
        return <ApprovedDemandsPage />;

      case 'receive-stock':
        return <ReceiveStockPage />;

      case 'received-stock-status':
        return <ReceivedStockStatusPage />;

      case 'demand-request-status':
        return <DemandRequestStatusPage />;

      case 'stock-transitions':
        return <StockTransitionsPage />;

      default:
        return (
          <div className="p-6">
            <PlaceholderSection
              title="Page Not Found"
              description="The requested page could not be found."
              icon={HomeIcon}
            />
          </div>
        );
    }
  };

  if (initializing) {
    return (
      <div className="flex h-screen items-center justify-center bg-gray-100 text-gray-500">
        Loading...
      </div>
    );
  }

  if (!session) {
    return <LoginPage />;
  }

  return (
    <div className="flex h-screen bg-gray-100">
      <Sidebar
        activeSection={activeSection}
        onSectionChange={handleSectionChange}
        collapsed={sidebarCollapsed}
        onToggleCollapse={handleToggleSidebar}
      />
      
      <main className={`flex-1 overflow-hidden transition-all duration-300 ${sidebarCollapsed ? 'ml-0' : 'ml-0'}`}>
        <div className="h-full overflow-auto">
          {renderMainContent()}
        </div>
      </main>
    </div>
  );
}

export default App;
