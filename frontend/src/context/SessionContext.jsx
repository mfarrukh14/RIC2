import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { sessionApi } from '../services/sessionApi';
import { SESSION_STORAGE_KEY } from '../services/httpAuth';

const SessionContext = createContext(null);

export const SessionProvider = ({ children }) => {
  const [session, setSession] = useState(null);
  const [initializing, setInitializing] = useState(true);
  const [error, setError] = useState(null);

  // On mount, try to restore a previous debug login (e.g. after a page refresh).
  // If the server cache no longer has it (e.g. API restarted), fall back to the login screen.
  useEffect(() => {
    const storedUserId = localStorage.getItem(SESSION_STORAGE_KEY);
    if (!storedUserId) {
      setInitializing(false);
      return;
    }

    sessionApi.getSession(storedUserId)
      .then((data) => setSession(data))
      .catch(() => {
        localStorage.removeItem(SESSION_STORAGE_KEY);
      })
      .finally(() => setInitializing(false));
  }, []);

  const login = useCallback(async (userId) => {
    setError(null);
    try {
      const data = await sessionApi.login(userId);
      localStorage.setItem(SESSION_STORAGE_KEY, String(userId));
      setSession(data);
      return data;
    } catch (err) {
      setError(err?.response?.data?.message || 'Login failed');
      throw err;
    }
  }, []);

  const logout = useCallback(async () => {
    const userId = session?.userId;
    localStorage.removeItem(SESSION_STORAGE_KEY);
    setSession(null);
    if (userId) {
      try {
        await sessionApi.logout(userId);
      } catch {
        // Local state is already cleared; nothing more to do if the server call fails.
      }
    }
  }, [session]);

  return (
    <SessionContext.Provider value={{ session, initializing, error, login, logout }}>
      {children}
    </SessionContext.Provider>
  );
};

export const useSession = () => {
  const ctx = useContext(SessionContext);
  if (!ctx) {
    throw new Error('useSession must be used within a SessionProvider');
  }
  return ctx;
};
