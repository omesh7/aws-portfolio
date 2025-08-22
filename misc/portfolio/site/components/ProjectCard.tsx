"use client"

import { useState } from "react"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Progress } from "@/components/ui/progress"
import { ExternalLink, Github, Play, Square, Loader2 } from "lucide-react"
import type { Project } from "@/lib/projects-data"

interface ProjectCardProps {
  project: Project
  index: number
}

const ProjectCard = ({ project }: ProjectCardProps) => {
  const [isStarting, setIsStarting] = useState(false)
  const [isStopping, setIsStopping] = useState(false)
  const [isRunning, setIsRunning] = useState(false)
  const [progress, setProgress] = useState(0)
  const [currentStep, setCurrentStep] = useState("")
  const [showProgress, setShowProgress] = useState(false)

  const simulateProgress = async (steps: string[], isStarting: boolean) => {
    setShowProgress(true)
    setProgress(0)

    for (let i = 0; i < steps.length; i++) {
      setCurrentStep(steps[i])
      setProgress(((i + 1) / steps.length) * 100)

      // Simulate time for each step
      await new Promise((resolve) => setTimeout(resolve, 800))
    }

    // Hide progress after completion
    setTimeout(() => {
      setShowProgress(false)
      setCurrentStep("")
      setProgress(0)
    }, 1000)
  }

  const handleStart = async () => {
    setIsStarting(true)
    try {
      console.log(`Starting infrastructure for ${project.title}`)

      const steps = project.deploymentSteps || [
        "Preparing infrastructure",
        "Running Terraform",
        "Terraform applied",
        "Code building starting",
        "Deployment in progress",
        "Done, deployed",
      ]

      await simulateProgress(steps, true)
      setIsRunning(true)
    } catch (error) {
      console.error("Failed to start infrastructure:", error)
    } finally {
      setIsStarting(false)
    }
  }

  const handleStop = async () => {
    setIsStopping(true)
    try {
      console.log(`Stopping infrastructure for ${project.title}`)

      const stopSteps = ["Stopping services", "Draining connections", "Destroying resources", "Cleanup complete"]

      await simulateProgress(stopSteps, false)
      setIsRunning(false)
    } catch (error) {
      console.error("Failed to stop infrastructure:", error)
    } finally {
      setIsStopping(false)
    }
  }

  return (
    <Card className="group hover:shadow-lg transition-all duration-300 hover:-translate-y-1 bg-card/50 backdrop-blur-sm border-border/50">
      <CardHeader className="pb-4">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <CardTitle className="text-xl font-bold group-hover:text-primary transition-colors">
              {project.title}
            </CardTitle>
            <CardDescription className="mt-2 text-sm">{project.category}</CardDescription>
          </div>
          {project.deployable && (
            <Badge variant={isRunning ? "default" : "secondary"} className="ml-2 shrink-0">
              {isRunning ? "Running" : "Deployable"}
            </Badge>
          )}
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {/* Architecture Diagram Placeholder */}
        <div className="aspect-video bg-muted rounded-lg flex items-center justify-center border-2 border-dashed border-border">
          <div className="text-center text-muted-foreground">
            <div className="w-16 h-16 mx-auto mb-2 bg-primary/10 rounded-lg flex items-center justify-center">
              <svg className="w-8 h-8 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
                />
              </svg>
            </div>
            <p className="text-sm">Architecture Diagram</p>
            <p className="text-xs">Coming Soon</p>
          </div>
        </div>

        {showProgress && (
          <div className="space-y-2 p-3 bg-muted/50 rounded-lg border">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Deployment Progress</span>
              <span className="text-sm text-muted-foreground">{Math.round(progress)}%</span>
            </div>
            <Progress value={progress} className="h-2" />
            <p className="text-xs text-muted-foreground">{currentStep}</p>
          </div>
        )}

        <div>
          <p className="text-sm text-muted-foreground mb-3">{project.description}</p>

          <div className="space-y-2">
            <div>
              <p className="text-xs font-medium text-muted-foreground mb-1">Key Achievement:</p>
              <p className="text-sm font-medium text-primary">{project.achievement}</p>
            </div>

            <div>
              <p className="text-xs font-medium text-muted-foreground mb-2">Tech Stack:</p>
              <div className="flex flex-wrap gap-1">
                {project.techStack.slice(0, 4).map((tech) => (
                  <Badge key={tech} variant="outline" className="text-xs">
                    {tech}
                  </Badge>
                ))}
                {project.techStack.length > 4 && (
                  <Badge variant="outline" className="text-xs">
                    +{project.techStack.length - 4} more
                  </Badge>
                )}
              </div>
            </div>
          </div>
        </div>
      </CardContent>

      <CardFooter className="pt-4 border-t border-border/50">
        <div className="flex gap-2 w-full">
          {project.deployable ? (
            <>
              {/* Infrastructure Control Buttons */}
              <div className="flex gap-2 flex-1">
                <Button
                  variant="default"
                  size="sm"
                  onClick={handleStart}
                  disabled={isStarting || isRunning || showProgress}
                  className="flex-1"
                >
                  {isStarting ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : <Play className="h-4 w-4 mr-2" />}
                  {isStarting ? "Starting..." : "Start"}
                </Button>

                <Button
                  variant="outline"
                  size="sm"
                  onClick={handleStop}
                  disabled={isStopping || !isRunning || showProgress}
                  className="flex-1 bg-transparent"
                >
                  {isStopping ? <Loader2 className="h-4 w-4 animate-spin mr-2" /> : <Square className="h-4 w-4 mr-2" />}
                  {isStopping ? "Stopping..." : "Stop"}
                </Button>
              </div>

              {/* GitHub Button - Always present for deployable projects */}
              <Button variant="outline" size="sm" asChild className="shrink-0 bg-transparent">
                <a href={project.githubUrl} target="_blank" rel="noopener noreferrer">
                  <Github className="h-4 w-4" />
                </a>
              </Button>
            </>
          ) : (
            <>
              {/* Non-deployable projects - Live Demo and GitHub */}
              {project.liveUrl && (
                <Button variant="default" size="sm" asChild className="flex-1">
                  <a href={project.liveUrl} target="_blank" rel="noopener noreferrer">
                    <ExternalLink className="h-4 w-4 mr-2" />
                    Live Demo
                  </a>
                </Button>
              )}

              <Button variant="outline" size="sm" asChild className={project.liveUrl ? "shrink-0" : "flex-1"}>
                <a href={project.githubUrl} target="_blank" rel="noopener noreferrer">
                  <Github className="h-4 w-4 mr-2" />
                  {project.liveUrl ? "" : "View Code"}
                </a>
              </Button>
            </>
          )}
        </div>
      </CardFooter>
    </Card>
  )
}

export default ProjectCard
