"use client";

import { useQuery } from "@tanstack/react-query";
import { getPipeline } from "@/lib/api";

const STAGE_LABELS: Record<string, string> = {
  lead: "Lead",
  contacted: "Contacted",
  qualified: "Qualified",
  loi_sent: "LOI Sent",
  due_diligence: "Due Diligence",
  closing: "Closing",
  closed_won: "Won",
  closed_lost: "Lost",
};

const STAGE_COLORS: Record<string, string> = {
  lead: "bg-accent-blue",
  contacted: "bg-blue-400",
  qualified: "bg-accent-green",
  loi_sent: "bg-emerald-400",
  due_diligence: "bg-accent-warm",
  closing: "bg-orange-400",
  closed_won: "bg-accent-green",
  closed_lost: "bg-accent-hot",
};

export function PipelineFunnel() {
  const { data, isLoading } = useQuery({
    queryKey: ["pipeline"],
    queryFn: getPipeline,
  });

  const maxCount = Math.max(
    ...(data?.pipeline.map((s) => s.count) || [1]),
    1
  );

  return (
    <div className="bg-bg-card border border-border-primary rounded-lg overflow-hidden">
      <div className="px-4 py-3 border-b border-border-primary">
        <h2 className="font-semibold text-text-primary">Deal Pipeline</h2>
      </div>

      <div className="p-4">
        {isLoading ? (
          <div className="space-y-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="skeleton h-6 rounded" />
            ))}
          </div>
        ) : (
          <div className="space-y-2">
            {(data?.stages || [])
              .filter((stage) => stage !== "closed_lost")
              .map((stage) => {
                const stageData = data?.pipeline.find(
                  (s) => s.stage === stage
                );
                const count = stageData?.count || 0;
                const pct = maxCount > 0 ? (count / maxCount) * 100 : 0;
                const value = stageData?.total_value || 0;

                return (
                  <div key={stage} className="flex items-center gap-3">
                    <div className="w-24 text-xs text-text-secondary truncate">
                      {STAGE_LABELS[stage] || stage}
                    </div>
                    <div className="flex-1 h-6 bg-border-primary/30 rounded overflow-hidden relative">
                      <div
                        className={`h-full rounded transition-all ${STAGE_COLORS[stage] || "bg-accent-blue"}`}
                        style={{
                          width: `${Math.max(pct, count > 0 ? 8 : 0)}%`,
                        }}
                      />
                      {count > 0 && (
                        <span className="absolute inset-0 flex items-center px-2 text-xs font-medium text-white">
                          {count}
                          {value > 0 &&
                            ` ($${(value / 1000000).toFixed(1)}M)`}
                        </span>
                      )}
                    </div>
                  </div>
                );
              })}
          </div>
        )}
      </div>
    </div>
  );
}
