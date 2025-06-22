const { PollyClient, SynthesizeSpeechCommand } = require("@aws-sdk/client-polly");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");

const REGION = process.env.AWS_REGION;
const S3_BUCKET = process.env.S3_BUCKET;

const polly = new PollyClient({ region: REGION });
const s3 = new S3Client({ region: REGION });

async function streamToBuffer(stream) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    stream.on("data", chunk => chunks.push(chunk));
    stream.on("end", () => resolve(Buffer.concat(chunks)));
    stream.on("error", reject);
  });
}

exports.handler = async (event) => {
  let text = "Hello Clara! This is AWS Polly speaking."; // default

  try {
    // Parse body if POST
    if (event.body) {
      const body = JSON.parse(event.body);
      if (body.text && typeof body.text === 'string' && body.text.trim().length > 0) {
        text = body.text.trim();
      }
    }

    console.log("📢 Converting text to speech:", text);

    const speechCommand = new SynthesizeSpeechCommand({
      OutputFormat: "mp3",
      Text: text,
      VoiceId: "Joanna"
    });

    const pollyResponse = await polly.send(speechCommand);
    console.log("🔎 Polly response metadata:", pollyResponse.$metadata);

    if (!pollyResponse.AudioStream) {
      console.error("❌ Polly did not return audio stream:", pollyResponse);
      throw new Error("Polly failed to generate audio");
    }

    const audioBuffer = await streamToBuffer(pollyResponse.AudioStream);
    const key = `speech-${Date.now()}.mp3`;

    await s3.send(new PutObjectCommand({
      Bucket: S3_BUCKET,
      Key: key,
      Body: audioBuffer,
      ContentType: "audio/mpeg",
      ContentLength: audioBuffer.length
    }));

    console.log(`✅ File uploaded: ${key}`);
    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Speech generated and uploaded",
        file: key,
        url: `https://${S3_BUCKET}.s3.${REGION}.amazonaws.com/${key}`
      })
    };
  } catch (err) {
    console.error("❌ Error in Lambda:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message || "Unknown error" })
    };
  }
};
// File: 04-text-to-speech-polly/lambda/package.json
// --- a/file:///d%3A/PROJECTS/AWS/portfolio/final/aws-portfolio/04-text-to-speech-polly/lambda/package.json?%7B%22path%22%3A%22d%3A%5C%5CPROJECTS%5C%5CAWS%5C%5Cportfolio%5C%5Cfinal%5C%5Caws-portfolio%5C%5C04-text-to-speech-polly%5C%5Clambda%22%2C%22ref%22%3A%22HEAD%22%7D