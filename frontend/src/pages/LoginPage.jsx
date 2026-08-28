import React, { useEffect, useState } from 'react';
import { useSession } from '../context/SessionContext';
import { systemApi } from '../services/systemApi';

const DEBUG_USER_ID = 3;

const LoginPage = () => {
  const { login, error } = useSession();
  const [loggingIn, setLoggingIn] = useState(false);

  const [dbInfo, setDbInfo] = useState(null);
  const [dbLoading, setDbLoading] = useState(true);
  const [switching, setSwitching] = useState(false);
  const [dbError, setDbError] = useState(null);

  useEffect(() => {
    systemApi.getCurrentDatabase()
      .then(setDbInfo)
      .catch(() => setDbError('Could not reach the backend to check the active database.'))
      .finally(() => setDbLoading(false));
  }, []);

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

  const handleSwitchDatabase = async (database) => {
    if (switching || dbInfo?.selection === database) {
      return;
    }
    setSwitching(true);
    setDbError(null);
    try {
      await systemApi.switchDatabase(database);
      const updated = await systemApi.getCurrentDatabase();
      setDbInfo(updated);
    } catch {
      setDbError('Failed to switch database.');
    } finally {
      setSwitching(false);
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

        <div className="mt-6 border-t border-gray-200 pt-4 text-left">
          <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-400">
            Debug: Active Database
          </p>

          {dbLoading ? (
            <p className="text-xs text-gray-400">Checking active database...</p>
          ) : (
            <>
              <p className="mb-2 text-xs text-gray-500">
                Currently on <span className="font-mono font-medium text-gray-700">{dbInfo?.databaseName || 'unknown'}</span>.
                Switching affects every user connected to this backend.
              </p>
              <div className="flex gap-2">
                {(dbInfo?.availableDatabases || ['HMSMAIN_TF', 'IPPHMSLOCAL']).map((name) => {
                  const isActive = dbInfo?.selection === name;
                  return (
                    <button
                      key={name}
                      type="button"
                      onClick={() => handleSwitchDatabase(name)}
                      disabled={switching || isActive}
                      className={`flex-1 rounded-md border px-3 py-2 text-xs font-medium transition disabled:cursor-not-allowed ${
                        isActive
                          ? 'border-indigo-600 bg-indigo-50 text-indigo-700'
                          : 'border-gray-300 bg-white text-gray-600 hover:bg-gray-50'
                      }`}
                    >
                      {isActive ? `${name} (active)` : switching ? '...' : name}
                    </button>
                  );
                })}
              </div>
              {dbError && <p className="mt-2 text-xs text-rose-600">{dbError}</p>}
            </>
          )}
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
