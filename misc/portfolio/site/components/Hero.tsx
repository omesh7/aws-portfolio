"use client";

import { useEffect, useRef, useState } from "react";
import { gsap } from "gsap";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ArrowDown, Github, Linkedin, Mail, Mic, MicOff } from "lucide-react";
import { Meteors } from "@/components/magicui/Meteors";

const Hero = () => {
  const heroRef = useRef<HTMLElement>(null);
  const textRef = useRef<HTMLDivElement>(null);
  const badgeRef = useRef<HTMLDivElement>(null);
  const [isListening, setIsListening] = useState(false);

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.fromTo(
        textRef.current?.children || [],
        { y: 20, opacity: 0 },
        {
          y: 0,
          opacity: 1,
          stagger: 0.1,
          duration: 0.6,
          ease: "power2.out",
          delay: 0.2,
        }
      );

      gsap.fromTo(
        badgeRef.current,
        { y: 10, opacity: 0 },
        {
          y: 0,
          opacity: 1,
          duration: 0.5,
          ease: "power2.out",
          delay: 0.8,
        }
      );

      gsap.to(".scroll-indicator", {
        y: 5,
        duration: 2,
        repeat: -1,
        yoyo: true,
        ease: "power2.inOut",
      });
    }, heroRef);

    return () => ctx.revert();
  }, []);

  const scrollToProjects = () => {
    document.getElementById("projects")?.scrollIntoView({ behavior: "smooth" });
  };

  const handleAITalk = () => {
    setIsListening(!isListening);
    // Placeholder for LiveKit agent integration
    console.log(
      isListening
        ? "Stopping AI conversation..."
        : "Starting AI conversation..."
    );
  };

  return (
    <section
      ref={heroRef}
      className="relative min-h-screen flex items-center justify-center overflow-hidden bg-gradient-to-br from-background via-background to-muted/10"
    >
      <div className="absolute inset-0 bg-grid-pattern opacity-3" />
      <Meteors />

      {/* Content */}
      <div className="container mx-auto px-4 text-center z-10">
        <div ref={badgeRef} className="mb-6">
          <Badge variant="secondary" className="px-4 py-2 text-sm font-medium">
            🚀 Available for Cloud & DevOps Opportunities
          </Badge>
        </div>

        <div ref={textRef} className="space-y-6 max-w-4xl mx-auto">
          <h1 className="text-4xl md:text-6xl lg:text-7xl font-bold tracking-tight">
            <span className="bg-gradient-to-r from-primary via-blue-600 to-purple-600 bg-clip-text text-transparent">
              Omeshwar V
            </span>
          </h1>

          <h2 className="text-2xl md:text-3xl lg:text-4xl font-semibold text-muted-foreground">
            Cloud Engineer & DevOps Enthusiast
          </h2>

          <p className="text-lg md:text-xl text-muted-foreground max-w-2xl mx-auto leading-relaxed">
            Passionate fresher with{" "}
            <span className="font-semibold text-foreground">
              14+ enterprise-grade AWS projects
            </span>{" "}
            showcasing production-ready solutions, Infrastructure as Code, and
            modern cloud architectures.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center pt-6">
            <div className="flex gap-3">
              <Button
                size="lg"
                onClick={scrollToProjects}
                className="px-8 py-3 text-lg font-medium"
              >
                View My Projects
              </Button>
              <Button
                size="lg"
                variant="outline"
                onClick={handleAITalk}
                className={`px-6 py-3 text-lg font-medium transition-all duration-300
    ${
      isListening
        ? "bg-primary border-primary text-primary-foreground animate-pulse dark:bg-slate-900 dark:border-slate-700 dark:text-white"
        : "bg-primary/10 hover:bg-primary/20 dark:bg-primary/20 dark:hover:bg-primary/30 text-black dark:text-white hover:text-white dark:hover:text-white"
    }
    focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 dark:focus:ring-offset-0
    active:scale-95 active:text-white dark:active:text-white`}
              >
                {isListening ? (
                  <MicOff className="h-5 w-5 mr-2" />
                ) : (
                  <Mic className="h-5 w-5 mr-2" />
                )}
                {isListening ? "Stop AI Chat" : "Talk to AI"}
              </Button>
            </div>

            <div className="flex gap-4">
              <Button variant="outline" size="icon" asChild>
                <a
                  href="https://github.com/omesh7"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <Github className="h-5 w-5" />
                </a>
              </Button>
              <Button variant="outline" size="icon" asChild>
                <a
                  href="https://linkedin.com/in/omesh7"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <Linkedin className="h-5 w-5" />
                </a>
              </Button>
              <Button variant="outline" size="icon" asChild>
                <a href="mailto:contact@omesh.site">
                  <Mail className="h-5 w-5" />
                </a>
              </Button>
            </div>
          </div>
        </div>

        {/* Scroll Indicator */}
        <div className="scroll-indicator absolute bottom-8 left-1/2 transform -translate-x-1/2">
          <ArrowDown className="h-6 w-6 text-muted-foreground" />
        </div>
      </div>
    </section>
  );
};

export default Hero;
