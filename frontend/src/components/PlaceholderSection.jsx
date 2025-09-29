import React from 'react';

const PlaceholderSection = ({ title, description, icon: Icon }) => {
  return (
    <div className="flex flex-col items-center justify-center h-full min-h-96 bg-gray-50 rounded-lg border-2 border-dashed border-gray-300">
      <div className="text-center p-8">
        {Icon && <Icon className="w-16 h-16 text-gray-400 mx-auto mb-4" />}
        <h2 className="text-2xl font-bold text-gray-900 mb-2">{title}</h2>
        {description && (
          <p className="text-gray-600 mb-4 max-w-md">{description}</p>
        )}
        <div className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm bg-white text-sm font-medium text-gray-700">
          Coming Soon
        </div>
      </div>
    </div>
  );
};

export default PlaceholderSection;