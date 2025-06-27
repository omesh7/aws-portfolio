// index.js
import {
  S3Client,
  HeadObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
} from "@aws-sdk/client-s3";
import sharp from "sharp";

const s3 = new S3Client({});
const SOURCE_BUCKET = process.env.SOURCE_BUCKET;
const RESIZED_BUCKET = process.env.RESIZED_BUCKET;

export async function handler(event) {
  try {
    const path = event.rawPath ?? event.path ?? "";
    const method = event.requestContext?.http?.method ?? "GET";

    if (method === "GET" && path === "/hello") {
      return { statusCode: 200, body: "hEllo" };
    }
    if (method === "POST" && path.startsWith("/upload")) {
      return await handleUpload(event);
    }
    if (method === "GET" && path.startsWith("/resize")) {
      return await handleResize(event);
    }
    return {
      statusCode: 404,
      body: JSON.stringify({ error: "Route not found" }),
    };
  } catch (err) {
    console.error("Unexpected Error:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Internal server error",
        details: err.message,
      }),
    };
  }
}

async function handleUpload(event) {
  try {
    const body = JSON.parse(event.body ?? "{}");
    const { filename, fileContentBase64, contentType = "image/jpeg" } = body;
    if (!filename || !fileContentBase64) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: "Missing filename or fileContentBase64",
        }),
      };
    }
    const valid = ["image/png", "image/jpeg", "image/webp"];
    if (!valid.includes(contentType)) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Invalid content type" }),
      };
    }
    if (!/^[a-zA-Z0-9-_]+\.[a-zA-Z0-9]+$/.test(filename)) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: "Invalid filename format" }),
      };
    }
    const buffer = Buffer.from(fileContentBase64, "base64");

    await s3.send(
      new PutObjectCommand({
        Bucket: SOURCE_BUCKET,
        Key: filename,
        Body: buffer,
        ContentType: contentType,
      })
    );

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Upload successful",
        file: filename,
        path: `${SOURCE_BUCKET}/${filename}`,
      }),
    };
  } catch (err) {
    console.error("Upload Error:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Failed to upload image",
        details: err.message,
      }),
    };
  }
}

async function handleResize(event) {
  try {
    const path = event.rawPath ?? event.path ?? "";
    const [, , widthStr, heightStr, ...keyParts] = path.split("/");
    const width = parseInt(widthStr),
      height = parseInt(heightStr);
    const key = decodeURIComponent(keyParts.join("/"));
    if (!width || !height || !key) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: "Missing width, height, or key in path.",
        }),
      };
    }

    const resizedKey = `${width}x${height}/${key}`;

    try {
      await s3.send(
        new HeadObjectCommand({ Bucket: RESIZED_BUCKET, Key: resizedKey })
      );
      return {
        statusCode: 302,
        headers: {
          Location: `http://${RESIZED_BUCKET}.s3.amazonaws.com/${resizedKey}`,
        },
      };
    } catch {}

    const original = await s3.send(
      new GetObjectCommand({ Bucket: SOURCE_BUCKET, Key: key })
    );
    const bodyStream = original.Body;
    const chunks = [];
    for await (let chunk of bodyStream) chunks.push(chunk);
    const originalBuffer = Buffer.concat(chunks);

    const resizedBuffer = await sharp(originalBuffer)
      .resize(width, height)
      .toBuffer();

    await s3.send(
      new PutObjectCommand({
        Bucket: RESIZED_BUCKET,
        Key: resizedKey,
        Body: resizedBuffer,
        ContentType: "image/jpeg",
      })
    );

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Image resized and saved",
        resizedKey,
        url: `http://${RESIZED_BUCKET}.s3.amazonaws.com/${resizedKey}`,
      }),
    };
  } catch (err) {
    console.error("Resize Error:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Failed to resize image",
        details: err.message,
      }),
    };
  }
}
