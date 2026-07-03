import React, { useState } from 'react';
import {
  ChevronLeftIcon,
  ChevronRightIcon,
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
  DocumentIcon,
  ShoppingCartIcon,
  ChartBarIcon,
  ClockIcon,
  ArchiveBoxIcon,
  ArrowTrendingUpIcon,
  CalendarIcon,
  XCircleIcon,
  CurrencyDollarIcon,
  TableCellsIcon,
  MapIcon,
  UsersIcon,
  ArrowRightOnRectangleIcon
} from '@heroicons/react/24/outline';
import { useSession } from '../context/SessionContext';

const Sidebar = ({ activeSection, onSectionChange, collapsed, onToggleCollapse }) => {
  const { session, logout } = useSession();
  const menuItems = [
    {
      id: 'dashboard',
      title: 'Dashboard',
      icon: HomeIcon,
      hasSubmenu: false
    },
    {
      id: 'inventory',
      title: 'Inventory Management',
      icon: CubeIcon,
      hasSubmenu: true,
      submenu: [
        { id: 'add-inventory', title: 'Add Inventory', icon: PlusIcon },
        { id: 'add-items', title: 'Add Items', icon: PlusIcon },
        { id: 'asset-allocation', title: 'Asset / Items Allocation', icon: ArrowsRightLeftIcon },
        { id: 'asset-allocation-report', title: 'Asset / Items Allocation Report', icon: DocumentTextIcon },
        { id: 'item-units', title: 'Item Units', icon: ScaleIcon },
        { id: 'item-types', title: 'Item Types', icon: TagIcon },
        { id: 'item-category', title: 'Item Category', icon: FolderIcon },
        { id: 'packing-types', title: 'Packing Types', icon: CubeIcon },
        { id: 'brands', title: 'Brands', icon: TagIcon },
        { id: 'manufacturers', title: 'Manufacturers', icon: BuildingOfficeIcon },
        { id: 'vendors', title: 'Vendors', icon: TruckIcon },
        { id: 'inventory-receiving', title: 'Inventory Receiving (GRN)', icon: ArrowDownTrayIcon },
        { id: 'transfer-inventory', title: 'Transfer Inventory', icon: ArrowsRightLeftIcon },
        { id: 'return-inventory', title: 'Return Inventory Wrt Items', icon: ArrowUpTrayIcon },
        { id: 'purchase-summary', title: 'Purchase Summary', icon: ClipboardDocumentListIcon },
        { id: 'purchase-summary-wrt', title: 'Purchase Summary Wrt', icon: DocumentTextIcon },
        { id: 'sample-collection', title: 'Sample Collection', icon: BeakerIcon },
        { id: 'surgical-group', title: 'Surgical Group', icon: BeakerIcon },
        { id: 'item-type-sale-level', title: 'Item Type Sale Level', icon: ScaleIcon },
        { id: 'contingent-bill', title: 'Contingent Bill', icon: DocumentIcon }
      ]
    },
    {
      id: 'stores',
      title: 'Stores Management',
      icon: ShoppingCartIcon,
      hasSubmenu: true,
      submenu: [
        { id: 'stock', title: 'Stock', icon: CubeIcon },
        { id: 'stock-audit', title: 'Stock Audit', icon: ClipboardDocumentListIcon },
        { id: 'stock-stats', title: 'Stock Stats', icon: ChartBarIcon },
        { id: 'stock-adjustment', title: 'Stock Adjustment', icon: ArrowsRightLeftIcon },
        { id: 'stock-consumption', title: 'Stock Consumption', icon: ArrowDownTrayIcon },
        { id: 'stock-flow', title: 'Stock Flow', icon: ArrowTrendingUpIcon },
        { id: 'stock-type', title: 'Stock Type', icon: TagIcon },
        { id: 'stock-type-association', title: 'Stock Type Association', icon: ArrowsRightLeftIcon },
        { id: 'stock-expiring', title: 'Stock Expiring', icon: ClockIcon },
        { id: 'stock-expired', title: 'Stock Expired', icon: XCircleIcon },
        { id: 'stock-value-wrt-items', title: 'Stock Value Wrt Items', icon: CurrencyDollarIcon },
        { id: 'stock-detail-record', title: 'Stock Detail Record', icon: DocumentTextIcon },
        { id: 'stock-balance-report', title: 'Stock Balance Report', icon: ChartBarIcon },
        { id: 'sale-summary-daily', title: 'Sale Summary Daily', icon: CalendarIcon },
        { id: 'sale-summary-wrt-items-discount', title: 'Sale Summary Wrt Items W Discount', icon: CurrencyDollarIcon },
        { id: 'sale-summary-wrt-stock-no-discount', title: 'Sale Summary Wrt Stock WO Discount', icon: DocumentTextIcon },
        { id: 'racks', title: 'Racks', icon: ArchiveBoxIcon },
        { id: 'rack-drawers', title: 'Rack Drawers', icon: TableCellsIcon },
        { id: 'rack-columns', title: 'Rack Columns', icon: TableCellsIcon },
        { id: 'rack-rows', title: 'Rack Rows', icon: TableCellsIcon },
        { id: 'space-allocation', title: 'Space Allocation', icon: MapIcon },
        { id: 'store-management', title: 'Store Management', icon: BuildingOfficeIcon },
        { id: 'stores-allocation-to-user', title: 'Stores Allocation To User', icon: UsersIcon },
        { id: 'stock-with-least-expiry', title: 'Stock With Least Expiry', icon: ClockIcon }
      ]
    },
    {
      id: 'supply-chain',
      title: 'Supply Chain',
      icon: ClipboardDocumentListIcon,
      hasSubmenu: true,
      submenu: [
        { id: 'demand-wise-value', title: 'Demand Wise Value', icon: ClipboardDocumentListIcon },
        { id: 'estimated-purchase-order', title: 'Estimated Purchase Order', icon: ClipboardDocumentListIcon },
        { id: 'purchase-order', title: 'Purchase Order', icon: ClipboardDocumentListIcon },
        { id: 'purchase-order-type', title: 'Purchase Order Type', icon: ClipboardDocumentListIcon },
        { id: 'purchase-order-status', title: 'Purchase Order Status', icon: ClipboardDocumentListIcon },
        { id: 'place-demand', title: 'Place Demand', icon: DocumentTextIcon },
        { id: 'pending-demands', title: 'Pending Demands', icon: ClipboardDocumentListIcon },
        { id: 'approved-demands', title: 'Approved Demands', icon: ClipboardDocumentListIcon },
        { id: 'receive-stock', title: 'Receive Stock', icon: ClipboardDocumentListIcon },
        { id: 'received-stock-status', title: 'Received Stock Status', icon: ClipboardDocumentListIcon },
        { id: 'demand-request-status', title: 'Demand Request Status', icon: ClipboardDocumentListIcon },
        { id: 'stock-transitions', title: 'Stock Transitions', icon: ClipboardDocumentListIcon }
      ]
    }
  ];

  const [expandedMenus, setExpandedMenus] = useState({ inventory: true, stores: false, 'supply-chain': true });

  const toggleSubmenu = (menuId) => {
    if (collapsed) return;
    setExpandedMenus(prev => ({
      ...prev,
      [menuId]: !prev[menuId]
    }));
  };

  const handleItemClick = (itemId) => {
    onSectionChange(itemId);
  };

  return (
    <div className={`bg-white shadow-lg border-r border-gray-200 transition-all duration-300 ${collapsed ? 'w-16' : 'w-72'} flex flex-col h-screen relative`}>
      {/* Header */}
      <div className="p-4 border-b border-gray-200 flex items-center justify-between">
        {!collapsed && (
          <div className="flex items-center space-x-3">
            <img 
              src="/logo.jpg" 
              alt="Logo" 
              className="w-10 h-10 rounded-full object-cover"
              onError={(e) => {
                e.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMjAiIGZpbGw9IiMzQjgyRjYiLz4KPHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTggMTJIOSIgc3Ryb2tlPSJ3aGl0ZSIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2UtbGluZWNhcD0icm91bmQiLz4KPC9zdmc+Cjwvc3ZnPgo=';
              }}
            />
            <div>
              <h1 className="text-lg font-bold text-gray-900">Rawalpindi Institute</h1>
              <p className="text-sm text-gray-600">of Cardiology</p>
            </div>
          </div>
        )}
        
        <button
          onClick={onToggleCollapse}
          className="p-1.5 rounded-md hover:bg-gray-100 transition-colors"
        >
          {collapsed ? (
            <ChevronRightIcon className="w-5 h-5 text-gray-600" />
          ) : (
            <ChevronLeftIcon className="w-5 h-5 text-gray-600" />
          )}
        </button>
      </div>

      {/* Navigation Menu */}
      <nav className="flex-1 overflow-y-auto p-4">
        <ul className="space-y-2">
          {menuItems.map((item) => (
            <li key={item.id}>
              {/* Main Menu Item */}
              <div
                className={`flex items-center justify-between p-3 rounded-lg cursor-pointer transition-colors ${
                  activeSection === item.id
                    ? 'bg-blue-100 text-blue-700'
                    : 'text-gray-700 hover:bg-gray-100'
                }`}
                onClick={() => {
                  if (item.hasSubmenu) {
                    toggleSubmenu(item.id);
                  } else {
                    handleItemClick(item.id);
                  }
                }}
              >
                <div className="flex items-center space-x-3">
                  <item.icon className="w-5 h-5 flex-shrink-0" />
                  {!collapsed && (
                    <span className="font-medium">{item.title}</span>
                  )}
                </div>
                
                {!collapsed && item.hasSubmenu && (
                  <ChevronRightIcon
                    className={`w-4 h-4 transition-transform ${
                      expandedMenus[item.id] ? 'rotate-90' : ''
                    }`}
                  />
                )}
              </div>

              {/* Submenu */}
              {!collapsed && item.hasSubmenu && expandedMenus[item.id] && (
                <ul className="ml-6 mt-2 space-y-1">
                  {item.submenu.map((subItem) => (
                    <li key={subItem.id}>
                      <div
                        className={`flex items-center space-x-3 p-2 rounded-md cursor-pointer transition-colors ${
                          activeSection === subItem.id
                            ? 'bg-blue-50 text-blue-700 border-l-2 border-blue-700'
                            : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                        }`}
                        onClick={() => handleItemClick(subItem.id)}
                      >
                        <subItem.icon className="w-4 h-4 flex-shrink-0" />
                        <span className="text-sm">{subItem.title}</span>
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </li>
          ))}
        </ul>
      </nav>

      {/* Footer */}
      {!collapsed && (
        <div className="p-4 border-t border-gray-200 space-y-3">
          <div className="rounded-lg bg-gray-50 px-3 py-2 text-xs text-gray-600">
            <p className="font-medium text-gray-800">{session?.user?.UserName || 'User'}</p>
            <p>{session?.branchName || 'No branch assigned'}</p>
          </div>
          <button
            type="button"
            onClick={logout}
            className="flex w-full items-center justify-center gap-2 rounded-md border border-gray-200 px-3 py-2 text-xs font-medium text-gray-700 transition-colors hover:bg-gray-100"
          >
            <ArrowRightOnRectangleIcon className="w-4 h-4" />
            Logout
          </button>
          <div className="text-xs text-gray-500 text-center">
            <p>Inventory & Store Management</p>
            <p>v1.0.0</p>
          </div>
        </div>
      )}
    </div>
  );
};

export default Sidebar;