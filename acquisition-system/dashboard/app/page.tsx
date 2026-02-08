import { KpiGrid } from "@/components/kpi-grid";
import { LeadsTable } from "@/components/leads-table";
import { PipelineFunnel } from "@/components/pipeline-funnel";
import { CampaignTable } from "@/components/campaign-table";
import { ScoreChart } from "@/components/score-chart";

export default function DashboardPage() {
  return (
    <>
      <KpiGrid />
      <div className="grid grid-cols-1 lg:grid-cols-[2fr_1fr] gap-6 mb-6">
        <LeadsTable />
        <PipelineFunnel />
      </div>
      <CampaignTable />
      <ScoreChart />
    </>
  );
}
