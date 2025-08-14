"use client"

import { useEffect } from "react"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import Navbar from "@/components/Navbar"
import Hero from "@/components/Hero"
import ProjectsShowcase from "@/components/ProjectsShowcase"
import TechStack from "@/components/TechStack"
import Certifications from "@/components/Certifications"
import Experience from "@/components/Experience"
import Contact from "@/components/Contact"
import Footer from "@/components/Footer"

// Register GSAP plugins
if (typeof window !== "undefined") {
  gsap.registerPlugin(ScrollTrigger)
}

export default function Home() {
  useEffect(() => {
    // Initialize smooth scrolling and global animations
    gsap.set("body", { overflow: "visible" })

    // Refresh ScrollTrigger on load
    ScrollTrigger.refresh()

    return () => {
      ScrollTrigger.getAll().forEach((trigger) => trigger.kill())
    }
  }, [])

  return (
    <main className="min-h-screen bg-background">
      <Navbar />
      <Hero />
      <ProjectsShowcase />
      <TechStack />
      <Certifications />
      <Experience />
      <Contact />
      <Footer />
    </main>
  )
}
