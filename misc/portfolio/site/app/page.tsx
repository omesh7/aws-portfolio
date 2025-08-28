import Navbar from "@/components/Navbar"
import Hero from "@/components/Hero"
import ProjectsShowcase from "@/components/ProjectsShowcase"
import TechStack from "@/components/TechStack"
import Certifications from "@/components/Certifications"
import Experience from "@/components/Experience"
import Contact from "@/components/Contact"
import ContactForm from "@/components/ContactForm"
import Footer from "@/components/Footer"

export default function Home() {
  return (
    <main className="min-h-screen bg-background">
      <Navbar />
      <Hero />
      <ProjectsShowcase />
      <TechStack />
      <Certifications />
      {/* <Experience /> */}
      <Contact />
      <ContactForm />
      <Footer />
    </main>
  )
}
