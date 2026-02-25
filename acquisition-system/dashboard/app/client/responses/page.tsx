'use client';

export default function ResponsesPage() {
  const responses = [
    {
      id: 1,
      company: 'Precision Metal Fabrication',
      owner: 'John Smith',
      subject: 'RE: Exploring partnership opportunities',
      preview: "Thanks for reaching out. I've been thinking about succession planning. Would love to talk more...",
      sentiment: 'Positive',
      received: '2 hours ago',
      status: 'Unread',
      campaign: 'Manufacturing Southeast Q1',
    },
    {
      id: 2,
      company: 'Industrial HVAC Services',
      owner: 'Mary Johnson',
      subject: 'RE: Strategic conversation',
      preview: 'Interesting timing. Can we schedule a call next week? Tuesdays work best for me.',
      sentiment: 'Interested',
      received: '5 hours ago',
      status: 'Read',
      campaign: 'HVAC Services Regional',
    },
    {
      id: 3,
      company: 'Specialty Chemical Distribution',
      owner: 'Robert Davis',
      subject: 'RE: Business transition discussion',
      preview: "Not looking to sell right now, but happy to stay in touch. Let's connect in 6 months.",
      sentiment: 'Neutral',
      received: '1 day ago',
      status: 'Replied',
      campaign: 'Distribution Companies Test',
    },
    {
      id: 4,
      company: 'Electrical Contracting Co',
      owner: 'Patricia Wilson',
      subject: 'RE: Confidential inquiry',
      preview: 'Yes, this is something I\'ve been considering. What\'s your timeline and approach?',
      sentiment: 'Very Interested',
      received: '2 days ago',
      status: 'Meeting Scheduled',
      campaign: 'Manufacturing Southeast Q1',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Responses</h1>
          <p className="text-gray-600 mt-1">{responses.length} total responses</p>
        </div>
        <div className="flex gap-2">
          <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium">
            Mark All Read
          </button>
          <button className="bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 font-medium">
            Compose Reply
          </button>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="bg-white border-b border-gray-200">
        <nav className="flex space-x-8 px-6">
          {['All', 'Unread', 'Interested', 'Meetings', 'Not Interested'].map((tab) => (
            <button
              key={tab}
              className={`py-4 px-1 border-b-2 font-medium text-sm ${
                tab === 'All'
                  ? 'border-indigo-600 text-indigo-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              {tab}
            </button>
          ))}
        </nav>
      </div>

      {/* Responses List */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        {responses.map((response) => (
          <div
            key={response.id}
            className="p-6 border-b border-gray-200 hover:bg-gray-50 cursor-pointer transition-colors"
          >
            {/* Response Header */}
            <div className="flex items-start justify-between mb-3">
              <div className="flex-1">
                <div className="flex items-center gap-3 mb-1">
                  <h3 className="text-lg font-semibold text-gray-900">{response.company}</h3>
                  <span
                    className={`px-2 py-1 rounded-full text-xs font-medium ${
                      response.sentiment === 'Very Interested'
                        ? 'bg-green-100 text-green-700'
                        : response.sentiment === 'Interested'
                        ? 'bg-blue-100 text-blue-700'
                        : response.sentiment === 'Positive'
                        ? 'bg-yellow-100 text-yellow-700'
                        : 'bg-gray-100 text-gray-700'
                    }`}
                  >
                    {response.sentiment}
                  </span>
                  <span
                    className={`px-2 py-1 rounded-full text-xs font-medium ${
                      response.status === 'Unread'
                        ? 'bg-red-100 text-red-700'
                        : response.status === 'Meeting Scheduled'
                        ? 'bg-purple-100 text-purple-700'
                        : 'bg-gray-100 text-gray-600'
                    }`}
                  >
                    {response.status}
                  </span>
                </div>
                <p className="text-sm text-gray-600">
                  {response.owner} • {response.campaign}
                </p>
              </div>
              <span className="text-sm text-gray-500">{response.received}</span>
            </div>

            {/* Response Content */}
            <div className="mb-3">
              <p className="text-sm font-medium text-gray-900 mb-1">{response.subject}</p>
              <p className="text-sm text-gray-600">{response.preview}</p>
            </div>

            {/* Actions */}
            <div className="flex items-center gap-3">
              <button className="text-indigo-600 hover:text-indigo-900 text-sm font-medium">
                Reply
              </button>
              <button className="text-gray-600 hover:text-gray-900 text-sm font-medium">
                Schedule Meeting
              </button>
              <button className="text-gray-600 hover:text-gray-900 text-sm font-medium">
                Add to CRM
              </button>
              <button className="text-gray-600 hover:text-gray-900 text-sm font-medium ml-auto">
                Archive
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <p className="text-sm text-gray-600 mb-1">Response Rate</p>
          <p className="text-3xl font-bold text-gray-900">11.2%</p>
          <p className="text-xs text-green-600 mt-1">+2.1% vs last month</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <p className="text-sm text-gray-600 mb-1">Interested Leads</p>
          <p className="text-3xl font-bold text-gray-900">12</p>
          <p className="text-xs text-green-600 mt-1">+4 this week</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <p className="text-sm text-gray-600 mb-1">Meetings Booked</p>
          <p className="text-3xl font-bold text-gray-900">7</p>
          <p className="text-xs text-green-600 mt-1">+3 this week</p>
        </div>
        <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
          <p className="text-sm text-gray-600 mb-1">Avg Response Time</p>
          <p className="text-3xl font-bold text-gray-900">18h</p>
          <p className="text-xs text-gray-600 mt-1">Target: <24h</p>
        </div>
      </div>
    </div>
  );
}
