import { DeploymentDashboard } from "@/components/DeploymentDashboard";

export default function DeploymentsPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      <DeploymentDashboard />
    </div>
  );
}

export const metadata = {
  title: "Deployment Dashboard - AWS Portfolio",
  description: "Manage and monitor AWS project deployments through GitHub Actions",
};