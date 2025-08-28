import type React from "react"
import type { Metadata } from "next"
import { GeistSans } from "geist/font/sans"
import { GeistMono } from "geist/font/mono"
import { ThemeProvider } from "@/components/theme-provider"

import "./globals.css"

export const metadata: Metadata = {
  title: "Omeshwar - Cloud Engineer Portfolio",
  description:
    "Passionate Aspiring DevOps Engineer showcasing 14+  AWS projects with production-ready solutions.",
  keywords: "Cloud Engineer, DevOps, AWS, Terraform, React, Portfolio, Omeshwar",
  authors: [{ name: "Omeshwar" }],
  openGraph: {
    title: "Omeshwar - Cloud Engineer Portfolio",
    description: "14+  AWS projects showcasing production-ready cloud solutions",
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
