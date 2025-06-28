import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import sharp from "sharp";
import busboy from "busboy";
import { v4 as uuidv4 } from "uuid";

const s3 = new S3Client({ region: "ap-south-1" });
const BUCKET_NAME = process.env.BUCKET_NAME;

export const handler = async (event) => {
  if (event.requestContext.http.method !== "POST") {
    return {
      statusCode: 405,
      body: JSON.stringify({ error: "Method Not Allowed" }),
    };
  }

  const width = parseInt(event.queryStringParameters?.width);
  const height = parseInt(event.queryStringParameters?.height);

  if (!width || !height) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Missing width or height" }),
    };
  }

  const contentType =
    event.headers["content-type"] || event.headers["Content-Type"];
  const bb = busboy({ headers: { "content-type": contentType } });

  let uploadBuffer = null;
  let filename = null;

  const result = await new Promise((resolve, reject) => {
    bb.on("file", (_, file, info) => {
      const chunks = [];
      filename = info.filename;

      file.on("data", (chunk) => chunks.push(chunk));
      file.on("end", () => {
        uploadBuffer = Buffer.concat(chunks);
      });
    });

    bb.on("finish", () => resolve());
    bb.on("error", reject);

    bb.end(
      Buffer.from(event.body, event.isBase64Encoded ? "base64" : undefined)
    );
  });

  const resizedBuffer = await sharp(uploadBuffer)
    .resize(width, height)
    .toBuffer();
  const key = `resized/${uuidv4()}-${filename}`;

  await s3.send(
    new PutObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
      Body: resizedBuffer,
      ACL: "public-read",
      ContentType: "image/jpeg",
    })
  );

  return {
    statusCode: 200,
    body: JSON.stringify({
      url: `https://${BUCKET_NAME}.s3.ap-south-1.amazonaws.com/${key}`,
    }),
    headers: { "Content-Type": "application/json" },
  };
};
