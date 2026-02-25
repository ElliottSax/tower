'use client';

export default function SettingsPage() {
  return (
    <div className="space-y-6 max-w-4xl">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Settings</h1>
        <p className="text-gray-600 mt-1">Manage your account and preferences</p>
      </div>

      {/* Account Information */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Account Information</h2>
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Company Name</label>
              <input
                type="text"
                defaultValue="Search Fund Alpha"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Contact Email</label>
              <input
                type="email"
                defaultValue="john@searchfundalpha.com"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
              />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
            <input
              type="tel"
              defaultValue="+1 (415) 555-0123"
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
            />
          </div>

          <button className="bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 font-medium">
            Save Changes
          </button>
        </div>
      </div>

      {/* Subscription Plan */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Subscription Plan</h2>
        <div className="bg-gradient-to-r from-indigo-50 to-purple-50 p-4 rounded-lg mb-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-lg font-semibold text-gray-900">Professional Tier</p>
              <p className="text-sm text-gray-600">$15,000/month</p>
            </div>
            <span className="px-3 py-1 bg-green-100 text-green-700 rounded-full text-sm font-medium">
              Active
            </span>
          </div>
        </div>

        <div className="space-y-2 mb-4">
          <div className="flex items-center text-sm text-gray-700">
            <svg className="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            100 qualified leads per month
          </div>
          <div className="flex items-center text-sm text-gray-700">
            <svg className="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            20 AI-powered outreach campaigns per month
          </div>
          <div className="flex items-center text-sm text-gray-700">
            <svg className="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            Dedicated account manager
          </div>
          <div className="flex items-center text-sm text-gray-700">
            <svg className="w-5 h-5 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            Weekly pipeline reviews
          </div>
        </div>

        <div className="flex gap-2">
          <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium">
            Upgrade Plan
          </button>
          <button className="px-4 py-2 text-gray-600 hover:text-gray-900 font-medium">
            View Billing History
          </button>
        </div>
      </div>

      {/* Search Criteria */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Search Criteria</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Industries</label>
            <div className="flex flex-wrap gap-2">
              {['Manufacturing', 'Services', 'Distribution', 'Construction', 'Healthcare'].map((industry) => (
                <button
                  key={industry}
                  className="px-3 py-1 bg-indigo-100 text-indigo-700 rounded-full text-sm font-medium hover:bg-indigo-200"
                >
                  {industry} ✕
                </button>
              ))}
              <button className="px-3 py-1 border-2 border-dashed border-gray-300 text-gray-600 rounded-full text-sm font-medium hover:border-gray-400">
                + Add Industry
              </button>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Geographic Focus</label>
            <div className="flex flex-wrap gap-2">
              {['Southeast', 'Texas', 'California', 'Northeast'].map((region) => (
                <button
                  key={region}
                  className="px-3 py-1 bg-indigo-100 text-indigo-700 rounded-full text-sm font-medium hover:bg-indigo-200"
                >
                  {region} ✕
                </button>
              ))}
              <button className="px-3 py-1 border-2 border-dashed border-gray-300 text-gray-600 rounded-full text-sm font-medium hover:border-gray-400">
                + Add Region
              </button>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Min Revenue</label>
              <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500">
                <option>$1M</option>
                <option selected>$5M</option>
                <option>$10M</option>
                <option>$25M</option>
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Max Revenue</label>
              <select className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500">
                <option>$10M</option>
                <option selected>$25M</option>
                <option>$50M</option>
                <option>$100M+</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Minimum Retirement Score</label>
            <input
              type="range"
              min="50"
              max="90"
              defaultValue="70"
              className="w-full"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>50 (Warm)</span>
              <span className="font-medium text-indigo-600">70 (Hot)</span>
              <span>90 (Very Hot)</span>
            </div>
          </div>

          <button className="bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 font-medium">
            Update Criteria
          </button>
        </div>
      </div>

      {/* Notifications */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Notifications</h2>
        <div className="space-y-3">
          {[
            { label: 'New hot leads (score 80+)', checked: true },
            { label: 'Email responses', checked: true },
            { label: 'Campaign performance updates', checked: true },
            { label: 'Weekly summary report', checked: false },
            { label: 'Monthly analytics digest', checked: true },
          ].map((notif) => (
            <label key={notif.label} className="flex items-center">
              <input
                type="checkbox"
                defaultChecked={notif.checked}
                className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
              />
              <span className="ml-3 text-sm text-gray-700">{notif.label}</span>
            </label>
          ))}
        </div>
      </div>

      {/* Danger Zone */}
      <div className="bg-white rounded-lg shadow-sm border border-red-200 p-6">
        <h2 className="text-lg font-semibold text-red-900 mb-4">Danger Zone</h2>
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-900">Pause Subscription</p>
              <p className="text-xs text-gray-500">Temporarily pause lead delivery and campaigns</p>
            </div>
            <button className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 font-medium">
              Pause
            </button>
          </div>
          <div className="flex items-center justify-between pt-3 border-t border-gray-200">
            <div>
              <p className="text-sm font-medium text-red-900">Cancel Subscription</p>
              <p className="text-xs text-gray-500">Permanently cancel your DealSourceAI account</p>
            </div>
            <button className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 font-medium">
              Cancel
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
