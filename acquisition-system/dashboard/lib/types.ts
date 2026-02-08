export interface OverviewStats {
  total_businesses: number;
  active_businesses: number;
  with_email: number;
  scored: number;
  hot_leads: number;
  emails_sent: number;
  replies: number;
  active_deals: number;
  recent_scrapes_7d: number;
}

export interface Lead {
  id: string;
  name: string;
  industry: string | null;
  city: string | null;
  state: string | null;
  website_url: string | null;
  estimated_revenue: number | null;
  estimated_employees: number | null;
  composite_score: number;
  score_tier: "hot" | "warm" | "cold";
  scored_at: string;
  signal_marketplace_listing: number | null;
  signal_owner_age: number | null;
  signal_digital_decay: number | null;
  signal_headcount_decline: number | null;
  owner_name: string | null;
  email: string | null;
  estimated_age: number | null;
}

export interface LeadsResponse {
  leads: Lead[];
  count: number;
}

export interface ScoreDistribution {
  bucket: number;
  count: number;
}

export interface LeadStatsResponse {
  by_tier: Record<string, number>;
  top_industries: Array<{ industry: string; count: number; avg_score: number }>;
  top_states: Array<{ state: string; count: number; hot_count: number }>;
  score_distribution: ScoreDistribution[];
}

export interface PipelineStage {
  stage: string;
  count: number;
  total_value: number;
  weighted_value: number;
  avg_probability: number;
}

export interface PipelineResponse {
  pipeline: PipelineStage[];
  stages: string[];
}

export interface CampaignStat {
  id: string;
  name: string;
  status: string;
  total_sent: number;
  total_delivered: number;
  total_opened: number;
  total_replied: number;
  total_interested: number;
  open_rate: number;
  reply_rate: number;
}

export interface CampaignStatsResponse {
  campaigns: CampaignStat[];
}
