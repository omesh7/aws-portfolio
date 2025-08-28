"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Menu, X, Activity } from "lucide-react"
import { AnimatedThemeToggler } from "@/components/magicui/AnimatedThemeToggler"
import Link from "next/link"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"

const Navbar = () => {
  const [isScrolled, setIsScrolled] = useState(false)
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const [isExperienceModalOpen, setIsExperienceModalOpen] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50)
    }

    window.addEventListener("scroll", handleScroll)
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  const scrollToSection = (sectionId: string) => {
    document.getElementById(sectionId)?.scrollIntoView({ behavior: "smooth" })
    setIsMobileMenuOpen(false)
  }

  const handleExperienceClick = () => {
    setIsExperienceModalOpen(true)
    setIsMobileMenuOpen(false)
  }

  return (
    <>
      <nav
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${isScrolled ? "bg-background/80 backdrop-blur-md border-b border-border/50" : "bg-transparent"
          }`}
      >
        <div className="container mx-auto px-4">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <div className="font-bold text-xl bg-gradient-to-r from-primary to-primary/60 bg-clip-text text-transparent">
              Omeshwar
            </div>

            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center space-x-8">
              <Button variant="ghost" onClick={() => scrollToSection("projects")}>
                Projects
              </Button>
              <Button variant="ghost" asChild>
                <Link href="/deployments">
                  <Activity className="h-4 w-4 mr-2" />
                  Deployments
                </Link>
              </Button>
              <Button variant="ghost" onClick={() => scrollToSection("certifications")}>
                Certifications
              </Button>
              <Button variant="ghost" onClick={handleExperienceClick}>
                Experience
              </Button>
              <Button variant="ghost" onClick={() => scrollToSection("contact")}>
                Contact
              </Button>
              <AnimatedThemeToggler />
            </div>

            {/* Mobile Menu Button */}
            <div className="md:hidden flex items-center gap-2">
              <AnimatedThemeToggler />
              <Button variant="ghost" size="icon" onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}>
                {isMobileMenuOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
              </Button>
            </div>
          </div>

          {/* Mobile Menu */}
          {isMobileMenuOpen && (
            <div className="md:hidden bg-background/95 backdrop-blur-md border-t border-border/50">
              <div className="px-2 pt-2 pb-3 space-y-1">
                <Button variant="ghost" className="w-full justify-start" onClick={() => scrollToSection("projects")}>
                  Projects
                </Button>
                <Button variant="ghost" className="w-full justify-start" asChild>
                  <Link href="/deployments" onClick={() => setIsMobileMenuOpen(false)}>
                    <Activity className="h-4 w-4 mr-2" />
                    Deployments
                  </Link>
                </Button>
                <Button
                  variant="ghost"
                  className="w-full justify-start"
                  onClick={() => scrollToSection("certifications")}
                >
                  Certifications
                </Button>
                <Button variant="ghost" className="w-full justify-start" onClick={handleExperienceClick}>
                  Experience
                </Button>
                <Button variant="ghost" className="w-full justify-start" onClick={() => scrollToSection("contact")}>
                  Contact
                </Button>
              </div>
            </div>
          )}
        </div>
      </nav>

      <Dialog open={isExperienceModalOpen} onOpenChange={setIsExperienceModalOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-center">Ready to Begin My Professional Journey</DialogTitle>
          </DialogHeader>
          <div className="text-center space-y-4 pt-4">
            <div className="text-base text-muted-foreground">
              While I'm early in my career, I bring fresh perspectives, strong technical skills, and an eagerness to
              contribute meaningfully to your team.
            </div>
            <div className="text-sm text-muted-foreground">
              I'm actively seeking opportunities to apply my knowledge, learn from experienced professionals, and prove
              my capabilities through real-world projects.
            </div>
            <div className="pt-4">
              <Button
                onClick={() => scrollToSection("contact")}
                className="w-full"
                onClickCapture={() => setIsExperienceModalOpen(false)}
              >
                Let's Connect
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </>
  )
}

export default Navbar
