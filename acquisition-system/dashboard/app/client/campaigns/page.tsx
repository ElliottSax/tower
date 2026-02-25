'use client';

export default function CampaignsPage() {
  const campaigns = [
    {
      id: 1,
      name: 'Manufacturing Southeast Q1',
      status: 'Active',
      sent: 47,
      delivered: 45,
      opened: 19,
      replied: 5,
      interested: 2,
      openRate: '42.2%',
      replyRate: '11.1%',
      startDate: '2026-02-01',
      template: 'Manufacturing Personalized V2',
    },
    {
      id: 2,
      name: 'HVAC Services Regional',
      status: 'Active',
      sent: 33,
      delivered: 32,
      opened: 14,
      replied: 4,
      interested: 1,
      openRate: '43.8%',
      replyRate: '12.5%',
      startDate: '2026-02-05',
      template: 'Service Business Template',
    },
    {
      id: 3,
      name: 'Distribution Companies Test',
      status: 'Completed',
      sent: 25,
      delivered: 24,
      opened: 11,
      replied: 3,
      interested: 1,
      openRate: '45.8%',
      replyRate: '12.5%',
      startDate: '2026-01-15',
      template: 'Distribution Focused',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Outreach Campaigns</h1>
          <p className="text-gray-600 mt-1">{campaigns.length} total campaigns</p>
        </div>
        <button className="bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 font-medium">
          + New Campaign
        </button>
      </div>

      {/* Campaign Cards */}
      <div className="space-y-4">
        {campaigns.map((campaign) => (
          <div key={campaign.id} className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
            {/* Campaign Header */}
            <div className="flex items-start justify-between mb-4">
              <div>
                <h3 className="text-lg font-semibold text-gray-900">{campaign.name}</h3>
                <p className="text-sm text-gray-500 mt-1">
                  Started {new Date(campaign.startDate).toLocaleDateString()} • {campaign.template}
                </p>
              </div>
              <span
                className={`px-3 py-1 rounded-full text-xs font-medium ${
                  campaign.status === 'Active'
                    ? 'bg-green-100 text-green-700'
                    : 'bg-gray-100 text-gray-700'
                }`}
              >
                {campaign.status}
              </span>
            </div>

            {/* Stats Grid */}
            <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-4">
              <div className="text-center">
                <p className="text-2xl font-bold text-gray-900">{campaign.sent}</p>
                <p className="text-xs text-gray-500">Sent</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-gray-900">{campaign.delivered}</p>
                <p className="text-xs text-gray-500">Delivered</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-indigo-600">{campaign.opened}</p>
                <p className="text-xs text-gray-500">Opened</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-green-600">{campaign.replied}</p>
                <p className="text-xs text-gray-500">Replied</p>
              </div>
              <div className="text-center">
                <p className="text-2xl font-bold text-purple-600">{campaign.interested}</p>
                <p className="text-xs text-gray-500">Interested</p>
              </div>
            </div>

            {/* Performance Metrics */}
            <div className="flex items-center gap-6 pt-4 border-t border-gray-200">
              <div>
                <p className="text-xs text-gray-500">Open Rate</p>
                <p className="text-lg font-semibold text-gray-900">{campaign.openRate}</p>
              </div>
              <div>
                <p className="text-xs text-gray-500">Reply Rate</p>
                <p className="text-lg font-semibold text-green-600">{campaign.replyRate}</p>
              </div>
              <div className="ml-auto">
                <button className="text-indigo-600 hover:text-indigo-900 text-sm font-medium mr-4">
                  View Details
                </button>
                <button className="text-gray-600 hover:text-gray-900 text-sm font-medium">
                  Export
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Campaign Templates */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Available Templates</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[
            { name: 'Manufacturing Personalized V2', usage: 47, performance: '11.1%' },
            { name: 'Service Business Template', usage: 33, performance: '12.5%' },
            { name: 'Distribution Focused', usage: 25, performance: '12.5%' },
          ].map((template) => (
            <div key={template.name} className="p-4 border border-gray-200 rounded-lg hover:border-indigo-300 cursor-pointer">
              <h3 className="font-medium text-gray-900 mb-2">{template.name}</h3>
              <div className="flex items-center justify-between text-sm">
                <span className="text-gray-500">{template.usage} sent</span>
                <span className="text-green-600 font-medium">{template.performance} reply</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
