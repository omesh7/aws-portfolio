"use client"

import type React from "react"

import { useState, useRef } from "react"
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Label } from "@/components/ui/label"
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Loader2, Upload, Download, ExternalLink } from "lucide-react"
import Image from "next/image"

export default function ImageResizer() {
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [selectedSize, setSelectedSize] = useState("800x800")
  const [customWidth, setCustomWidth] = useState("")
  const [customHeight, setCustomHeight] = useState("")
  const [format, setFormat] = useState("webp")
  const [resizedImageUrl, setResizedImageUrl] = useState<string | null>(null)
  const [resizedFormat, setResizedFormat] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [downloadError, setDownloadError] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setError(null)
    setDownloadError(null)
    setResizedImageUrl(null)
    setIsLoading(true)

    let width: number | undefined
    let height: number | undefined

    if (selectedSize === "custom") {
      width = Number.parseInt(customWidth, 10)
      height = Number.parseInt(customHeight, 10)
      if (isNaN(width) || isNaN(height) || width < 10 || height < 10) {
        setError("Please enter valid dimensions (minimum 10px).")
        setIsLoading(false)
        return
      }
    } else {
      const [w, h] = selectedSize.split("x").map(Number)
      if (isNaN(w) || isNaN(h)) {
        setError("Invalid resize size selected.")
        setIsLoading(false)
        return
      }
    }

    if (!imageFile) {
      setError("Please upload an image file.")
      setIsLoading(false)
      return
    }

    // Check file size (optional - add reasonable limits)
    const maxSize = 10 * 1024 * 1024 // 10MB
    if (imageFile.size > maxSize) {
      setError("File size too large. Please upload an image smaller than 10MB.")
      setIsLoading(false)
      return
    }

    try {
      const formData = new FormData()
      formData.append("imageFile", imageFile)
      formData.append("selectedSize", selectedSize)
      formData.append("format", format)
      if (selectedSize === "custom") {
        formData.append("width", customWidth)
        formData.append("height", customHeight)
      }

      const response = await fetch("/api/resize", {
        method: "POST",
        body: formData,
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.error || `Server error: ${response.status}`)
      }

      const data = await response.json()
      setResizedImageUrl(data.resizedImageUrl)
      setResizedFormat(data.format)
    } catch (err: any) {
      console.error("Client error:", err)
      setError(err.message || "An unexpected error occurred.")
    } finally {
      setIsLoading(false)
    }
  }

  const handleDownload = async () => {
    if (!resizedImageUrl) return

    setDownloadError(null)

    try {
      // Create a proxy endpoint to handle CORS issues
      const response = await fetch(`/api/download?url=${encodeURIComponent(resizedImageUrl)}`)

      if (!response.ok) {
        throw new Error("Failed to download image")
      }

      const blob = await response.blob()
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = `resized-image.${resizedFormat || "webp"}`
      document.body.appendChild(a)
      a.click()
      window.URL.revokeObjectURL(url)
      document.body.removeChild(a)
    } catch (error) {
      console.error("Download failed:", error)
      setDownloadError("Download failed. You can try opening the image in a new tab and saving it manually.")
    }
  }

  return (
    <Card className="w-full max-w-2xl shadow-lg">
      <CardHeader>
        <CardTitle className="text-2xl font-bold">Image Resizer</CardTitle>
        <CardDescription>Upload an image to resize it to your desired dimensions and format.</CardDescription>
      </CardHeader>
      <CardContent className="grid gap-6">
        <form onSubmit={handleSubmit}>
          <div className="grid gap-2">
            <Label htmlFor="imageUpload">Upload Image</Label>
            <Input
              id="imageUpload"
              type="file"
              accept="image/*"
              ref={fileInputRef}
              onChange={(e) => setImageFile(e.target.files ? e.target.files[0] : null)}
              aria-label="Image upload input"
              required
            />
            {imageFile && (
              <p className="text-sm text-muted-foreground">
                Selected: {imageFile.name} ({(imageFile.size / 1024 / 1024).toFixed(2)} MB)
              </p>
            )}
          </div>

          <div className="grid gap-2 mt-4">
            <Label htmlFor="resizeSize">Resize Size</Label>
            <Select value={selectedSize} onValueChange={setSelectedSize} aria-label="Select resize size">
              <SelectTrigger id="resizeSize">
                <SelectValue placeholder="Select a size" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="200x200">200x200</SelectItem>
                <SelectItem value="400x400">400x400</SelectItem>
                <SelectItem value="800x800">800x800</SelectItem>
                <SelectItem value="1200x1200">1200x1200</SelectItem>
                <SelectItem value="custom">Custom</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {selectedSize === "custom" && (
            <div className="grid grid-cols-2 gap-4 mt-4">
              <div className="grid gap-2">
                <Label htmlFor="customWidth">Width (px)</Label>
                <Input
                  id="customWidth"
                  type="number"
                  placeholder="e.g., 1200"
                  value={customWidth}
                  onChange={(e) => setCustomWidth(e.target.value)}
                  aria-label="Custom width input"
                  min="10"
                />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="customHeight">Height (px)</Label>
                <Input
                  id="customHeight"
                  type="number"
                  placeholder="e.g., 800"
                  value={customHeight}
                  onChange={(e) => setCustomHeight(e.target.value)}
                  aria-label="Custom height input"
                  min="10"
                />
              </div>
            </div>
          )}

          <div className="grid gap-2 mt-4">
            <Label htmlFor="format">Output Format</Label>
            <Select value={format} onValueChange={setFormat} aria-label="Select output format">
              <SelectTrigger id="format">
                <SelectValue placeholder="Select format" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="webp">WebP (Recommended)</SelectItem>
                <SelectItem value="jpeg">JPEG</SelectItem>
                <SelectItem value="png">PNG</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <Button type="submit" disabled={isLoading || !imageFile} className="w-full mt-6">
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Processing...
              </>
            ) : (
              <>
                <Upload className="mr-2 h-4 w-4" />
                Resize Image
              </>
            )}
          </Button>
        </form>

        {error && (
          <Alert variant="destructive" className="mt-4">
            <AlertTitle>Error</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}

        {downloadError && (
          <Alert variant="destructive" className="mt-4">
            <AlertTitle>Download Error</AlertTitle>
            <AlertDescription>{downloadError}</AlertDescription>
          </Alert>
        )}

        {resizedImageUrl && (
          <div className="grid gap-4 mt-4">
            <h3 className="text-lg font-semibold">Resized Image</h3>
            <div className="relative flex items-center justify-center overflow-hidden rounded-md border border-gray-200 bg-gray-50 p-4 dark:border-gray-800 dark:bg-gray-950">
              <Image
                src={resizedImageUrl || "/placeholder.svg"}
                alt="Resized Image"
                width={800}
                height={600}
                className="max-w-full h-auto object-contain"
                priority
              />
            </div>

            <div className="grid gap-2">
              <Label htmlFor="resizedImageUrl">Resized Image URL</Label>
              <Input
                id="resizedImageUrl"
                type="text"
                value={resizedImageUrl}
                readOnly
                className="text-xs md:text-sm"
                aria-label="Resized image URL"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-2">
              <Button
                onClick={() => navigator.clipboard.writeText(resizedImageUrl || "")}
                variant="outline"
                className="w-full"
              >
                Copy URL
              </Button>
              <Button onClick={handleDownload} variant="outline" className="w-full bg-transparent">
                <Download className="mr-2 h-4 w-4" />
                Download
              </Button>
              <Button onClick={() => window.open(resizedImageUrl, "_blank")} variant="outline" className="w-full">
                <ExternalLink className="mr-2 h-4 w-4" />
                Open
              </Button>
            </div>

            <div className="text-sm text-muted-foreground">
              Format: {resizedFormat?.toUpperCase() || "WebP"} • Stored in AWS S3
            </div>
          </div>
        )}
      </CardContent>
      <CardFooter className="text-sm text-muted-foreground">Powered by Next.js, AWS Lambda, and S3 storage.</CardFooter>
    </Card>
  )
}
