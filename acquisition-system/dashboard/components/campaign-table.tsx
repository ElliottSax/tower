"use client";

import { useQuery } from "@tanstack/react-query";
import { getCampaignStats } from "@/lib/api";

function StatusBadge({ status }: { status: string }) {
  const styles: Record<string, string> = {
    active: "bg-accent-green/20 text-accent-green",
    paused: "bg-accent-warm/20 text-accent-warm",
    completed: "bg-text-secondary/20 text-text-secondary",
    draft: "bg-accent-blue/20 text-accent-blue",
  };

  return (
    <span
      className={`text-xs px-2 py-0.5 rounded font-medium ${styles[status] || styles.draft}`}
    >
      {status}
    </span>
  );
}

export function CampaignTable() {
  const { data, isLoading } = useQuery({
    queryKey: ["campaignStats"],
    queryFn: getCampaignStats,
  });

  return (
    <div className="bg-bg-card border border-border-primary rounded-lg overflow-hidden mb-6">
      <div className="px-4 py-3 border-b border-border-primary">
        <h2 className="font-semibold text-text-primary">
          Campaign Performance
        </h2>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border-primary text-text-secondary text-left">
              <th className="py-2 px-4 font-medium">Campaign</th>
              <th className="py-2 px-4 font-medium">Status</th>
              <th className="py-2 px-4 font-medium text-right">Sent</th>
              <th className="py-2 px-4 font-medium text-right">Delivered</th>
              <th className="py-2 px-4 font-medium text-right">Opened</th>
              <th className="py-2 px-4 font-medium text-right">Open Rate</th>
              <th className="py-2 px-4 font-medium text-right">Replied</th>
              <th className="py-2 px-4 font-medium text-right">Reply Rate</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              Array.from({ length: 3 }).map((_, i) => (
                <tr key={i} className="border-b border-border-primary">
                  {Array.from({ length: 8 }).map((_, j) => (
                    <td key={j} className="py-3 px-4">
                      <div className="skeleton h-4 w-16 rounded" />
                    </td>
                  ))}
                </tr>
              ))
            ) : data?.campaigns.length === 0 ? (
              <tr>
                <td
                  colSpan={8}
                  className="py-8 text-center text-text-secondary"
                >
                  No campaigns yet
                </td>
              </tr>
            ) : (
              data?.campaigns.map((c) => (
                <tr
                  key={c.id}
                  className="border-b border-border-primary hover:bg-bg-hover transition-colors"
                >
                  <td className="py-3 px-4 font-medium text-text-primary">
                    {c.name}
                  </td>
                  <td className="py-3 px-4">
                    <StatusBadge status={c.status} />
                  </td>
                  <td className="py-3 px-4 text-right text-text-secondary">
                    {c.total_sent.toLocaleString()}
                  </td>
                  <td className="py-3 px-4 text-right text-text-secondary">
                    {c.total_delivered.toLocaleString()}
                  </td>
                  <td className="py-3 px-4 text-right text-text-secondary">
                    {c.total_opened.toLocaleString()}
                  </td>
                  <td className="py-3 px-4 text-right text-accent-warm">
                    {c.open_rate}%
                  </td>
                  <td className="py-3 px-4 text-right text-text-secondary">
                    {c.total_replied.toLocaleString()}
                  </td>
                  <td className="py-3 px-4 text-right text-accent-green">
                    {c.reply_rate}%
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
