"use client";

import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { 
  RefreshCw, 
  Activity, 
  CheckCircle, 
  XCircle, 
  Clock, 
  Loader2,
  ExternalLink,
  Play,
  Trash2,
  AlertCircle
} from "lucide-react";
import { githubAPI, DeploymentStatus } from "@/lib/github-api";
import { projects, Project } from "@/lib/projects-data";

interface ProjectStatusCard {
  project: Project;
  status: DeploymentStatus;
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

const ProjectCard = ({ project, status, onAction, isLoading }: {
  project: Project;
  status: DeploymentStatus;
  onAction: (projectId: string, action: 'deploy' | 'destroy') => void;
  isLoading: boolean;
}) => {
  const isDeployable = githubAPI.isProjectDeployable(project.id);
  const canDeploy = status.status === 'idle' || status.status === 'completed' || status.status === 'failed';
  const canDestroy = status.status === 'completed';

  return (
    <Card className="h-full">
      <CardHeader className="pb-3">
        <div className="flex items-start justify-between">
          <div>
            <CardTitle className="text-sm font-medium">{project.title}</CardTitle>
            <p className="text-xs text-muted-foreground mt-1">{project.category}</p>
          </div>
          <div className="flex items-center gap-2">
            <StatusIcon status={status.status} />
            <Badge variant="outline" className="text-xs">
              {status.status.replace('_', ' ')}
            </Badge>
          </div>
        </div>
      </CardHeader>
      
      <CardContent className="space-y-3">
        {status.currentStep && (
          <div className="space-y-2">
            <div className="text-xs text-muted-foreground">
              {status.currentStep}
            </div>
            {status.progress !== undefined && (
              <Progress value={status.progress} className="h-1" />
            )}
          </div>
        )}

        {isDeployable ? (
          <div className="flex gap-1">
            <Button
              onClick={() => onAction(project.id, 'deploy')}
              disabled={!canDeploy || isLoading}
              size="sm"
              variant="outline"
              className="flex-1 text-xs"
            >
              <Play className="h-3 w-3 mr-1" />
              Deploy
            </Button>
            
            <Button
              onClick={() => onAction(project.id, 'destroy')}
              disabled={!canDestroy || isLoading}
              size="sm"
              variant="outline"
              className="flex-1 text-xs"
            >
              <Trash2 className="h-3 w-3 mr-1" />
              Destroy
            </Button>
          </div>
        ) : (
          <div className="text-xs text-muted-foreground text-center py-2">
            Manual deployment only
          </div>
        )}

        {project.liveUrl && status.status === 'completed' && (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => window.open(project.liveUrl, '_blank')}
            className="w-full text-xs"
          >
            <ExternalLink className="h-3 w-3 mr-1" />
            View Live
          </Button>
        )}

        {status.lastUpdated && (
          <div className="text-xs text-muted-foreground">
            Updated: {new Date(status.lastUpdated).toLocaleString()}
          </div>
        )}
      </CardContent>
    </Card>
  );
};

export function DeploymentDashboard() {
  const [projectStatuses, setProjectStatuses] = useState<Record<string, DeploymentStatus>>({});
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());

  const deployableProjects = projects.filter(p => githubAPI.isProjectDeployable(p.id));
  const nonDeployableProjects = projects.filter(p => !githubAPI.isProjectDeployable(p.id));

  const fetchAllStatuses = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const statuses = await githubAPI.getAllProjectStatuses();
      setProjectStatuses(statuses);
      setLastRefresh(new Date());
    } catch (err) {
      setError('Failed to fetch deployment statuses');
      console.error('Status fetch error:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleAction = async (projectId: string, action: 'deploy' | 'destroy') => {
    try {
      const success = await githubAPI.triggerDeployment(projectId, action);
      if (success) {
        // Update status to queued immediately
        setProjectStatuses(prev => ({
          ...prev,
          [projectId]: { ...prev[projectId], status: 'queued' }
        }));
        // Refresh after a delay
        setTimeout(fetchAllStatuses, 2000);
      } else {
        setError(`Failed to trigger ${action} for ${projectId}`);
      }
    } catch (err) {
      setError(`Error triggering ${action}: ${err}`);
    }
  };

  // Auto-refresh for active deployments
  useEffect(() => {
    fetchAllStatuses();

    const interval = setInterval(() => {
      const hasActiveDeployments = Object.values(projectStatuses).some(
        status => status.status === 'in_progress' || status.status === 'queued'
      );
      
      if (hasActiveDeployments) {
        fetchAllStatuses();
      }
    }, 10000); // Poll every 10 seconds

    return () => clearInterval(interval);
  }, []);

  const getStatusCounts = () => {
    const counts = {
      idle: 0,
      queued: 0,
      in_progress: 0,
      completed: 0,
      failed: 0,
      cancelled: 0
    };

    Object.values(projectStatuses).forEach(status => {
      counts[status.status]++;
    });

    return counts;
  };

  const statusCounts = getStatusCounts();
  const activeCount = statusCounts.queued + statusCounts.in_progress;
  const successCount = statusCounts.completed;
  const failedCount = statusCounts.failed;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold">Deployment Dashboard</h2>
          <p className="text-muted-foreground">
            Manage and monitor your AWS project deployments
          </p>
        </div>
        <Button
          onClick={fetchAllStatuses}
          disabled={isLoading}
          variant="outline"
        >
          <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? 'animate-spin' : ''}`} />
          Refresh All
        </Button>
      </div>

      {error && (
        <Alert variant="destructive">
          <XCircle className="h-4 w-4" />
          <AlertDescription>{error}</AlertDescription>
        </Alert>
      )}

      {/* Status Overview */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <Activity className="h-4 w-4 text-blue-500" />
              <div>
                <div className="text-2xl font-bold">{activeCount}</div>
                <div className="text-xs text-muted-foreground">Active</div>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-green-500" />
              <div>
                <div className="text-2xl font-bold">{successCount}</div>
                <div className="text-xs text-muted-foreground">Deployed</div>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <XCircle className="h-4 w-4 text-red-500" />
              <div>
                <div className="text-2xl font-bold">{failedCount}</div>
                <div className="text-xs text-muted-foreground">Failed</div>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center gap-2">
              <Clock className="h-4 w-4 text-gray-500" />
              <div>
                <div className="text-2xl font-bold">{deployableProjects.length}</div>
                <div className="text-xs text-muted-foreground">Total</div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="deployable" className="w-full">
        <TabsList>
          <TabsTrigger value="deployable">
            Deployable Projects ({deployableProjects.length})
          </TabsTrigger>
          <TabsTrigger value="manual">
            Manual Projects ({nonDeployableProjects.length})
          </TabsTrigger>
        </TabsList>
        
        <TabsContent value="deployable" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {deployableProjects.map(project => (
              <ProjectCard
                key={project.id}
                project={project}
                status={projectStatuses[project.id] || { status: 'idle' }}
                onAction={handleAction}
                isLoading={isLoading}
              />
            ))}
          </div>
        </TabsContent>
        
        <TabsContent value="manual" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {nonDeployableProjects.map(project => (
              <ProjectCard
                key={project.id}
                project={project}
                status={{ status: 'idle' }}
                onAction={handleAction}
                isLoading={false}
              />
            ))}
          </div>
        </TabsContent>
      </Tabs>

      <div className="text-xs text-muted-foreground text-center">
        Last updated: {lastRefresh.toLocaleString()}
        {activeCount > 0 && " • Auto-refreshing active deployments"}
      </div>
    </div>
  );
}