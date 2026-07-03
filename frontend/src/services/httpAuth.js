import axios from 'axios';

export const SESSION_STORAGE_KEY = 'debugUserId';

// Adds the X-User-Id header (read fresh from localStorage on every request) to
// the given axios instance, so BaseController on the backend can identify the
// caller. Call this once per axios instance created via axios.create().
export function attachUserIdHeader(axiosInstance) {
  axiosInstance.interceptors.request.use((config) => {
    const userId = localStorage.getItem(SESSION_STORAGE_KEY);
    if (userId) {
      config.headers['X-User-Id'] = userId;
    }
    return config;
  });
}

// Most service files call the bare `axios.get/post/...` directly instead of
// creating their own instance, so they all share this default singleton -
// attaching the interceptor here covers all of them in one place.
attachUserIdHeader(axios);

// A handful of service files use the native fetch() API instead of axios.
// Wrap the global fetch once so those calls also carry the X-User-Id header.
const originalFetch = window.fetch.bind(window);
window.fetch = (input, init = {}) => {
  const userId = localStorage.getItem(SESSION_STORAGE_KEY);
  if (!userId) {
    return originalFetch(input, init);
  }

  const headers = new Headers(init.headers || (input instanceof Request ? input.headers : undefined));
  headers.set('X-User-Id', userId);
  return originalFetch(input, { ...init, headers });
};
