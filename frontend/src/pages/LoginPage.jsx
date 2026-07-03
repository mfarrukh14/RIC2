import React, { useState } from 'react';
import { useSession } from '../context/SessionContext';

const DEBUG_USER_ID = 3;

const LoginPage = () => {
  const { login, error } = useSession();
  const [loggingIn, setLoggingIn] = useState(false);

  const handleDebugLogin = async () => {
    setLoggingIn(true);
    try {
      await login(DEBUG_USER_ID);
    } catch {
      // error is surfaced via session context
    } finally {
      setLoggingIn(false);
    }
  };

  return (
    <div className="flex h-screen items-center justify-center bg-gray-100">
      <div className="w-full max-w-sm rounded-xl bg-white p-8 text-center shadow-lg">
        <h1 className="mb-1 text-xl font-bold text-gray-900">Inventory &amp; Store Management</h1>
        <p className="mb-6 text-sm text-gray-500">Sign in to continue</p>

        {error && <p className="mb-4 text-sm text-rose-600">{error}</p>}

        <button
          type="button"
          onClick={handleDebugLogin}
          disabled={loggingIn}
          className="w-full rounded-lg bg-indigo-600 px-4 py-3 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {loggingIn ? 'Logging in...' : `Debug Login (User ${DEBUG_USER_ID})`}
        </button>
      </div>
    </div>
  );
};

export default LoginPage;
