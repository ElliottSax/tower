'use client';

import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export default function ClientDashboard() {
  const stats = [
    { label: 'Total Leads', value: '847', change: '+12%', trend: 'up', icon: '🎯' },
    { label: 'Hot Leads (70+)', value: '127', change: '+8%', trend: 'up', icon: '🔥' },
    { label: 'Outreach Sent', value: '240', change: '+24', trend: 'up', icon: '📧' },
    { label: 'Response Rate', value: '11.2%', change: '+2.1%', trend: 'up', icon: '💬' },
  ];

  const responseData = [
    { month: 'Oct', responses: 8, meetings: 2 },
    { month: 'Nov', responses: 12, meetings: 3 },
    { month: 'Dec', responses: 15, meetings: 5 },
    { month: 'Jan', responses: 22, meetings: 7 },
    { month: 'Feb', responses: 27, meetings: 9 },
  ];

  const scoreDistribution = [
    { score: '90-100', count: 23 },
    { score: '80-89', count: 47 },
    { score: '70-79', count: 57 },
    { score: '60-69', count: 112 },
    { score: '50-59', count: 203 },
  ];

  const recentLeads = [
    {
      id: 1,
      company: 'Precision Metal Fabrication',
      location: 'Atlanta, GA',
      score: 92,
      revenue: '$8-12M',
      industry: 'Manufacturing',
      owner: 'John Smith, 68',
      status: 'New',
    },
    {
      id: 2,
      company: 'Industrial HVAC Services',
      location: 'Charlotte, NC',
      score: 88,
      revenue: '$5-8M',
      industry: 'HVAC',
      owner: 'Mary Johnson, 66',
      status: 'Contacted',
    },
    {
      id: 3,
      company: 'Specialty Chemical Distribution',
      location: 'Nashville, TN',
      score: 86,
      revenue: '$12-18M',
      industry: 'Distribution',
      owner: 'Robert Davis, 65',
      status: 'Responded',
    },
  ];

  const activities = [
    { type: 'response', text: 'New response from Precision Metal Fabrication', time: '2 hours ago', status: 'success' },
    { type: 'outreach', text: 'Outreach campaign sent to 20 new leads', time: '5 hours ago', status: 'info' },
    { type: 'leads', text: '50 new hot leads added to your pipeline', time: '1 day ago', status: 'info' },
    { type: 'meeting', text: 'Meeting scheduled with Industrial HVAC Services', time: '2 days ago', status: 'success' },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
          <p className="text-gray-600 mt-1">Welcome back, Search Fund Alpha</p>
        </div>
        <button className="bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 font-medium">
          + New Campaign
        </button>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => (
          <div key={stat.label} className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between mb-2">
              <p className="text-sm font-medium text-gray-600">{stat.label}</p>
              <span className="text-2xl">{stat.icon}</span>
            </div>
            <div className="flex items-end justify-between">
              <p className="text-3xl font-bold text-gray-900">{stat.value}</p>
              <span className={`text-xs px-2 py-1 rounded ${stat.trend === 'up' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                {stat.change}
              </span>
            </div>
          </div>
        ))}
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Response Trend */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Response & Meeting Trend</h2>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={responseData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" stroke="#6b7280" />
              <YAxis stroke="#6b7280" />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="responses" stroke="#6366f1" strokeWidth={2} name="Responses" />
              <Line type="monotone" dataKey="meetings" stroke="#10b981" strokeWidth={2} name="Meetings" />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Score Distribution */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Retirement Score Distribution</h2>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={scoreDistribution}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="score" stroke="#6b7280" />
              <YAxis stroke="#6b7280" />
              <Tooltip />
              <Bar dataKey="count" fill="#6366f1" name="Leads" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Recent Hot Leads Table */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Recent Hot Leads (Score 70+)</h2>
          <a href="/client/leads" className="text-indigo-600 hover:text-indigo-700 text-sm font-medium">
            View All →
          </a>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Company</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Score</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Owner</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Revenue</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Action</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {recentLeads.map((lead) => (
                <tr key={lead.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4">
                    <div>
                      <p className="text-sm font-medium text-gray-900">{lead.company}</p>
                      <p className="text-xs text-gray-500">{lead.industry} • {lead.location}</p>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      lead.score >= 90 ? 'bg-red-100 text-red-800' : lead.score >= 80 ? 'bg-orange-100 text-orange-800' : 'bg-yellow-100 text-yellow-800'
                    }`}>
                      {lead.score}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-sm text-gray-900">{lead.owner}</td>
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">{lead.revenue}</td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
                      lead.status === 'New' ? 'bg-blue-100 text-blue-700' :
                      lead.status === 'Contacted' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-green-100 text-green-700'
                    }`}>
                      {lead.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <button className="text-indigo-600 hover:text-indigo-900 text-sm font-medium">View Details</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Activity Feed */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Recent Activity</h2>
        <div className="space-y-4">
          {activities.map((activity, idx) => (
            <div key={idx} className="flex items-start">
              <div className={`flex-shrink-0 w-2 h-2 rounded-full mt-2 ${
                activity.status === 'success' ? 'bg-green-500' : 'bg-blue-500'
              }`}></div>
              <div className="ml-4">
                <p className="text-sm text-gray-900">{activity.text}</p>
                <p className="text-xs text-gray-500 mt-1">{activity.time}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
