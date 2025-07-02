import { type NextRequest, NextResponse } from "next/server"

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const imageUrl = searchParams.get("url")

    if (!imageUrl) {
      return NextResponse.json({ error: "Missing image URL" }, { status: 400 })
    }

    // Fetch the image from S3
    const response = await fetch(imageUrl)

    if (!response.ok) {
      throw new Error("Failed to fetch image")
    }

    const imageBuffer = await response.arrayBuffer()
    const contentType = response.headers.get("content-type") || "image/webp"

    // Return the image with proper headers
    return new NextResponse(imageBuffer, {
      headers: {
        "Content-Type": contentType,
        "Content-Disposition": "attachment",
      },
    })
  } catch (error) {
    console.error("Download proxy error:", error)
    return NextResponse.json({ error: "Failed to download image" }, { status: 500 })
  }
}
