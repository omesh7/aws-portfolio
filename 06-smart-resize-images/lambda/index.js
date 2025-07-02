import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import sharp from "sharp";
import busboy from "busboy";
import { v4 as uuidv4 } from "uuid";
import path from "path";

const s3 = new S3Client({ region: process.env.REGION || "ap-south-1" });
const BUCKET_NAME = process.env.BUCKET_NAME;

const contentTypeMap = {
  jpeg: "image/jpeg",
  jpg: "image/jpeg",
  png: "image/png",
  webp: "image/webp",
};

export const handler = async (event) => {
  console.log("Received event:", JSON.stringify(event));

  const method = event?.requestContext?.http?.method || "GET";
  const pathName = event?.rawPath || "/";

  try {
    // Route: GET /hello
    if (method === "GET" && pathName === "/hello") {
      return jsonResponse({ message: "Lambda is alive 🚀" });
    }

    // Route: POST /resize
    if (method === "POST" && pathName === "/resize") {
      const width = parseInt(event.queryStringParameters?.width);
      const height = parseInt(event.queryStringParameters?.height);
      const formatParam = event.queryStringParameters?.format || "webp";

      if (!width || !height || width < 10 || height < 10) {
        return badRequest("Missing or invalid width/height");
      }

      if (!contentTypeMap[formatParam]) {
        return badRequest(`Unsupported format: ${formatParam}`);
      }

      const contentTypeHeader =
        event.headers["content-type"] || event.headers["Content-Type"];
      if (!contentTypeHeader?.startsWith("multipart/form-data")) {
        return badRequest("Content-Type must be multipart/form-data");
      }

      const { buffer, filename } = await parseMultipart(
        event.body,
        contentTypeHeader,
        event.isBase64Encoded
      );

      if (!buffer || !filename) {
        return badRequest("Image file not received");
      }

      const outputBuffer = await sharp(buffer)
        .resize(width, height)
        .toFormat(formatParam)
        .toBuffer();

      const ext = formatParam === "jpeg" ? "jpg" : formatParam;
      const key = `resized/${uuidv4()}-${sanitizeFilename(filename, ext)}`;

      await s3.send(
        new PutObjectCommand({
          Bucket: BUCKET_NAME,
          Key: key,
          Body: outputBuffer,
          ContentType: contentTypeMap[formatParam],
        })
      );

      const url = `https://${BUCKET_NAME}.s3.${
        process.env.REGION || "ap-south-1"
      }.amazonaws.com/${key}`;
      return jsonResponse({ url });
    }

    return notFound(pathName);
  } catch (err) {
    console.error("Unhandled error:", err);
    return errorResponse(err.message || "Something went wrong");
  }
};

// ===================== HELPERS =====================

function sanitizeFilename(filename, ext) {
  const base = path.basename(filename, path.extname(filename));
  return `${base.replace(/\W+/g, "-").toLowerCase()}.${ext}`;
}

async function parseMultipart(body, contentType, isBase64Encoded) {
  const bb = busboy({ headers: { "content-type": contentType } });

  return new Promise((resolve, reject) => {
    let buffer = null;
    let filename = null;

    bb.on("file", (_, file, info) => {
      const chunks = [];
      filename = info.filename;
      file.on("data", (chunk) => chunks.push(chunk));
      file.on("end", () => (buffer = Buffer.concat(chunks)));
    });

    bb.on("finish", () => resolve({ buffer, filename }));
    bb.on("error", reject);

    const input = Buffer.from(body, isBase64Encoded ? "base64" : undefined);
    bb.end(input);
  });
}

const jsonResponse = (obj) => ({
  statusCode: 200,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(obj),
});

const badRequest = (msg) => ({
  statusCode: 400,
  body: JSON.stringify({ error: msg }),
  headers: { "Content-Type": "application/json" },
});

const notFound = (path) => ({
  statusCode: 404,
  body: JSON.stringify({ error: `No handler for path: ${path}` }),
  headers: { "Content-Type": "application/json" },
});

const errorResponse = (msg) => ({
  statusCode: 500,
  body: JSON.stringify({ error: "Internal Server Error", details: msg }),
  headers: { "Content-Type": "application/json" },
});
