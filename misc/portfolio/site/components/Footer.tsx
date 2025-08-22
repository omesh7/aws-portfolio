"use client"

import { Badge } from "@/components/ui/badge"

const Footer = () => {
  return (
    <footer className="py-8 bg-muted/30 border-t border-border/50">
      <div className="container mx-auto px-4">
        <div className="flex flex-col md:flex-row justify-between items-center gap-4">
          <div className="text-center md:text-left">
            <h3 className="font-bold text-lg mb-1">Omeshwar V</h3>
            <p className="text-sm text-muted-foreground">Cloud Engineer & DevOps Enthusiast</p>
          </div>

          <div className="flex items-center gap-4">
            <Badge variant="secondary" className="px-3 py-1">
              🚀 Available for Opportunities
            </Badge>
            <p className="text-sm text-muted-foreground">© 2024 Omeshwar V. All rights reserved.</p>
          </div>
        </div>

        <div className="mt-6 pt-6 border-t border-border/50 text-center">
          <p className="text-xs text-muted-foreground">
            Built with Next.js, TypeScript, Tailwind CSS, and GSAP animations. Deployed on AWS with Infrastructure as
            Code.
          </p>
        </div>
      </div>
    </footer>
  )
}

export default Footer
