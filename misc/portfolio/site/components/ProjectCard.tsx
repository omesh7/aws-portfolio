"use client"

import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Dialog, DialogContent, DialogDescription, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { ExternalLink, Github, Expand } from "lucide-react"
import { DeploymentStatus } from "@/components/DeploymentStatus"
import { githubAPI } from "@/lib/github-api"
import type { Project } from "@/lib/projects-data"
import { useState, useEffect } from "react"

interface ProjectCardProps {
  project: Project
  index: number
  modalSizePercent?: number
}

const ProjectCard = ({ project, modalSizePercent = 78 }: ProjectCardProps) => {
  const isDeployable = githubAPI.isProjectDeployable(project.id)

  const [modalDimensions, setModalDimensions] = useState({
    width: `${modalSizePercent}vw`,
    height: `${modalSizePercent}vh`,
    maxWidth: `${modalSizePercent}vw`,
    maxHeight: `${modalSizePercent}vh`,
  })

  const calculateModalSize = (img: HTMLImageElement) => {
    const aspectRatio = img.naturalWidth / img.naturalHeight
    const viewportAspectRatio = window.innerWidth / window.innerHeight

    let width, height, maxWidth, maxHeight

    if (aspectRatio > viewportAspectRatio) {
      width = `${modalSizePercent}vw`
      maxWidth = `${modalSizePercent}vw`
      height = `${Math.min(modalSizePercent, (modalSizePercent / aspectRatio) * viewportAspectRatio)}vh`
      maxHeight = `${Math.min(modalSizePercent, (modalSizePercent / aspectRatio) * viewportAspectRatio)}vh`
    } else {
      height = `${modalSizePercent}vh`
      maxHeight = `${modalSizePercent}vh`
      width = `${Math.min(modalSizePercent, (modalSizePercent * aspectRatio) / viewportAspectRatio)}vw`
      maxWidth = `${Math.min(modalSizePercent, (modalSizePercent * aspectRatio) / viewportAspectRatio)}vw`
    }

    return { width, height, maxWidth, maxHeight }
  }

  useEffect(() => {
    if (project.architectureDiagram) {
      const img = new Image()
      img.onload = () => {
        const dimensions = calculateModalSize(img)
        setModalDimensions(dimensions)
      }
      img.src = project.architectureDiagram
    }
  }, [project.architectureDiagram, modalSizePercent])

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
        {/* Architecture Diagram */}
        <div className="aspect-video bg-muted rounded-lg flex items-center justify-center border border-border overflow-hidden">
          {project.architectureDiagram ? (
            <Dialog>
              <DialogTrigger asChild>
                <div className="relative w-full h-full p-4 cursor-pointer group hover:bg-muted/50 transition-colors">
                  <img
                    src={project.architectureDiagram}
                    alt={`${project.title} Architecture Diagram`}
                    className="w-full h-full object-contain"
                  />
                  <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity bg-black/20 rounded">
                    <div className="bg-white/90 p-2 rounded-full">
                      <Expand className="h-5 w-5 text-gray-700" />
                    </div>
                  </div>
                </div>
              </DialogTrigger>
            <DialogContent className="p-0 bg-black/95 border-none overflow-hidden" style={modalDimensions}>
              <DialogTitle className="sr-only">{project.title} Architecture Diagram</DialogTitle>
              <DialogDescription className="sr-only">
                Detailed architecture diagram showing the technical infrastructure and data flow
              </DialogDescription>

              <div className="w-full h-full flex items-center justify-center p-8">
                <div className="relative w-full h-full flex items-center justify-center">
                  <img
                    src={project.architectureDiagram}
                    alt={`${project.title} Architecture Diagram - Full View`}
                    className="w-full h-full object-contain rounded-lg shadow-2xl"
                    style={{
                      maxWidth: "100%",
                      maxHeight: "100%",
                      objectFit: "contain",
                      objectPosition: "center",
                    }}
                  />

                  <div className="absolute bottom-6 left-6 bg-black/80 backdrop-blur-sm text-white px-4 py-3 rounded-lg border border-white/10">
                    <p className="text-base font-semibold">{project.title}</p>
                    <p className="text-sm opacity-90">Architecture Diagram</p>
                  </div>
                  {/* 
                  <div className="absolute top-6 left-6 bg-black/60 backdrop-blur-sm text-white px-3 py-2 rounded-lg text-xs opacity-75">
                    {modalSizePercent}% viewport
                  </div> */}
                </div>
              </div>
            </DialogContent>
            </Dialog>
          ) : (
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
          )}
        </div>

        {/* Deployment Status for deployable projects */}
        {isDeployable && <DeploymentStatus project={project} compact={true} />}

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
