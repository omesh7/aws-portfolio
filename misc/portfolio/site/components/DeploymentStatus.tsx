"use client";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { 
  Play, 
  Trash2, 
  ExternalLink, 
  Clock, 
  CheckCircle, 
  XCircle, 
  AlertCircle,
  Loader2
} from "lucide-react";
import { useWorkflowStatus } from "@/hooks/useWorkflowStatus";
import { Project } from "@/lib/projects-data";

interface DeploymentStatusProps {
  project: Project;
  compact?: boolean;
}

const StatusIcon = ({ status }: { status: string }) => {
  switch (status) {
    case 'queued':
      return <Clock className="h-3 w-3 text-yellow-500" />;
    case 'in_progress':
      return <Loader2 className="h-3 w-3 text-blue-500 animate-spin" />;
    case 'completed':
      return <CheckCircle className="h-3 w-3 text-green-500" />;
    case 'failed':
      return <XCircle className="h-3 w-3 text-red-500" />;
    case 'cancelled':
      return <AlertCircle className="h-3 w-3 text-gray-500" />;
    default:
      return <Clock className="h-3 w-3 text-gray-400" />;
  }
};

export function DeploymentStatus({ project, compact = false }: DeploymentStatusProps) {
  const { 
    status, 
    isLoading, 
    error, 
    triggerAction, 
    isDeployable 
  } = useWorkflowStatus({ 
    projectId: project.id,
    enabled: true 
  });

  if (!isDeployable) {
    return null;
  }

  const canDeploy = status.status === 'idle' || status.status === 'completed' || status.status === 'failed';
  const canDestroy = status.status === 'completed';
  const isActive = status.status === 'in_progress' || status.status === 'queued';

  if (compact) {
    return (
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <Badge variant="outline" className="text-xs">
            <StatusIcon status={status.status} />
            <span className="ml-1">{status.status.replace('_', ' ')}</span>
          </Badge>
        </div>

        {status.currentStep && (
          <div className="space-y-1">
            <div className="text-xs text-muted-foreground truncate">
              {status.currentStep}
            </div>
            {status.progress !== undefined && (
              <Progress value={status.progress} className="h-1" />
            )}
          </div>
        )}

        <Button
          onClick={() => window.location.href = '/deployments'}
          size="sm"
          variant="outline"
          className="w-full h-7 text-xs"
        >
          Manage Deployment
        </Button>

        {error && (
          <div className="text-xs text-red-500 truncate" title={error}>
            {error}
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="space-y-3 p-3 bg-muted/30 rounded-lg border">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <StatusIcon status={status.status} />
          <span className="text-sm font-medium capitalize">
            {status.status.replace('_', ' ')}
          </span>
        </div>
        {status.lastUpdated && (
          <span className="text-xs text-muted-foreground">
            {new Date(status.lastUpdated).toLocaleTimeString()}
          </span>
        )}
      </div>

      {status.currentStep && (
        <div className="space-y-2">
          <div className="text-sm text-muted-foreground">
            {status.currentStep}
          </div>
          {status.progress !== undefined && (
            <Progress value={status.progress} className="h-2" />
          )}
        </div>
      )}

      <Button
        onClick={() => window.location.href = '/deployments'}
        size="sm"
        className="w-full"
      >
        Manage Deployment
      </Button>

      {status.status === 'completed' && project.liveUrl && (
        <Button
          variant="outline"
          size="sm"
          onClick={() => window.open(project.liveUrl, '_blank')}
          className="w-full"
        >
          <ExternalLink className="h-4 w-4 mr-1" />
          View Live Application
        </Button>
      )}

      {error && (
        <div className="text-sm text-red-500 p-2 bg-red-50 rounded border">
          {error}
        </div>
      )}
    </div>
  );
}