import { S3Client, paginateListObjectsV2 } from "@aws-sdk/client-s3";
import { LambdaClient, paginateListFunctions } from "@aws-sdk/client-lambda";

const region = "ap-south-1";
const BUCKET_NAME = "05-smart-resizer-source-images-aws-portfolio";

const s3 = new S3Client({ region });
const lambda = new LambdaClient({ region });

export const handler = async (event) => {
  const path = event.rawPath || "/";
  console.log("Request path:", path);

  try {
    if (path === "/files") {
      const files = [];
      const paginator = paginateListObjectsV2(
        { client: s3 },
        { Bucket: BUCKET_NAME }
      );

      for await (const page of paginator) {
        if (page.Contents) {
          files.push(...page.Contents.map((obj) => obj.Key));
        }
      }

      return jsonResponse({ files });
    }

    if (path === "/func") {
      const functions = [];
      const paginator = paginateListFunctions({ client: lambda }, {});

      for await (const page of paginator) {
        if (page.Functions) {
          functions.push(...page.Functions.map((fn) => fn.FunctionName));
        }
      }

      return jsonResponse({ functions });
    }

    return notFoundResponse(path);
  } catch (err) {
    console.error("Error:", err);
    return errorResponse(err);
  }
};

const jsonResponse = (bodyObj) => ({
  statusCode: 200,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(bodyObj),
});

const notFoundResponse = (path) => ({
  statusCode: 404,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ error: "Unknown route", path }),
});

const errorResponse = (err) => ({
  statusCode: 500,
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    error: "Internal Server Error",
    details: err.message,
  }),
});
