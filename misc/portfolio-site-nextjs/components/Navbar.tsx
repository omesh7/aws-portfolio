"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { ThemeToggle } from "@/components/theme-toggle"
import { Menu, X } from "lucide-react"
import { AnimatedThemeToggler } from "@/components/magicui/AnimatedThemeToggler";

const Navbar = () => {
  const [isScrolled, setIsScrolled] = useState(false)
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)

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

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${isScrolled ? "bg-background/80 backdrop-blur-md border-b border-border/50" : "bg-transparent"
        }`}
    >
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <div className="font-bold text-xl bg-gradient-to-r from-primary to-primary/60 bg-clip-text text-transparent">
            Omeshwar V
          </div>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-8">
            <Button variant="ghost" onClick={() => scrollToSection("projects")}>
              Projects
            </Button>
            <Button variant="ghost" onClick={() => scrollToSection("certifications")}>
              Certifications
            </Button>
            <Button variant="ghost" onClick={() => scrollToSection("experience")}>
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
              <Button
                variant="ghost"
                className="w-full justify-start"
                onClick={() => scrollToSection("certifications")}
              >
                Certifications
              </Button>
              <Button variant="ghost" className="w-full justify-start" onClick={() => scrollToSection("experience")}>
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
  )
}

export default Navbar
