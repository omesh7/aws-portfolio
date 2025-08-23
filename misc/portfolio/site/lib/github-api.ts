import { Octokit } from "@octokit/rest";

interface DeploymentStatus {
  status:
    | "idle"
    | "queued"
    | "in_progress"
    | "completed"
    | "failed"
    | "cancelled";
  url?: string;
  lastUpdated?: string;
  currentStep?: string;
  progress?: number;
}

interface WorkflowStep {
  name: string;
  status: "queued" | "in_progress" | "completed" | "failed" | "cancelled";
  conclusion?: string;
  started_at?: string;
  completed_at?: string;
}

interface ProjectMapping {
  [key: string]: {
    workflowFile: string;
    displayName: string;
  };
}

const PROJECT_MAPPINGS: ProjectMapping = {
  "mass-email-system": {
    workflowFile: "02-mass-email-deploy.yml",
    displayName: "Mass Email System",
  },
  "alexa-skill": {
    workflowFile: "03-alexa-skill-deploy.yml",
    displayName: "Alexa Skill",
  },
  "text-to-speech": {
    workflowFile: "04-polly-tts.yml",
    displayName: "Text-to-Speech",
  },
  "image-resizer": {
    workflowFile: "project-06-deploy.yml",
    displayName: "Smart Image Resizer",
  },
  "receipt-processor": {
    workflowFile: "project-07-deploy.yml",
    displayName: "Receipt Processor",
  },
  "rag-portfolio-chat": {
    workflowFile: "project-08-deploy.yml",
    displayName: "AI RAG Chat",
  },
  "kinesis-ml-pipeline": {
    workflowFile: "project-10-deploy.yml",
    displayName: "Kinesis ML Pipeline",
  },
  "image-recognition-poem": {
    workflowFile: "project-11-deploy.yml",
    displayName: "Image Recognition + Poetry",
  },
  "2048-game-cicd": {
    workflowFile: "project-13-deploy.yml",
    displayName: "2048 Game CI/CD",
  },
  "multi-cloud-weather": {
    workflowFile: "project-14-deploy.yml",
    displayName: "Multi-Cloud Weather",
  },
};

class GitHubAPIService {
  private octokit: Octokit | null = null;
  private owner: string;
  private repo: string;

  constructor() {
    this.owner = process.env.NEXT_PUBLIC_GITHUB_REPO_OWNER || "omesh7";
    this.repo = process.env.NEXT_PUBLIC_GITHUB_REPO_NAME || "aws-portfolio";

    const token = process.env.NEXT_PUBLIC_GITHUB_TOKEN;
    if (token) {
      this.octokit = new Octokit({ auth: token });
    }
  }

  private isAvailable(): boolean {
    return this.octokit !== null;
  }

  async getProjectStatus(projectId: string): Promise<DeploymentStatus> {
    if (!this.isAvailable()) {
      return { status: "idle" };
    }

    const mapping = PROJECT_MAPPINGS[projectId];
    if (!mapping) {
      return { status: "idle" };
    }

    try {
      // Get latest workflow runs for this project
      const runs = await this.octokit!.rest.actions.listWorkflowRuns({
        owner: this.owner,
        repo: this.repo,
        workflow_id: mapping.workflowFile,
        per_page: 1,
      });

      if (runs.data.workflow_runs.length === 0) {
        return { status: "idle" };
      }

      const latestRun = runs.data.workflow_runs[0];
      const status = this.mapWorkflowStatus(latestRun.status, latestRun.conclusion);
      
      // Get current step if run is in progress
      let currentStep = undefined;
      let progress = 0;
      
      if (status === "in_progress") {
        const steps = await this.getWorkflowSteps(latestRun.id);
        currentStep = this.getCurrentStep(steps);
        progress = this.calculateProgress(steps);
      }

      return {
        status,
        lastUpdated: latestRun.updated_at,
        currentStep,
        progress,
      };
    } catch (error) {
      console.error("Failed to get project status:", error);
      return { status: "idle" };
    }
  }

