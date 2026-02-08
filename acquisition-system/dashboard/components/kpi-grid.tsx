"use client";

import { useQuery } from "@tanstack/react-query";
import { getOverview } from "@/lib/api";

interface KpiCardProps {
  label: string;
  value: number | undefined;
  color?: string;
  sub?: string;
  loading?: boolean;
}

function KpiCard({ label, value, color, sub, loading }: KpiCardProps) {
  return (
    <div className="bg-bg-card border border-border-primary rounded-lg p-5">
      <div className="text-sm text-text-secondary mb-1">{label}</div>
      {loading ? (
        <div className="skeleton h-8 w-20 rounded" />
      ) : (
        <>
          <div className={`text-2xl font-bold ${color || "text-text-primary"}`}>
            {value?.toLocaleString() ?? "0"}
          </div>
          {sub && (
            <div className="text-xs text-text-secondary mt-1">{sub}</div>
          )}
        </>
      )}
    </div>
  );
}

export function KpiGrid() {
  const { data, isLoading } = useQuery({
    queryKey: ["overview"],
    queryFn: getOverview,
  });

  const replyRate =
    data && data.emails_sent > 0
      ? `${((data.replies / data.emails_sent) * 100).toFixed(1)}% reply rate`
      : undefined;

  return (
    <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 mb-6">
      <KpiCard
        label="Total Businesses"
        value={data?.total_businesses}
        loading={isLoading}
      />
      <KpiCard
        label="Hot Leads"
        value={data?.hot_leads}
        color="text-accent-hot"
        loading={isLoading}
      />
      <KpiCard
        label="With Email"
        value={data?.with_email}
        color="text-accent-warm"
        loading={isLoading}
      />
      <KpiCard
        label="Emails Sent"
        value={data?.emails_sent}
        color="text-accent-green"
        loading={isLoading}
      />
      <KpiCard
        label="Replies"
        value={data?.replies}
        color="text-accent-green"
        sub={replyRate}
        loading={isLoading}
      />
      <KpiCard
        label="Active Deals"
        value={data?.active_deals}
        loading={isLoading}
      />
    </div>
  );
}
