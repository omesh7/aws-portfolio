"use client"

import { useEffect, useRef } from "react"
import { gsap } from "gsap"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { TrendingUp, Users, Award, Target } from "lucide-react"

const achievements = [
  {
    icon: TrendingUp,
    title: "14+ Production Projects",
    description: " AWS solutions deployed and maintained",
    metric: "100% Uptime",
  },
  {
    icon: Users,
    title: "1000+ Concurrent Users",
    description: "Scalable applications handling high traffic loads",
    metric: "<200ms Response",
  },
  {
    icon: Award,
    title: "Cost Optimization",
    description: "Reduced infrastructure costs by 60% using serverless",
    metric: "<$50/month",
  },
  {
    icon: Target,
    title: "Zero Security Incidents",
    description: " security implementations",
    metric: "99.9% Reliability",
  },
]

const Experience = () => {
  const sectionRef = useRef<HTMLElement>(null)
  const titleRef = useRef<HTMLDivElement>(null)
  const cardsRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const ctx = gsap.context(() => {
      // Animate title
      gsap.fromTo(
        titleRef.current,
        { y: 50, opacity: 0 },
        {
          y: 0,
          opacity: 1,
          duration: 1,
          scrollTrigger: {
            trigger: titleRef.current,
            start: "top 80%",
          },
        },
      )

      // Animate achievement cards
      gsap.fromTo(
        cardsRef.current?.children || [],
        { y: 80, opacity: 0 },
        {
          y: 0,
          opacity: 1,
          duration: 0.8,
          stagger: 0.2,
          ease: "power2.out",
          scrollTrigger: {
            trigger: cardsRef.current,
            start: "top 85%",
          },
        },
      )
    }, sectionRef)

    return () => ctx.revert()
  }, [])

  return (
    <section ref={sectionRef} className="py-20 bg-muted/30">
      <div className="container mx-auto px-4">
        <div ref={titleRef} className="text-center mb-16">
          <Badge variant="secondary" className="mb-4 px-4 py-2">
            🎯 Portfolio Highlights
          </Badge>
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mb-4">
            Proven <span className="text-primary">Results</span>
          </h2>
          <p className="text-lg md:text-xl text-muted-foreground max-w-3xl mx-auto">
            As a passionate fresher, I've built a comprehensive portfolio demonstrating real-world cloud engineering
            capabilities and production-ready solutions.
          </p>
        </div>

        <div ref={cardsRef} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12">
          {achievements.map((achievement, index) => {
            const IconComponent = achievement.icon
            return (
              <Card
                key={achievement.title}
                className="group hover:shadow-lg transition-all duration-300 hover:-translate-y-1 bg-card/50 backdrop-blur-sm border-border/50 text-center"
              >
                <CardContent className="p-6">
                  <div className="w-12 h-12 mx-auto mb-4 bg-primary/10 rounded-lg flex items-center justify-center group-hover:bg-primary/20 transition-colors">
                    <IconComponent className="h-6 w-6 text-primary" />
                  </div>
                  <h3 className="text-lg font-semibold mb-2 group-hover:text-primary transition-colors">
                    {achievement.title}
                  </h3>
                  <p className="text-sm text-muted-foreground mb-3">{achievement.description}</p>
                  <Badge variant="outline" className="text-xs font-medium">
                    {achievement.metric}
                  </Badge>
                </CardContent>
              </Card>
            )
          })}
        </div>

        {/* Key Skills Summary */}
        <div className="bg-card/30 backdrop-blur-sm rounded-lg p-8 border border-border/50">
          <h3 className="text-2xl font-bold text-center mb-6">Ready for Cloud & DevOps Roles</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-center">
            <div>
              <h4 className="font-semibold text-primary mb-2">Cloud Architecture</h4>
              <p className="text-sm text-muted-foreground">
                AWS Solutions Architect with hands-on experience in 25+ services
              </p>
            </div>
            <div>
              <h4 className="font-semibold text-primary mb-2">Infrastructure as Code</h4>
              <p className="text-sm text-muted-foreground">
                Terraform, CloudFormation, and automated deployment pipelines
              </p>
            </div>
            <div>
              <h4 className="font-semibold text-primary mb-2">Modern Development</h4>
              <p className="text-sm text-muted-foreground">
                Full-stack development with React, Node.js, and serverless architectures
              </p>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

export default Experience
