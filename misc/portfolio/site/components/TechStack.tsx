"use client"

import { useEffect, useRef } from "react"
import { gsap } from "gsap"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"

const techCategories = [
  {
    category: "Cloud Platforms",
    icon: "☁️",
    technologies: ["AWS", "Azure", "Google Cloud", "Cloudflare"],
  },
  {
    category: "Infrastructure as Code",
    icon: "🏗️",
    technologies: ["Terraform", "CloudFormation", "AWS CDK", "Pulumi"],
  },
  {
    category: "Serverless Computing",
    icon: "⚡",
    technologies: ["Lambda", "API Gateway", "Step Functions", "EventBridge"],
  },
  {
    category: "Frontend Development",
    icon: "🎨",
    technologies: ["React", "Next.js", "Vue.js", "TypeScript", "Three.js"],
  },
  {
    category: "Backend Development",
    icon: "⚙️",
    technologies: ["Node.js", "Python", "TypeScript", "Microservices"],
  },
  {
    category: "DevOps & CI/CD",
    icon: "🔄",
    technologies: ["GitHub Actions", "CodePipeline", "Docker", "Kubernetes"],
  },
  {
    category: "Databases",
    icon: "🗄️",
    technologies: ["DynamoDB", "RDS", "Aurora", "Redis", "Vector DBs"],
  },
  {
    category: "AI/ML Services",
    icon: "🤖",
    technologies: ["Bedrock", "SageMaker", "Rekognition", "Polly", "Textract"],
  },
  {
    category: "Monitoring & Security",
    icon: "🔒",
    technologies: ["CloudWatch", "X-Ray", "IAM", "VPC", "WAF"],
  },
]

const TechStack = () => {
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

      // Animate tech cards
      gsap.fromTo(
        cardsRef.current?.children || [],
        { y: 60, opacity: 0, scale: 0.9 },
        {
          y: 0,
          opacity: 1,
          scale: 1,
          duration: 0.6,
          stagger: 0.1,
          ease: "back.out(1.7)",
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
    <section id="skills" ref={sectionRef} className="py-20 bg-background">
      <div className="container mx-auto px-4">
        <div ref={titleRef} className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mb-4">
            Technical <span className="text-primary">Expertise</span>
          </h2>
          <p className="text-lg md:text-xl text-muted-foreground max-w-3xl mx-auto">
            Comprehensive cloud engineering skills across AWS services, modern development frameworks, and
             infrastructure solutions.
          </p>
        </div>

        <div ref={cardsRef} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {techCategories.map((category, index) => (
            <Card
              key={category.category}
              className="group hover:shadow-lg transition-all duration-300 hover:-translate-y-1 bg-card/50 backdrop-blur-sm border-border/50"
            >
              <CardContent className="p-6">
                <div className="flex items-center mb-4">
                  <span className="text-2xl mr-3">{category.icon}</span>
                  <h3 className="text-lg font-semibold group-hover:text-primary transition-colors">
                    {category.category}
                  </h3>
                </div>

                <div className="flex flex-wrap gap-2">
                  {category.technologies.map((tech) => (
                    <Badge
                      key={tech}
                      variant="secondary"
                      className="text-xs hover:bg-primary hover:text-primary-foreground transition-colors cursor-default"
                    >
                      {tech}
                    </Badge>
                  ))}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}

export default TechStack
