import { useCallback, useEffect, useRef, useState } from 'react';

// Single shared data-fetching pattern for every server-paginated list page.
// `fetchPage` must accept { pageNumber, pageSize, ...filters } and resolve to
// the backend's PagedResult shape: { items, totalCount }. Pass whatever
// filter object the page needs (search term, dropdown selections, date
// range, etc.) - changing it resets back to page 1, same as changing the
// page size, since the previous page number is meaningless against a new
// filtered/re-sized result set.
export default function usePagedList(fetchPage, filters = {}, options = {}) {
  // autoLoad: false skips fetching on mount/filter-change - use for
  // click-to-search report-style pages (e.g. Stock) where a "Generate" button
  // decides when the first request goes out. Call search() from that
  // button's handler to trigger it; after the first search() call, page-size
  // changes still refresh the same search server-side (there's no "current
  // filters" to lose since they're already applied).
  const { initialPageSize = 10, autoLoad = true } = options;

  const [items, setItems] = useState([]);
  const [totalCount, setTotalCount] = useState(0);
  // Raw last server response, for pages whose PagedResult carries extra fields
  // beyond items/totalCount (e.g. a full-filtered-set Totals summary row) -
  // most callers can ignore this and just use items/totalCount.
  const [raw, setRaw] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(initialPageSize);
  const [loading, setLoading] = useState(autoLoad);
  const [error, setError] = useState(null);

  const filtersRef = useRef(filters);
  filtersRef.current = filters;
  const filtersKey = JSON.stringify(filters);
  const hasSearchedRef = useRef(autoLoad);

  const load = useCallback(async (pageNumber, size, filtersOverride) => {
    setLoading(true);
    setError(null);
    try {
      const result = await fetchPage({
        pageNumber,
        pageSize: size,
        ...(filtersOverride !== undefined ? filtersOverride : filtersRef.current),
      });
      setItems(result.items || []);
      setTotalCount(result.totalCount || 0);
      setRaw(result);
    } catch (err) {
      setError(err);
      setItems([]);
      setTotalCount(0);
      setRaw(null);
    } finally {
      setLoading(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fetchPage]);

  // Filters (including page size) changed - go back to page 1 rather than
  // re-fetching whatever page number happened to be selected before.
  useEffect(() => {
    if (!autoLoad) return;
    setCurrentPage(1);
    load(1, pageSize);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filtersKey, pageSize, load, autoLoad]);

  // For manual (autoLoad: false) pages, a page-size change after the first
  // search() should still re-run server-side at page 1 - there's no "pending
  // filters" concern since filters were already locked in by search().
  useEffect(() => {
    if (autoLoad || !hasSearchedRef.current) return;
    setCurrentPage(1);
    load(1, pageSize);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pageSize]);

  const goToPage = useCallback((pageNumber) => {
    setCurrentPage(pageNumber);
    load(pageNumber, pageSize);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pageSize, load]);

  // filtersOverride bypasses filtersRef so a click handler can update filter
  // state and search in the same tick without waiting for the re-render that
  // would otherwise be needed for filtersRef to pick up the new value.
  const search = useCallback((filtersOverride) => {
    hasSearchedRef.current = true;
    setCurrentPage(1);
    load(1, pageSize, filtersOverride);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pageSize, load]);

  const reload = useCallback(() => load(currentPage, pageSize), [load, currentPage, pageSize]);

  return {
    items,
    totalCount,
    raw,
    currentPage,
    pageSize,
    setPageSize,
    goToPage,
    search,
    loading,
    error,
    reload,
  };
}
