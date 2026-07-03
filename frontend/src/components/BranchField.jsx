import React from 'react';
import { useSession } from '../context/SessionContext';

// Read-only display of the logged-in user's own branch. Use this in place of a
// branch <select> wherever the field represents the user's current working
// branch (i.e. "which branch is this record/action for"), NOT a genuine
// cross-branch selector such as "which other branch am I requesting stock from".
const BranchField = ({ label = 'Branch', className = '' }) => {
  const { session } = useSession();

  return (
    <div className={className}>
      <label className="mb-2 block text-sm font-medium text-slate-700">{label}</label>
      <input
        type="text"
        value={session?.branchName || ''}
        disabled
        readOnly
        title="Locked to your assigned branch"
        className="w-full cursor-not-allowed rounded-lg border border-slate-200 bg-slate-100 px-4 py-3 text-sm text-slate-600"
      />
    </div>
  );
};

export default BranchField;
