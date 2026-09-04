import React, { useEffect, useState } from 'react';
import { InformationCircleIcon, PlusIcon, XMarkIcon } from '@heroicons/react/24/outline';
import pharmacyApi from '../services/pharmacyApi';
import Pagination from '../components/Pagination';
import usePagedList from '../hooks/usePagedList';

function formatDateTime(value) {
  if (!value) return '-';
  return new Date(value).toLocaleString('en-US', {
    month: 'short', day: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: false
  });
}

function useDebouncedValue(value, delayMs) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const handle = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(handle);
  }, [value, delayMs]);
  return debounced;
}

const ImmunizationPage = () => {
  const [vaccines, setVaccines] = useState([]);
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [error, setError] = useState('');

  const {
    items: pageItems,
    totalCount,
    currentPage,
    pageSize: entriesPerPage,
    setPageSize: setEntriesPerPage,
    goToPage,
    search: runSearch,
    loading,
    error: loadError,
    reload: reloadRecords,
  } = usePagedList(pharmacyApi.getVaccineRecords, {}, { autoLoad: false, initialPageSize: 10 });

  const [showAddModal, setShowAddModal] = useState(false);
  const [patientQuery, setPatientQuery] = useState('');
  const [patientResults, setPatientResults] = useState([]);
  const [selectedPatient, setSelectedPatient] = useState(null);
  const [vaccineId, setVaccineId] = useState('');
  const [vaccinationDate, setVaccinationDate] = useState('');
  const [remarks, setRemarks] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const debouncedPatientQuery = useDebouncedValue(patientQuery, 300);

  useEffect(() => {
    pharmacyApi.getVaccines()
      .then(setVaccines)
      .catch((vaccineError) => console.error('Error loading vaccines:', vaccineError));
    runSearch({ dateFrom: undefined, dateTo: undefined });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!debouncedPatientQuery || debouncedPatientQuery.trim().length < 2 || selectedPatient) {
      setPatientResults([]);
      return;
    }

    let cancelled = false;
    pharmacyApi.searchPatients(debouncedPatientQuery.trim())
      .then((results) => { if (!cancelled) setPatientResults(results); })
      .catch((searchError) => console.error('Error searching patients:', searchError));
    return () => { cancelled = true; };
  }, [debouncedPatientQuery, selectedPatient]);

  const loadRecords = () => {
    setError('');
    runSearch({ dateFrom: dateFrom || undefined, dateTo: dateTo || undefined });
  };

  const closeAddModal = () => {
    setShowAddModal(false);
    setPatientQuery('');
    setPatientResults([]);
    setSelectedPatient(null);
    setVaccineId('');
    setVaccinationDate('');
    setRemarks('');
  };

  const handleAddRecord = async () => {
    if (!selectedPatient || !vaccineId) {
      setError('Select a patient and a vaccine.');
      return;
    }

    setSubmitting(true);
    setError('');

    try {
      await pharmacyApi.createVaccineRecord({
        patientId: selectedPatient.patientId,
        vaccineId: Number(vaccineId),
        vaccinationDate: vaccinationDate || null,
        remarks: remarks || null
      });
      closeAddModal();
      await reloadRecords();
    } catch (addError) {
      console.error('Error adding immunization record:', addError);
      setError(addError.response?.data?.message || 'Failed to add the immunization record.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-100 p-0 sm:p-1">
      <div className="space-y-3">
        <section className="rounded-md border border-slate-200 bg-white shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-100 px-6 py-3">
            <h1 className="flex items-center gap-2 text-2xl font-semibold text-slate-900">
              Immunization
              <InformationCircleIcon className="h-5 w-5 text-indigo-500" />
            </h1>
            <button
              type="button"
              onClick={() => setShowAddModal(true)}
              className="inline-flex items-center gap-2 rounded-md bg-indigo-600 px-4 py-2 text-sm font-medium text-white transition hover:bg-indigo-700"
            >
              <PlusIcon className="h-4 w-4" /> Add Record
            </button>
          </div>

          {(error || loadError) && (
            <div className="px-6 pt-4 text-sm text-rose-600">
              {error || `Failed to load immunization records${loadError.message ? `: ${loadError.message}` : ''}`}
            </div>
          )}

          <div className="grid grid-cols-1 gap-4 px-6 py-5 lg:grid-cols-3">
            <div>
              <label className="mb-2 block text-sm font-medium text-slate-700">Date Range</label>
              <div className="flex items-center gap-2">
                <input type="date" value={dateFrom} onChange={(event) => setDateFrom(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-indigo-400" />
                <input type="date" value={dateTo} onChange={(event) => setDateTo(event.target.value)} className="w-full rounded-md border border-slate-200 px-3 py-2.5 text-sm outline-none focus:border-indigo-400" />
              </div>
            </div>
            <div className="flex items-end">
              <button type="button" onClick={loadRecords} className="rounded-md bg-indigo-600 px-6 py-2.5 text-sm font-medium text-white hover:bg-indigo-700">Search</button>
            </div>
          </div>

          <div className="overflow-x-auto px-6 pb-4">
            <table className="min-w-full border-separate border-spacing-0 text-sm">
              <thead>
                <tr className="text-left text-slate-700">
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Patient Name</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">MR No</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Vaccine</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Administration Date</th>
                  <th className="border-y border-slate-200 bg-white px-4 py-3 font-semibold">Remarks</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr><td colSpan="5" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">Loading...</td></tr>
                ) : pageItems.length === 0 ? (
                  <tr><td colSpan="5" className="border-b border-slate-200 px-4 py-10 text-center text-slate-500">No data available in table</td></tr>
                ) : (
                  pageItems.map((record) => (
                    <tr key={record.patientVaccineId} className="text-slate-700">
                      <td className="border-b border-slate-200 px-4 py-3">{record.patientName || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{record.mrNo || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{record.vaccineName || '-'}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{formatDateTime(record.vaccinationDate)}</td>
                      <td className="border-b border-slate-200 px-4 py-3">{record.remarks || '-'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <Pagination
            currentPage={currentPage}
            pageSize={entriesPerPage}
            totalCount={totalCount}
            onPageChange={goToPage}
            onPageSizeChange={setEntriesPerPage}
          />
        </section>
      </div>

      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4">
          <div className="w-full max-w-lg rounded-md bg-white shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4">
              <h3 className="text-lg font-semibold text-slate-900">Add Immunization Record</h3>
              <button type="button" onClick={closeAddModal} className="rounded-md p-2 text-slate-500 hover:bg-slate-100">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>

            <div className="space-y-4 px-6 py-5">
              <div className="relative">
                <label className="mb-2 block text-sm font-medium text-slate-700">Patient</label>
                {selectedPatient ? (
                  <div className="flex items-center justify-between rounded-md border border-slate-200 bg-slate-50 px-4 py-3 text-sm">
                    <span>{selectedPatient.mrNo} - {selectedPatient.name}</span>
                    <button type="button" onClick={() => setSelectedPatient(null)} className="text-slate-400 hover:text-slate-600">
                      <XMarkIcon className="h-4 w-4" />
                    </button>
                  </div>
                ) : (
                  <input
                    type="text"
                    value={patientQuery}
                    onChange={(event) => setPatientQuery(event.target.value)}
                    placeholder="MR No. or Name"
                    className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-indigo-400"
                  />
                )}
                {patientResults.length > 0 && (
                  <ul className="absolute z-10 mt-1 max-h-60 w-full overflow-y-auto rounded-md border border-slate-200 bg-white shadow-lg">
                    {patientResults.map((patient) => (
                      <li
                        key={patient.patientId}
                        onClick={() => { setSelectedPatient(patient); setPatientResults([]); }}
                        className="cursor-pointer px-4 py-2 text-sm hover:bg-indigo-50"
                      >
                        {patient.mrNo} - {patient.name}
                      </li>
                    ))}
                  </ul>
                )}
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Vaccine</label>
                <select value={vaccineId} onChange={(event) => setVaccineId(event.target.value)} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400">
                  <option value="">Select Vaccine</option>
                  {vaccines.map((vaccine) => <option key={vaccine.id} value={vaccine.id}>{vaccine.name}</option>)}
                </select>
                {vaccines.length === 0 && (
                  <p className="mt-1 text-xs text-amber-600">No vaccines configured yet - add one in the Vaccines master before recording immunizations.</p>
                )}
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Administration Date</label>
                <input type="date" value={vaccinationDate} onChange={(event) => setVaccinationDate(event.target.value)} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
              </div>

              <div>
                <label className="mb-2 block text-sm font-medium text-slate-700">Remarks</label>
                <textarea value={remarks} onChange={(event) => setRemarks(event.target.value)} rows={2} className="w-full rounded-md border border-slate-200 px-4 py-3 text-sm outline-none focus:border-indigo-400" />
              </div>

              <div className="flex justify-end">
                <button
                  type="button"
                  onClick={handleAddRecord}
                  disabled={submitting}
                  className="rounded-md bg-indigo-600 px-6 py-3 text-sm font-medium text-white transition hover:bg-indigo-700 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  {submitting ? 'Saving...' : 'Save'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ImmunizationPage;
