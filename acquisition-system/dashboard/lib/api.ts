import type {
  OverviewStats,
  LeadsResponse,
  LeadStatsResponse,
  PipelineResponse,
  CampaignStatsResponse,
} from "./types";

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

async function fetchAPI<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}/api${path}`);
  if (!res.ok) {
    throw new Error(`API ${res.status}: ${res.statusText}`);
  }
  return res.json();
}

export function getOverview(): Promise<OverviewStats> {
  return fetchAPI("/businesses/overview");
}

export function getLeads(
  tier?: string,
  limit: number = 20
): Promise<LeadsResponse> {
  const params = new URLSearchParams({ limit: String(limit) });
  if (tier && tier !== "all") params.set("tier", tier);
  return fetchAPI(`/leads?${params}`);
}

export function getLeadStats(): Promise<LeadStatsResponse> {
  return fetchAPI("/leads/stats");
}

export function getPipeline(): Promise<PipelineResponse> {
  return fetchAPI("/deals/pipeline");
}

export function getCampaignStats(): Promise<CampaignStatsResponse> {
  return fetchAPI("/campaigns/stats");
}
