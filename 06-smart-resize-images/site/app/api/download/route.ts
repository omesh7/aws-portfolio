import { type NextRequest, NextResponse } from "next/server"

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const imageUrl = searchParams.get("url")

    if (!imageUrl) {
      return NextResponse.json({ error: "Missing image URL" }, { status: 400 })
    }

    // SSRF mitigation: Only allow URLs from specific S3 bucket(s)
    let s3Url: URL;
    try {
      s3Url = new URL(imageUrl);
    } catch {
      return NextResponse.json({ error: "Invalid image URL" }, { status: 400 });
    }

    // Replace with your actual allowed S3 buckets
    const allowedHostnames = [
      "your-bucket.s3.amazonaws.com",    // Example allowed bucket (change to yours)
      "your-bucket.s3.us-east-1.amazonaws.com", // S3 regional endpoints (if needed)
    ];
    if (
      s3Url.protocol !== "https:" ||
      !allowedHostnames.includes(s3Url.hostname)
    ) {
      return NextResponse.json({ error: "Invalid image host" }, { status: 400 });
    }

    // Optionally, validate the pathname or filetype:
    // if (!s3Url.pathname.startsWith("/images/") || !/\.(jpg|jpeg|png|webp|gif)$/i.test(s3Url.pathname)) {
    //   return NextResponse.json({ error: "Invalid image path" }, { status: 400 });
    // }

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
