"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { 
  Play, 
  Trash2, 
  RefreshCw, 
  ExternalLink, 
  Clock, 
  CheckCircle, 
  XCircle, 
  AlertCircle,
  Loader2
} from "lucide-react";
import { githubAPI, DeploymentStatus } from "@/lib/github-api";
import { Project } from "@/lib/projects-data";

interface DeploymentManagerProps {
  project: Project;
}

const StatusIcon = ({ status }: { status: DeploymentStatus['status'] }) => {
  switch (status) {
    case 'queued':
      return <Clock className="h-4 w-4 text-yellow-500" />;
    case 'in_progress':
      return <Loader2 className="h-4 w-4 text-blue-500 animate-spin" />;
    case 'completed':
      return <CheckCircle className="h-4 w-4 text-green-500" />;
    case 'failed':
      return <XCircle className="h-4 w-4 text-red-500" />;
    case 'cancelled':
      return <AlertCircle className="h-4 w-4 text-gray-500" />;
    default:
      return <Clock className="h-4 w-4 text-gray-400" />;
  }
};

const StatusBadge = ({ status }: { status: DeploymentStatus['status'] }) => {
  const variants = {
    idle: "secondary",
    queued: "outline",
    in_progress: "default",
    completed: "default",
    failed: "destructive",
    cancelled: "secondary"
  } as const;

  const colors = {
    idle: "bg-gray-100 text-gray-700",
    queued: "bg-yellow-100 text-yellow-700",
    in_progress: "bg-blue-100 text-blue-700",
    completed: "bg-green-100 text-green-700",
    failed: "bg-red-100 text-red-700",
    cancelled: "bg-gray-100 text-gray-700"
  };

  return (
    <Badge variant={variants[status]} className={colors[status]}>
      <StatusIcon status={status} />
      <span className="ml-1 capitalize">{status.replace('_', ' ')}</span>
    </Badge>
  );
};

export function DeploymentManager({ project }: DeploymentManagerProps) {
  const [status, setStatus] = useState<DeploymentStatus>({ status: 'idle' });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());

  const isDeployable = githubAPI.isProjectDeployable(project.id);

  const fetchStatus = async () => {
    if (!isDeployable) return;
    
    try {
      const projectStatus = await githubAPI.getProjectStatus(project.id);
      setStatus(projectStatus);
      setLastRefresh(new Date());
      setError(null);
    } catch (err) {
      setError('Failed to fetch deployment status');
      console.error('Status fetch error:', err);
    }
  };

  const handleAction = async (action: 'deploy' | 'destroy') => {
    setIsLoading(true);
    setError(null);

    try {
      const success = await githubAPI.triggerDeployment(project.id, action);
      if (success) {
        // Update status to queued immediately
        setStatus(prev => ({ ...prev, status: 'queued' }));
        // Start polling for updates
        setTimeout(fetchStatus, 2000);
      } else {
        setError(`Failed to trigger ${action}`);
      }
    } catch (err) {
      setError(`Error triggering ${action}: ${err}`);
    } finally {
      setIsLoading(false);
    }
  };

  // Auto-refresh status for active deployments
  useEffect(() => {
    if (!isDeployable) return;

    fetchStatus();

    const interval = setInterval(() => {
      if (status.status === 'in_progress' || status.status === 'queued') {
        fetchStatus();
      }
    }, 5000); // Poll every 5 seconds for active deployments

    return () => clearInterval(interval);
  }, [project.id, status.status, isDeployable]);

  if (!isDeployable) {
    return (
      <Card className="w-full">
        <CardHeader>
          <CardTitle className="text-sm">Deployment</CardTitle>
        </CardHeader>
        <CardContent>
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              This project doesn't support automated deployment through the portfolio interface.
            </AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    );
  }

  const canDeploy = status.status === 'idle' || status.status === 'completed' || status.status === 'failed';
  const canDestroy = status.status === 'completed';
  const isActive = status.status === 'in_progress' || status.status === 'queued';

  return (
    <Card className="w-full">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="text-sm">Deployment Status</CardTitle>
          <Button
            variant="ghost"
            size="sm"
            onClick={fetchStatus}
            disabled={isLoading}
          >
            <RefreshCw className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </CardHeader>
      
      <CardContent className="space-y-4">
        {error && (
          <Alert variant="destructive">
            <XCircle className="h-4 w-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        <div className="flex items-center justify-between">
          <StatusBadge status={status.status} />
          {status.lastUpdated && (
            <span className="text-xs text-muted-foreground">
              {new Date(status.lastUpdated).toLocaleTimeString()}
            </span>
          )}
        </div>

        {status.currentStep && (
          <div className="space-y-2">
            <div className="text-sm text-muted-foreground">
              Current Step: {status.currentStep}
            </div>
            {status.progress !== undefined && (
              <Progress value={status.progress} className="h-2" />
            )}
          </div>
        )}

        {project.liveUrl && status.status === 'completed' && (
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => window.open(project.liveUrl, '_blank')}
            >
              <ExternalLink className="h-4 w-4 mr-1" />
              View Live
            </Button>
          </div>
        )}

        <div className="flex gap-2">
          <Button
            onClick={() => handleAction('deploy')}
            disabled={!canDeploy || isLoading}
            size="sm"
            className="flex-1"
          >
            <Play className="h-4 w-4 mr-1" />
            {status.status === 'completed' ? 'Redeploy' : 'Deploy'}
          </Button>
          
          <Button
            onClick={() => handleAction('destroy')}
            disabled={!canDestroy || isLoading}
            variant="destructive"
            size="sm"
            className="flex-1"
          >
            <Trash2 className="h-4 w-4 mr-1" />
            Destroy
          </Button>
        </div>

        <div className="text-xs text-muted-foreground">
          Last checked: {lastRefresh.toLocaleTimeString()}
        </div>
      </CardContent>
    </Card>
  );
}