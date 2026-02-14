"use client";

import { useQuery } from "@tanstack/react-query";
import { getLeadStats } from "@/lib/api";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts";

function bucketColor(bucket: number): string {
  if (bucket >= 8) return "#f85149"; // hot
  if (bucket >= 5) return "#d29922"; // warm
  return "#388bfd"; // cold
}

export function ScoreChart() {
  const { data, isLoading } = useQuery({
    queryKey: ["leadStats"],
    queryFn: getLeadStats,
  });

  const chartData = (data?.score_distribution || []).map((b) => ({
    label: `${((b.bucket - 1) / 10).toFixed(1)}`,
    count: b.count,
    color: bucketColor(b.bucket),
  }));

  if (isLoading) {
    return (
      <div className="bg-bg-card border border-border-primary rounded-lg p-4">
        <h2 className="font-semibold text-text-primary mb-4">
          Score Distribution
        </h2>
        <div className="skeleton h-[160px] rounded" />
      </div>
    );
  }

  if (chartData.length === 0) {
    return (
      <div className="bg-bg-card border border-border-primary rounded-lg p-4">
        <h2 className="font-semibold text-text-primary mb-4">
          Score Distribution
        </h2>
        <div className="h-[160px] flex items-center justify-center text-text-secondary text-sm">
          No scoring data yet
        </div>
      </div>
    );
  }

  return (
    <div className="bg-bg-card border border-border-primary rounded-lg p-4">
      <h2 className="font-semibold text-text-primary mb-4">
        Score Distribution
      </h2>
      <ResponsiveContainer width="100%" height={160}>
        <BarChart data={chartData}>
          <XAxis
            dataKey="label"
            tick={{ fill: "#8b949e", fontSize: 11 }}
            axisLine={{ stroke: "#30363d" }}
            tickLine={false}
          />
          <YAxis hide />
          <Tooltip
            contentStyle={{
              background: "#161b22",
              border: "1px solid #30363d",
              borderRadius: "6px",
              color: "#e1e4e8",
              fontSize: 12,
            }}
          />
          <Bar dataKey="count" radius={[3, 3, 0, 0]}>
            {chartData.map((entry, i) => (
              <Cell key={i} fill={entry.color} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
