import React from 'react';

// Single shared pagination control for every list page in the app - page-size
// dropdown, "Showing X to Y of Z entries", and Prev/numbered-pages/Next. Purely
// presentational: the page/pageSize state and data fetching live in
// usePagedList (see hooks/usePagedList.js), this component just renders
// whatever it's handed and reports back via onPageChange/onPageSizeChange.
const Pagination = ({
  currentPage,
  pageSize,
  totalCount,
  onPageChange,
  onPageSizeChange,
  pageSizeOptions = [10, 25, 50, 100],
}) => {
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const startIndex = totalCount === 0 ? 0 : (currentPage - 1) * pageSize + 1;
  const endIndex = Math.min(currentPage * pageSize, totalCount);

  const handlePageSizeChange = (e) => {
    onPageSizeChange(Number(e.target.value));
  };

  const renderPageButtons = () => {
    const buttons = [];
    for (let page = 1; page <= totalPages; page += 1) {
      const isEdge = page === 1 || page === totalPages;
      const isNearCurrent = page >= currentPage - 1 && page <= currentPage + 1;

      if (isEdge || isNearCurrent) {
        buttons.push(
          <button
            key={page}
            type="button"
            onClick={() => onPageChange(page)}
            className={`px-3 py-1 text-sm border rounded-md ${
              page === currentPage
                ? 'bg-blue-600 text-white border-blue-600'
                : 'bg-white text-gray-700 border-gray-300 hover:bg-gray-50'
            }`}
          >
            {page}
          </button>
        );
      } else if (page === currentPage - 2 || page === currentPage + 2) {
        buttons.push(
          <span key={page} className="px-2 text-gray-400">
            &hellip;
          </span>
        );
      }
    }
    return buttons;
  };

  return (
    <div className="flex flex-col gap-3 px-6 py-4 border-t border-gray-200 bg-gray-50 md:flex-row md:items-center md:justify-between">
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2">
          <label className="text-sm font-medium text-gray-700">Show</label>
          <select
            value={pageSize}
            onChange={handlePageSizeChange}
            className="border border-gray-300 rounded-md px-3 py-1 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            {pageSizeOptions.map((size) => (
              <option key={size} value={size}>
                {size}
              </option>
            ))}
          </select>
          <span className="text-sm font-medium text-gray-700">entries</span>
        </div>
        <div className="text-sm text-gray-700">
          {totalCount === 0
            ? 'Showing 0 to 0 of 0 entries'
            : `Showing ${startIndex} to ${endIndex} of ${totalCount} entries`}
        </div>
      </div>

      <div className="flex items-center gap-1">
        <button
          type="button"
          onClick={() => onPageChange(Math.max(1, currentPage - 1))}
          disabled={currentPage <= 1}
          className="px-3 py-1 text-sm bg-white border border-gray-300 rounded-md text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Previous
        </button>
        {renderPageButtons()}
        <button
          type="button"
          onClick={() => onPageChange(Math.min(totalPages, currentPage + 1))}
          disabled={currentPage >= totalPages}
          className="px-3 py-1 text-sm bg-white border border-gray-300 rounded-md text-gray-600 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          Next
        </button>
      </div>
    </div>
  );
};

export default Pagination;
