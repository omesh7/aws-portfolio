import { type NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();

    const selectedSize = formData.get("selectedSize") as string;
    const format = (formData.get("format") as string) || "webp";
    let width: number;
    let height: number;

    if (selectedSize === "custom") {
      const customWidth = formData.get("width") as string;
      const customHeight = formData.get("height") as string;
      width = Number.parseInt(customWidth, 10);
      height = Number.parseInt(customHeight, 10);
    } else {
      const [w, h] = selectedSize.split("x").map(Number);
      width = w;
      height = h;
    }

    const imageFile = formData.get("imageFile") as File | null;

    if (!process.env.IMAGE_RESIZE_API_URL) {
      console.error("IMAGE_RESIZE_API_URL environment variable is not set");
      return NextResponse.json(
        { error: "Service configuration error. Please contact support." },
        { status: 500 }
      );
    }

    if (!imageFile) {
      return NextResponse.json(
        { error: "Please upload an image file." },
        { status: 400 }
      );
    }

    if (!width || !height || width < 10 || height < 10) {
      return NextResponse.json(
        { error: "Invalid width or height. Must be at least 10px." },
        { status: 400 }
      );
    }

    // Build the URL with query parameters as expected by your Lambda
    const apiUrl = new URL(`${process.env.IMAGE_RESIZE_API_URL}/resize`);
    apiUrl.searchParams.set("width", width.toString());
    apiUrl.searchParams.set("height", height.toString());
    apiUrl.searchParams.set("format", format);

    // Create FormData with the image file
    const requestFormData = new FormData();
    requestFormData.append("image", imageFile);

    const response = await fetch(apiUrl.toString(), {
      method: "POST",
      body: requestFormData,
      signal: AbortSignal.timeout(30000), // 30 second timeout
    });

    if (!response.ok) {
      const errorMessage = "Image processing failed. Please try again.";
      try {
        const errorData = await response.json();
        // Don't expose internal error details to client
        console.error("Lambda error response:", errorData);
      } catch (parseError) {
        console.error("Could not parse error response:", parseError);
      }
      throw new Error(errorMessage);
    }

    const data = await response.json();

    return NextResponse.json({
      resizedImageUrl: data.url,
      format: format,
    });
  } catch (err: any) {
    console.error("API Route error details:", {
      message: err.message,
      name: err.name,
    });

    // Provide generic error messages without exposing internal details
    let errorMessage =
      "Service temporarily unavailable. Please try again later.";

    if (err.name === "AbortError") {
      errorMessage = "Request timeout. Please try with a smaller image.";
    } else if (err.message.includes("Image processing failed")) {
      errorMessage = err.message;
    }

    return NextResponse.json({ error: errorMessage }, { status: 500 });
  }
}
