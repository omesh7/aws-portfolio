const fs = require("fs");
const path = require("path");
const axios = require("axios");
const dotenv = require("dotenv");

// Load environment variables from .env file located in the same directory
dotenv.config({ path: path.join(__dirname, ".env") });

// Validate required environment variables
const API_ENDPOINT = process.env.API_ENDPOINT;
const FILENAME = process.env.FILENAME;

if (!API_ENDPOINT) {
  throw new Error("❌ Missing required environment variable: API_ENDPOINT");
}

if (!FILENAME) {
  throw new Error("❌ Missing required environment variable: FILENAME");
}

// Construct upload URL
const UPLOAD_ENDPOINT = `${API_ENDPOINT}/upload`;

// Build the full path to the image file
const IMAGE_PATH = path.join(__dirname, FILENAME);

// Ensure the image file exists
if (!fs.existsSync(IMAGE_PATH)) {
  throw new Error(`❌ Image file not found at path: ${IMAGE_PATH}`);
}

console.log("🚀 Starting image upload...");
console.log("📡 Uploading to:", UPLOAD_ENDPOINT);

/**
 * Reads an image file, encodes it as Base64,
 * and sends it to the upload endpoint.
 */
async function uploadImage() {
  try {
    // Read image file from disk
    const fileBuffer = fs.readFileSync(IMAGE_PATH);
    const fileBase64 = fileBuffer.toString("base64");

    // Make POST request to upload the image
    const response = await axios.post(
      UPLOAD_ENDPOINT,
      {
        filename: FILENAME,
        fileContentBase64: fileBase64,
      },
      {
        headers: {
          "Content-Type": "application/json",
        },
      }
    );

    console.log("✅ Upload successful:", response.data);
  } catch (err) {
    console.error("❌ Upload failed:", err.response?.data || err.message);
  }
}

// Run the upload function
uploadImage();
