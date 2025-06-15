// Simple handler that reuses AWS SDK client outside the function
import AWS from "aws-sdk";
const s3 = new AWS.S3(); // reused across invocations

exports.handler = async (event) => {
  console.log("Event:", JSON.stringify(event));
  // Example real-world call: list buckets
  const buckets = await s3.listBuckets().promise();
  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Hello from Lambda!", buckets }),
  };
};
