"use client";

import { useState, useEffect, useCallback } from "react";
import { githubAPI, DeploymentStatus } from "@/lib/github-api";

interface UseWorkflowStatusOptions {
  projectId: string;
  pollInterval?: number;
  enabled?: boolean;
}

export function useWorkflowStatus({ 
  projectId, 
  pollInterval = 5000, 
  enabled = true 
}: UseWorkflowStatusOptions) {
  const [status, setStatus] = useState<DeploymentStatus>({ status: 'idle' });
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());

  const fetchStatus = useCallback(async () => {
    if (!enabled || !githubAPI.isProjectDeployable(projectId)) {
      return;
    }

    setIsLoading(true);
    try {
      const projectStatus = await githubAPI.getProjectStatus(projectId);
      setStatus(projectStatus);
      setLastUpdated(new Date());
      setError(null);
    } catch (err) {
      setError(`Failed to fetch status: ${err}`);
      console.error('Status fetch error:', err);
    } finally {
      setIsLoading(false);
    }
  }, [projectId, enabled]);

  const triggerAction = useCallback(async (action: 'deploy' | 'destroy') => {
    try {
      const success = await githubAPI.triggerDeployment(projectId, action);
      if (success) {
        // Immediately update status to queued
        setStatus(prev => ({ ...prev, status: 'queued' }));
        // Fetch updated status after a short delay
        setTimeout(fetchStatus, 2000);
        return true;
      } else {
        setError(`Failed to trigger ${action}`);
        return false;
      }
    } catch (err) {
      setError(`Error triggering ${action}: ${err}`);
      return false;
    }
  }, [projectId, fetchStatus]);

  // Initial fetch
  useEffect(() => {
    if (enabled) {
      fetchStatus();
    }
  }, [fetchStatus, enabled]);

  // Polling for active deployments
  useEffect(() => {
    if (!enabled) return;

    const shouldPoll = status.status === 'in_progress' || status.status === 'queued';
    
    if (shouldPoll) {
      const interval = setInterval(fetchStatus, pollInterval);
      return () => clearInterval(interval);
    }
  }, [status.status, pollInterval, fetchStatus, enabled]);

  return {
    status,
    isLoading,
    error,
    lastUpdated,
    fetchStatus,
    triggerAction,
    isDeployable: githubAPI.isProjectDeployable(projectId),
  };
}