  async triggerDeployment(
    projectId: string,
    action: "deploy" | "destroy"
  ): Promise<boolean> {
    if (!this.isAvailable()) {
      console.error("GitHub API not available - missing token");
      return false;
    }

    const mapping = PROJECT_MAPPINGS[projectId];
    if (!mapping) {
      console.error(`No workflow mapping found for project: ${projectId}`);
      return false;
    }

    try {
      await this.octokit!.rest.actions.createWorkflowDispatch({
        owner: this.owner,
        repo: this.repo,
        workflow_id: mapping.workflowFile,
        ref: "main",
        inputs: {
          action: action,
        },
      });

      console.log(`✅ Triggered ${action} for project ${projectId}`);
      return true;
    } catch (error) {
      console.error(
        `Failed to trigger ${action} for project ${projectId}:`,
        error
      );
      return false;
    }
  }

  async getWorkflowRuns(projectId: string, limit: number = 5) {
    if (!this.isAvailable()) {
      return [];
    }

    const mapping = PROJECT_MAPPINGS[projectId];
    if (!mapping) {
      return [];
    }

    try {
      const runs = await this.octokit!.rest.actions.listWorkflowRuns({
        owner: this.owner,
        repo: this.repo,
        workflow_id: mapping.workflowFile,
        per_page: limit,
      });

      return runs.data.workflow_runs;
    } catch (error) {
      console.error("Failed to get workflow runs:", error);
      return [];
    }
  }

  private async getWorkflowSteps(runId: number): Promise<WorkflowStep[]> {
    try {
      const jobs = await this.octokit!.rest.actions.listJobsForWorkflowRun({
        owner: this.owner,
        repo: this.repo,
        run_id: runId,
      });

      const steps: WorkflowStep[] = [];
      for (const job of jobs.data.jobs) {
        for (const step of job.steps || []) {
          steps.push({
            name: step.name,
            status: step.status as WorkflowStep['status'],
            conclusion: step.conclusion || undefined,
            started_at: step.started_at || undefined,
            completed_at: step.completed_at || undefined,
          });
        }
      }
      return steps;
    } catch (error) {
      console.error("Failed to get workflow steps:", error);
      return [];
    }
  }

  private getCurrentStep(steps: WorkflowStep[]): string {
    const inProgressStep = steps.find(step => step.status === 'in_progress');
    if (inProgressStep) {
      return inProgressStep.name;
    }
    
    const lastCompletedStep = steps.filter(step => step.status === 'completed').pop();
    if (lastCompletedStep) {
      return `Completed: ${lastCompletedStep.name}`;
    }
    
    return 'Starting...';
  }

  private calculateProgress(steps: WorkflowStep[]): number {
    if (steps.length === 0) return 0;
    
    const completedSteps = steps.filter(step => step.status === 'completed').length;
    return Math.round((completedSteps / steps.length) * 100);
  }

  private mapWorkflowStatus(status: string | null, conclusion: string | null): DeploymentStatus['status'] {
    if (status === 'queued') return 'queued';
    if (status === 'in_progress') return 'in_progress';
    if (status === 'completed') {
      if (conclusion === 'success') return 'completed';
      if (conclusion === 'failure') return 'failed';
      if (conclusion === 'cancelled') return 'cancelled';
    }
    return 'idle';
  }

  async getAllProjectStatuses(): Promise<Record<string, DeploymentStatus>> {
    const statuses: Record<string, DeploymentStatus> = {};

    for (const projectId of Object.keys(PROJECT_MAPPINGS)) {
      statuses[projectId] = await this.getProjectStatus(projectId);
    }

    return statuses;
  }

  getProjectDisplayName(projectId: string): string {
    return PROJECT_MAPPINGS[projectId]?.displayName || projectId;
  }

  isProjectDeployable(projectId: string): boolean {
    return projectId in PROJECT_MAPPINGS;
  }
}

export const githubAPI = new GitHubAPIService();
export type { DeploymentStatus, WorkflowStep };
export { PROJECT_MAPPINGS };
