import { type NextRequest, NextResponse } from "next/server";
import sharp from "sharp";

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

    // Primary: Lambda processing
    if (process.env.IMAGE_RESIZE_API_URL) {
      try {
        const apiUrl = new URL(`${process.env.IMAGE_RESIZE_API_URL}/resize`);
        apiUrl.searchParams.set("width", width.toString());
        apiUrl.searchParams.set("height", height.toString());
        apiUrl.searchParams.set("format", format);

        const requestFormData = new FormData();
        requestFormData.append("imageFile", imageFile);

        const response = await fetch(apiUrl.toString(), {
          method: "POST",
          body: requestFormData,
          signal: AbortSignal.timeout(30000),
        });

        if (response.ok) {
          const data = await response.json();
          return NextResponse.json({
            resizedImageUrl: data.url,
            format: format,
          });
        }
      } catch (lambdaError) {
        console.error("Lambda processing failed, falling back to local:", lambdaError);
      }
    }

    // Fallback: Local processing with Sharp
    console.log("Using local Sharp processing");
    const buffer = Buffer.from(await imageFile.arrayBuffer());
    const processedBuffer = await sharp(buffer)
      .resize(width, height)
      .toFormat(format as keyof sharp.FormatEnum)
      .toBuffer();

    const base64 = processedBuffer.toString('base64');
    const mimeType = format === 'jpeg' ? 'image/jpeg' : `image/${format}`;
    const dataUrl = `data:${mimeType};base64,${base64}`;

    return NextResponse.json({
      resizedImageUrl: dataUrl,
      format: format,
    });
  } catch (err: any) {
    console.error("Image processing error:", err.message);
    return NextResponse.json({ error: "Failed to process image" }, { status: 500 });
  }
}
