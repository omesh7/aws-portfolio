import type React from "react"
import type { Metadata } from "next"
import { GeistSans } from "geist/font/sans"
import { GeistMono } from "geist/font/mono"
import { ThemeProvider } from "@/components/theme-provider"

import "./globals.css"

export const metadata: Metadata = {
  title: "Omeshwar V - Cloud Engineer Portfolio",
  description:
    "Passionate Cloud Engineer & DevOps Enthusiast showcasing 14+ enterprise-grade AWS projects with production-ready solutions.",
  keywords: "Cloud Engineer, DevOps, AWS, Terraform, React, Portfolio, Omeshwar V",
  authors: [{ name: "Omeshwar V" }],
  openGraph: {
    title: "Omeshwar V - Cloud Engineer Portfolio",
    description: "14+ enterprise-grade AWS projects showcasing production-ready cloud solutions",
    type: "website",
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <style>{`
html {
  font-family: ${GeistSans.style.fontFamily};
  --font-sans: ${GeistSans.variable};
  --font-mono: ${GeistMono.variable};
}
        `}</style>
      </head>
      <body className={`${GeistSans.variable} ${GeistMono.variable} antialiased`}>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem disableTransitionOnChange>
              

          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
