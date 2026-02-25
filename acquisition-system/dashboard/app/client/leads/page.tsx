'use client';

import { useState } from 'react';

export default function LeadsPage() {
  const [filter, setFilter] = useState('all');
  const [search, setSearch] = useState('');

  const leads = [
    {
      id: 1,
      company: 'Precision Metal Fabrication',
      industry: 'Manufacturing',
      location: 'Atlanta, GA',
      score: 92,
      revenue: '$8-12M',
      owner: { name: 'John Smith', age: 68, tenure: 29 },
      email: 'jsmith@precisionmetal.com',
      phone: '(404) 555-0123',
      signals: ['Age 65+', 'Tenure 20+', 'Website Stale', 'No Social'],
      addedDate: '2026-02-20',
      status: 'New',
    },
    {
      id: 2,
      company: 'Industrial HVAC Services',
      industry: 'HVAC',
      location: 'Charlotte, NC',
      score: 88,
      revenue: '$5-8M',
      owner: { name: 'Mary Johnson', age: 66, tenure: 25 },
      email: 'mjohnson@industrialhvac.com',
      phone: '(704) 555-0456',
      signals: ['Age 65+', 'Tenure 20+', 'Digital Decay'],
      addedDate: '2026-02-19',
      status: 'Contacted',
    },
    {
      id: 3,
      company: 'Specialty Chemical Distribution',
      industry: 'Distribution',
      location: 'Nashville, TN',
      score: 86,
      revenue: '$12-18M',
      owner: { name: 'Robert Davis', age: 65, tenure: 28 },
      email: 'rdavis@chemicaldist.com',
      phone: '(615) 555-0789',
      signals: ['Age 65+', 'Tenure 20+', 'No Hires 3yr'],
      addedDate: '2026-02-18',
      status: 'Responded',
    },
    {
      id: 4,
      company: 'Electrical Contracting Co',
      industry: 'Construction',
      location: 'Raleigh, NC',
      score: 84,
      revenue: '$6-10M',
      owner: { name: 'Patricia Wilson', age: 67, tenure: 32 },
      email: 'pwilson@electricalco.com',
      phone: '(919) 555-0321',
      signals: ['Age 65+', 'Tenure 30+', 'Website Stale'],
      addedDate: '2026-02-17',
      status: 'New',
    },
    {
      id: 5,
      company: 'Commercial Printing Services',
      industry: 'Printing',
      location: 'Chattanooga, TN',
      score: 78,
      revenue: '$5-9M',
      owner: { name: 'Michael Brown', age: 66, tenure: 27 },
      email: 'mbrown@printservices.com',
      phone: '(423) 555-0654',
      signals: ['Age 65+', 'Tenure 20+', 'Declining Industry'],
      addedDate: '2026-02-16',
      status: 'Contacted',
    },
  ];

  const filteredLeads = leads.filter((lead) => {
    if (filter === 'hot' && lead.score < 80) return false;
    if (filter === 'warm' && (lead.score < 60 || lead.score >= 80)) return false;
    if (filter === 'new' && lead.status !== 'New') return false;
    if (filter === 'contacted' && lead.status !== 'Contacted') return false;
    if (search && !lead.company.toLowerCase().includes(search.toLowerCase())) return false;
    return true;
  });

  const [selectedLead, setSelectedLead] = useState<typeof leads[0] | null>(null);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Leads</h1>
          <p className="text-gray-600 mt-1">{filteredLeads.length} total leads</p>
        </div>
        <button className="bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 font-medium">
          Export to CSV
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
        <div className="flex flex-wrap gap-4">
          <div className="flex-1 min-w-[200px]">
            <input
              type="text"
              placeholder="Search companies..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            />
          </div>

          <div className="flex gap-2">
            {[
              { id: 'all', label: 'All Leads' },
              { id: 'hot', label: 'Hot (80+)' },
              { id: 'warm', label: 'Warm (60-79)' },
              { id: 'new', label: 'New' },
              { id: 'contacted', label: 'Contacted' },
            ].map((btn) => (
              <button
                key={btn.id}
                onClick={() => setFilter(btn.id)}
                className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                  filter === btn.id
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {btn.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Leads Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {filteredLeads.map((lead) => (
          <div
            key={lead.id}
            className="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow cursor-pointer"
            onClick={() => setSelectedLead(lead)}
          >
            {/* Header */}
            <div className="flex items-start justify-between mb-4">
              <div className="flex-1">
                <h3 className="text-lg font-semibold text-gray-900">{lead.company}</h3>
                <p className="text-sm text-gray-500">{lead.industry} • {lead.location}</p>
              </div>
              <span
                className={`px-3 py-1 rounded-full text-xs font-bold ${
                  lead.score >= 90
                    ? 'bg-red-100 text-red-800'
                    : lead.score >= 80
                    ? 'bg-orange-100 text-orange-800'
                    : lead.score >= 70
                    ? 'bg-yellow-100 text-yellow-800'
                    : 'bg-blue-100 text-blue-800'
                }`}
              >
                Score: {lead.score}
              </span>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div>
                <p className="text-xs text-gray-500">Revenue</p>
                <p className="text-sm font-semibold text-gray-900">{lead.revenue}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500">Owner</p>
                <p className="text-sm font-semibold text-gray-900">{lead.owner.name}, {lead.owner.age}</p>
              </div>
            </div>

            {/* Signals */}
            <div className="mb-4">
              <p className="text-xs text-gray-500 mb-2">Retirement Signals:</p>
              <div className="flex flex-wrap gap-1">
                {lead.signals.map((signal) => (
                  <span
                    key={signal}
                    className="px-2 py-1 bg-indigo-50 text-indigo-700 text-xs rounded"
                  >
                    {signal}
                  </span>
                ))}
              </div>
            </div>

            {/* Footer */}
            <div className="flex items-center justify-between pt-4 border-t border-gray-200">
              <span
                className={`px-2 py-1 text-xs font-medium rounded-full ${
                  lead.status === 'New'
                    ? 'bg-blue-100 text-blue-700'
                    : lead.status === 'Contacted'
                    ? 'bg-yellow-100 text-yellow-700'
                    : 'bg-green-100 text-green-700'
                }`}
              >
                {lead.status}
              </span>
              <button className="text-indigo-600 hover:text-indigo-900 text-sm font-medium">
                View Details →
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Lead Detail Modal */}
      {selectedLead && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-3xl w-full max-h-[90vh] overflow-y-auto">
            {/* Modal Header */}
            <div className="p-6 border-b border-gray-200 flex items-start justify-between">
              <div>
                <h2 className="text-2xl font-bold text-gray-900">{selectedLead.company}</h2>
                <p className="text-gray-600">{selectedLead.industry} • {selectedLead.location}</p>
              </div>
              <button
                onClick={() => setSelectedLead(null)}
                className="text-gray-400 hover:text-gray-600"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 space-y-6">
              {/* Retirement Score */}
              <div className="bg-gradient-to-r from-indigo-50 to-purple-50 p-6 rounded-lg">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold text-gray-900">Retirement Likelihood</h3>
                  <span className="text-4xl font-bold text-indigo-600">{selectedLead.score}/100</span>
                </div>
                <div className="space-y-2">
                  {selectedLead.signals.map((signal) => (
                    <div key={signal} className="flex items-center">
                      <svg className="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                      </svg>
                      <span className="text-sm text-gray-700">{signal}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Owner Info */}
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-3">Owner Information</h3>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-gray-500">Name</p>
                    <p className="text-base font-medium text-gray-900">{selectedLead.owner.name}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Age</p>
                    <p className="text-base font-medium text-gray-900">{selectedLead.owner.age} years</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Tenure</p>
                    <p className="text-base font-medium text-gray-900">{selectedLead.owner.tenure} years</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Email</p>
                    <p className="text-base font-medium text-indigo-600">{selectedLead.email}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Phone</p>
                    <p className="text-base font-medium text-gray-900">{selectedLead.phone}</p>
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">Revenue</p>
                    <p className="text-base font-medium text-gray-900">{selectedLead.revenue}</p>
                  </div>
                </div>
              </div>

              {/* Actions */}
              <div className="flex gap-3">
                <button className="flex-1 bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 font-medium">
                  Start Outreach Campaign
                </button>
                <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium">
                  Mark as Contacted
                </button>
                <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium">
                  Add Note
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
