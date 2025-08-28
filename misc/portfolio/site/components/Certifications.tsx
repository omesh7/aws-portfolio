import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { ExternalLink, Award, Calendar } from "lucide-react"
import Image from "next/image"

const certifications = [
  {
    name: "AWS Certified Cloud Practitioner",
    issuer: "Amazon Web Services",
    badgeImage: "/certificates-badge/aws-cloud-practitioner.png",
    date: "2025",
    status: "Active",
    description:
      "Foundational understanding of AWS Cloud concepts, services, security, architecture, pricing, and support.",
    skills: ["Cloud Concepts", "AWS Services", "Security & Compliance", "Billing & Pricing"],
    credentialUrl: "https://www.credly.com/badges/cd87e5bd-2f5c-4b0b-a779-8018344a673e",
    badgeColor: "bg-orange-500/10 text-orange-600 border-orange-200",
  },
  {
    name: "HashiCorp Certified: Terraform Associate",
    issuer: "HashiCorp",
    badgeImage: "/certificates-badge/terraform-c-a.png",
    date: "2025",
    status: "Active",
    description: "Infrastructure as Code expertise using Terraform for cloud resource provisioning and management.",
    skills: ["Infrastructure as Code", "Terraform Configuration", "State Management", "Modules & Providers"],
    credentialUrl: "https://www.credly.com/badges/cdbc9a22-d6d4-44f4-b9f3-61f01d566967",
    badgeColor: "bg-purple-500/10 text-purple-600 border-purple-200",
  },
]

const Certifications = () => {
  return (
    <section id="certifications" className="py-20 bg-muted/20">
      <div className="container mx-auto px-4">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl lg:text-5xl font-bold mb-4">
            <span className="text-primary">Certifications</span>
          </h2>
          <p className="text-lg md:text-xl text-muted-foreground max-w-3xl mx-auto">
            Industry-recognized certifications validating expertise in cloud computing and infrastructure automation.
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 max-w-5xl mx-auto">
          {certifications.map((cert, index) => (
            <Card
              key={cert.name}
              className="group hover:shadow-xl transition-all duration-300 hover:-translate-y-2 bg-card/80 backdrop-blur-sm border-border/50 overflow-hidden"
            >
              <CardContent className="p-8">
                {/* Header */}
                <div className="flex items-start justify-between mb-6">
                  <div className="flex items-center">
                    <div className="mr-4 p-2 rounded-lg bg-primary/10 w-16 h-16 flex items-center justify-center">
                      {cert.badgeImage ? (
                        <Image
                          src={cert.badgeImage}
                          alt={`${cert.name} Badge`}
                          width={60}
                          height={60}
                          className="object-contain"
                        />
                      ) : (
                        <div className="text-center text-muted-foreground">
                          <Award className="w-6 h-6 mx-auto mb-1" />
                          <p className="text-xs">Coming Soon</p>
                        </div>
                      )}
                    </div>
                    <div>
                      <h3 className="text-xl font-bold group-hover:text-primary transition-colors mb-1">{cert.name}</h3>
                      <p className="text-muted-foreground font-medium">{cert.issuer}</p>
                    </div>
                  </div>
                  <Badge className={`bg-green-500/10 text-green-600 border-green-200   font-medium`}>
                    <Award className="w-3 h-3 mr-1" />
                    {cert.status}
                  </Badge>
                </div>

                {/* Date */}
                <div className="flex items-center mb-4 text-sm text-muted-foreground">
                  <Calendar className="w-4 h-4 mr-2" />
                  Earned in {cert.date}
                </div>

                {/* Description */}
                <p className="text-muted-foreground mb-6 leading-relaxed">{cert.description}</p>

                {/* Skills */}
                <div className="mb-6">
                  <h4 className="text-sm font-semibold mb-3 text-foreground">Key Competencies:</h4>
                  <div className="flex flex-wrap gap-2">
                    {cert.skills.map((skill) => (
                      <Badge
                        key={skill}
                        variant="secondary"
                        className="text-xs hover:bg-primary hover:text-primary-foreground transition-colors"
                      >
                        {skill}
                      </Badge>
                    ))}
                  </div>
                </div>

                {/* Credential Link */}
                <Button
                  variant="outline"
                  className="w-full group-hover:bg-primary group-hover:text-primary-foreground transition-colors bg-transparent"
                  asChild
                >
                  <a href={cert.credentialUrl} target="_blank" rel="noopener noreferrer">
                    <ExternalLink className="w-4 h-4 mr-2" />
                    View Credential
                  </a>
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Additional Info */}
        <div className="text-center mt-12">
          <p className="text-muted-foreground">
            Continuously expanding knowledge through hands-on projects and industry best practices
          </p>
        </div>
      </div>
    </section>
  )
}

export default Certifications
