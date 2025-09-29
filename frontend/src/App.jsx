import React, { useState } from 'react';
import Sidebar from './components/Sidebar';
import VendorList from './components/VendorList';
import VendorForm from './components/VendorForm';
import ManufacturerList from './components/ManufacturerList';
import ManufacturerForm from './components/ManufacturerForm';
import PlaceholderSection from './components/PlaceholderSection';
import {
  HomeIcon,
  PlusIcon,
  CubeIcon,
  TagIcon,
  FolderIcon,
  BuildingOfficeIcon,
  TruckIcon,
  ArrowDownTrayIcon,
  ArrowUpTrayIcon,
  ArrowsRightLeftIcon,
  DocumentTextIcon,
  ClipboardDocumentListIcon,
  BeakerIcon,
  ScaleIcon,
  DocumentIcon
} from '@heroicons/react/24/outline';

function App() {
  const [activeSection, setActiveSection] = useState('vendors');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [showVendorForm, setShowVendorForm] = useState(false);
  const [editingVendor, setEditingVendor] = useState(null);
  const [showManufacturerForm, setShowManufacturerForm] = useState(false);
  const [editingManufacturer, setEditingManufacturer] = useState(null);

  const handleSectionChange = (section) => {
    setActiveSection(section);
    setShowVendorForm(false);
    setEditingVendor(null);
    setShowManufacturerForm(false);
    setEditingManufacturer(null);
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
        return (
          <div className="p-6">
            <PlaceholderSection
              title="Add Inventory"
              description="Add new inventory items to your system."
              icon={PlusIcon}
            />
          </div>
        );

      case 'add-items':
        return (
          <div className="p-6">
            <PlaceholderSection
              title="Add Items"
              description="Create and manage individual items in your inventory."
              icon={PlusIcon}
            />
          </div>
        );

      case 'asset-allocation':
        return renderPlaceholderWithPadding(
          "Asset / Items Allocation",
          "Allocate assets and items to different departments or users.",
          ArrowsRightLeftIcon
        );

      case 'asset-allocation-report':
        return renderPlaceholderWithPadding(
          "Asset / Items Allocation Report",
          "View detailed reports on asset and item allocations.",
          DocumentTextIcon
        );

      case 'item-units':
        return renderPlaceholderWithPadding(
          "Item Units",
          "Manage different units of measurement for your inventory items.",
          ScaleIcon
        );

      case 'item-types':
        return renderPlaceholderWithPadding(
          "Item Types",
          "Define and manage different types of inventory items.",
          TagIcon
        );

      case 'item-category':
        return renderPlaceholderWithPadding(
          "Item Category",
          "Organize your inventory items into categories.",
          FolderIcon
        );

      case 'packing-types':
        return renderPlaceholderWithPadding(
          "Packing Types",
          "Manage different packing and packaging types.",
          CubeIcon
        );

      case 'brands':
        return renderPlaceholderWithPadding(
          "Brands",
          "Manage brands and manufacturers of your inventory items.",
          TagIcon
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
        return renderPlaceholderWithPadding(
          "Inventory Receiving (GRN)",
          "Process goods received notes and incoming inventory.",
          ArrowDownTrayIcon
        );

      case 'transfer-inventory':
        return renderPlaceholderWithPadding(
          "Transfer Inventory",
          "Transfer inventory items between locations or departments.",
          ArrowsRightLeftIcon
        );

      case 'return-inventory':
        return renderPlaceholderWithPadding(
          "Return Inventory Wrt Items",
          "Process inventory returns and manage returned items.",
          ArrowUpTrayIcon
        );

      case 'purchase-summary':
        return renderPlaceholderWithPadding(
          "Purchase Summary",
          "View comprehensive purchase summaries and reports.",
          ClipboardDocumentListIcon
        );

      case 'purchase-summary-wrt':
        return renderPlaceholderWithPadding(
          "Purchase Summary Wrt",
          "Detailed purchase summaries with respect to specific criteria.",
          DocumentTextIcon
        );

      case 'invoices':
        return renderPlaceholderWithPadding(
          "Invoices",
          "Manage and track purchase invoices.",
          DocumentIcon
        );

      case 'sample-collection':
        return renderPlaceholderWithPadding(
          "Sample Collection",
          "Manage sample collection and testing procedures.",
          BeakerIcon
        );

      case 'consumption-item':
        return renderPlaceholderWithPadding(
          "Consumption Item",
          "Track item consumption and usage patterns.",
          CubeIcon
        );

      case 'surgical-group':
        return renderPlaceholderWithPadding(
          "Surgical Group",
          "Manage surgical equipment groups and procedures.",
          BeakerIcon
        );

      case 'item-type-sale-level':
        return renderPlaceholderWithPadding(
          "Item Type Sale Level",
          "Configure sale levels for different item types.",
          ScaleIcon
        );

      case 'contingent-bill':
        return renderPlaceholderWithPadding(
          "Contingent Bill",
          "Manage contingent billing and emergency purchases.",
          DocumentIcon
        );

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
