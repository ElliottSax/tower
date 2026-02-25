'use client';

import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export default function AnalyticsPage() {
  const monthlyTrend = [
    { month: 'Sep', leads: 421, responses: 31, meetings: 8 },
    { month: 'Oct', leads: 536, responses: 43, meetings: 11 },
    { month: 'Nov', leads: 678, responses: 61, meetings: 17 },
    { month: 'Dec', leads: 734, responses: 72, meetings: 21 },
    { month: 'Jan', leads: 812, responses: 89, meetings: 27 },
    { month: 'Feb', leads: 847, responses: 95, meetings: 31 },
  ];

  const industryBreakdown = [
    { name: 'Manufacturing', value: 234, color: '#6366f1' },
    { name: 'Services', value: 189, color: '#10b981' },
    { name: 'Distribution', value: 156, color: '#f59e0b' },
    { name: 'Construction', value: 143, color: '#ef4444' },
    { name: 'Healthcare', value: 125, color: '#8b5cf6' },
  ];

  const scoreRanges = [
    { range: '90-100', count: 23, pct: '2.7%' },
    { range: '80-89', count: 47, pct: '5.5%' },
    { range: '70-79', count: 57, pct: '6.7%' },
    { range: '60-69', count: 112, pct: '13.2%' },
    { range: '50-59', count: 203, pct: '24.0%' },
    { range: '<50', count: 405, pct: '47.8%' },
  ];

  const campaignPerformance = [
    { campaign: 'Manufacturing SE Q1', sent: 47, replies: 5, rate: '10.6%', sentiment: 'Positive' },
    { campaign: 'HVAC Services Regional', sent: 33, replies: 4, rate: '12.1%', sentiment: 'Very Positive' },
    { campaign: 'Distribution Test', sent: 25, replies: 3, rate: '12.0%', sentiment: 'Positive' },
    { campaign: 'Construction Q4', sent: 18, replies: 1, rate: '5.6%', sentiment: 'Neutral' },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Analytics</h1>
          <p className="text-gray-600 mt-1">Performance insights and trends</p>
        </div>
        <div className="flex gap-2">
          <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium">
            Last 30 Days
          </button>
          <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium">
            Export Report
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {[
          { label: 'Total Leads', value: '847', change: '+3.9%', icon: '🎯' },
          { label: 'Qualified (70+)', value: '127', change: '+12.4%', icon: '⭐' },
          { label: 'Outreach Sent', value: '123', change: '+8.8%', icon: '📧' },
          { label: 'Meetings Booked', value: '31', change: '+24.0%', icon: '📅' },
        ].map((kpi) => (
          <div key={kpi.label} className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
            <div className="flex items-center justify-between mb-2">
              <p className="text-sm text-gray-600">{kpi.label}</p>
              <span className="text-2xl">{kpi.icon}</span>
            </div>
            <p className="text-3xl font-bold text-gray-900">{kpi.value}</p>
            <p className="text-xs text-green-600 mt-1">{kpi.change} vs last month</p>
          </div>
        ))}
      </div>

      {/* Charts Row 1 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Monthly Trend */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Growth Trend</h2>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={monthlyTrend}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="month" stroke="#6b7280" />
              <YAxis stroke="#6b7280" />
              <Tooltip />
              <Legend />
              <Line type="monotone" dataKey="leads" stroke="#6366f1" strokeWidth={2} name="Total Leads" />
              <Line type="monotone" dataKey="responses" stroke="#10b981" strokeWidth={2} name="Responses" />
              <Line type="monotone" dataKey="meetings" stroke="#f59e0b" strokeWidth={2} name="Meetings" />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Industry Breakdown */}
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Industry Distribution</h2>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={industryBreakdown}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                outerRadius={100}
                fill="#8884d8"
                dataKey="value"
              >
                {industryBreakdown.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Score Distribution */}
      <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Retirement Score Distribution</h2>
        <div className="grid grid-cols-2 md:grid-cols-6 gap-4">
          {scoreRanges.map((range) => (
            <div key={range.range} className="text-center p-4 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-600 mb-1">Score {range.range}</p>
              <p className="text-2xl font-bold text-gray-900">{range.count}</p>
              <p className="text-xs text-gray-500">{range.pct}</p>
            </div>
          ))}
        </div>
      </div>

      {/* Campaign Performance */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900">Campaign Performance</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Campaign</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Sent</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Replies</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Reply Rate</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Sentiment</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {campaignPerformance.map((campaign) => (
                <tr key={campaign.campaign} className="hover:bg-gray-50">
                  <td className="px-6 py-4 text-sm font-medium text-gray-900">{campaign.campaign}</td>
                  <td className="px-6 py-4 text-sm text-gray-600">{campaign.sent}</td>
                  <td className="px-6 py-4 text-sm font-medium text-indigo-600">{campaign.replies}</td>
                  <td className="px-6 py-4">
                    <span className="text-sm font-semibold text-green-600">{campaign.rate}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                      campaign.sentiment === 'Very Positive' ? 'bg-green-100 text-green-700' :
                      campaign.sentiment === 'Positive' ? 'bg-blue-100 text-blue-700' :
                      'bg-gray-100 text-gray-700'
                    }`}>
                      {campaign.sentiment}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Insights */}
      <div className="bg-gradient-to-r from-indigo-50 to-purple-50 p-6 rounded-lg border border-indigo-200">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">📊 Key Insights</h2>
        <div className="space-y-3">
          <div className="flex items-start">
            <svg className="w-5 h-5 text-green-500 mr-2 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            <p className="text-sm text-gray-700">
              <strong>Reply rate up 24%</strong> - Your personalized HVAC campaign is performing exceptionally well
            </p>
          </div>
          <div className="flex items-start">
            <svg className="w-5 h-5 text-blue-500 mr-2 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
            </svg>
            <p className="text-sm text-gray-700">
              <strong>127 hot leads</strong> (score 70+) ready for outreach - highest quality pipeline yet
            </p>
          </div>
          <div className="flex items-start">
            <svg className="w-5 h-5 text-yellow-500 mr-2 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
            </svg>
            <p className="text-sm text-gray-700">
              <strong>Construction campaign underperforming</strong> - consider refreshing messaging or pausing
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
