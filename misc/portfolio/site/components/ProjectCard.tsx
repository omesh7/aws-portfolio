"use client"

import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { ExternalLink, Github } from "lucide-react"
import { DeploymentStatus } from "@/components/DeploymentStatus"
import { githubAPI } from "@/lib/github-api"
import type { Project } from "@/lib/projects-data"

interface ProjectCardProps {
  project: Project
  index: number
}

const ProjectCard = ({ project }: ProjectCardProps) => {
  const isDeployable = githubAPI.isProjectDeployable(project.id)

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
          {isDeployable && (
            <Badge variant="default" className="ml-2 shrink-0">
              Deployable
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

        {/* Deployment Status for deployable projects */}
        {isDeployable && (
          <DeploymentStatus project={project} compact={true} />
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
          {/* Live Demo and GitHub buttons for all projects */}
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
        </div>
      </CardFooter>
    </Card>
  )
}

export default ProjectCard
