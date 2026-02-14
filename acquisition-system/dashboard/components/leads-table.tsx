"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { getLeads } from "@/lib/api";
import type { Lead } from "@/lib/types";

const TIERS = ["hot", "warm", "all"] as const;

function ScoreBadge({ score, tier }: { score: number; tier: string }) {
  const colorMap: Record<string, string> = {
    hot: "bg-accent-hot",
    warm: "bg-accent-warm",
    cold: "bg-text-secondary",
  };
  const bgColor = colorMap[tier] || "bg-text-secondary";

  return (
    <div className="flex items-center gap-2">
      <div className="score-bar w-16">
        <div
          className={`score-fill ${bgColor}`}
          style={{ width: `${(score * 100).toFixed(0)}%` }}
        />
      </div>
      <span
        className={`text-xs px-1.5 py-0.5 rounded font-medium ${
          tier === "hot"
            ? "bg-accent-hot/20 text-accent-hot"
            : tier === "warm"
              ? "bg-accent-warm/20 text-accent-warm"
              : "bg-text-secondary/20 text-text-secondary"
        }`}
      >
        {score.toFixed(2)}
      </span>
    </div>
  );
}

function LeadRow({ lead }: { lead: Lead }) {
  return (
    <tr className="border-b border-border-primary hover:bg-bg-hover transition-colors">
      <td className="py-3 px-4">
        <div className="font-medium text-text-primary">{lead.name}</div>
      </td>
      <td className="py-3 px-4 text-text-secondary text-sm">
        {lead.industry || "-"}
      </td>
      <td className="py-3 px-4 text-text-secondary text-sm">
        {[lead.city, lead.state].filter(Boolean).join(", ") || "-"}
      </td>
      <td className="py-3 px-4">
        <ScoreBadge score={lead.composite_score} tier={lead.score_tier} />
      </td>
      <td className="py-3 px-4 text-text-secondary text-sm">
        {lead.owner_name || "-"}
      </td>
      <td className="py-3 px-4 text-text-secondary text-sm truncate max-w-[180px]">
        {lead.email || "-"}
      </td>
    </tr>
  );
}

export function LeadsTable() {
  const [tier, setTier] = useState<string>("hot");

  const { data, isLoading } = useQuery({
    queryKey: ["leads", tier],
    queryFn: () => getLeads(tier),
  });

  return (
    <div className="bg-bg-card border border-border-primary rounded-lg overflow-hidden">
      <div className="px-4 py-3 border-b border-border-primary flex items-center justify-between">
        <h2 className="font-semibold text-text-primary">Top Leads</h2>
        <div className="flex gap-1">
          {TIERS.map((t) => (
            <button
              key={t}
              onClick={() => setTier(t)}
              className={`px-3 py-1 text-sm rounded transition-colors ${
                tier === t
                  ? "bg-accent-blue text-white"
                  : "text-text-secondary hover:text-text-primary hover:bg-bg-hover"
              }`}
            >
              {t.charAt(0).toUpperCase() + t.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border-primary text-text-secondary text-left">
              <th className="py-2 px-4 font-medium">Business</th>
              <th className="py-2 px-4 font-medium">Industry</th>
              <th className="py-2 px-4 font-medium">Location</th>
              <th className="py-2 px-4 font-medium">Score</th>
              <th className="py-2 px-4 font-medium">Owner</th>
              <th className="py-2 px-4 font-medium">Email</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              Array.from({ length: 5 }).map((_, i) => (
                <tr key={i} className="border-b border-border-primary">
                  {Array.from({ length: 6 }).map((_, j) => (
                    <td key={j} className="py-3 px-4">
                      <div className="skeleton h-4 w-24 rounded" />
                    </td>
                  ))}
                </tr>
              ))
            ) : data?.leads.length === 0 ? (
              <tr>
                <td
                  colSpan={6}
                  className="py-8 text-center text-text-secondary"
                >
                  No leads found
                </td>
              </tr>
            ) : (
              data?.leads.map((lead) => (
                <LeadRow key={lead.id} lead={lead} />
              ))
            )}
          </tbody>
        </table>
      </div>

      {data && (
        <div className="px-4 py-2 border-t border-border-primary text-xs text-text-secondary">
          Showing {data.leads.length} of {data.count} leads
        </div>
      )}
    </div>
  );
}
