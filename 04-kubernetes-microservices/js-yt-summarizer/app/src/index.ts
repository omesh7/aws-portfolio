import "dotenv/config";
import { serve } from "@hono/node-server";
import { Hono } from "hono";
import { YoutubeTranscript } from "youtube-transcript";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { Groq } from "groq-sdk";
import OpenAI from "openai";
import * as FormData from "form-data";
import {
  extractVideoId,
  createSummaryPrompt,
  AVAILABLE_LANGUAGES,
} from "./youtube.js";

const logger = {
  info: (message: string, data?: any) => {
    console.log(
      `[INFO] ${new Date().toISOString()} - ${message}`,
      data ? JSON.stringify(data) : ""
    );
  },
  error: (message: string, error?: any) => {
    console.error(
      `[ERROR] ${new Date().toISOString()} - ${message}`,
      error?.stack || error
    );
  },
  warn: (message: string, data?: any) => {
    console.warn(
      `[WARN] ${new Date().toISOString()} - ${message}`,
      data ? JSON.stringify(data) : ""
    );
  },
};

const app = new Hono();

function getGeminiClient() {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return null;
  return new GoogleGenerativeAI(apiKey);
}

function getGroqClient() {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) return null;
  return new Groq({ apiKey });
}

function getOpenAIClient() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) return null;
  return new OpenAI({ apiKey });
}

const AI_MODELS = {
  gemini: {
    async generateContent(prompt: string) {
      const genAI = getGeminiClient();
      if (!genAI) throw new Error("Gemini API key not configured");
      const model = genAI.getGenerativeModel({ model: "gemini-2.0-flash-001" });
      const result = await model.generateContent(prompt);
      return result.response.text();
    },
  },
  groq: {
    async generateContent(prompt: string) {
      const groq = getGroqClient();
      if (!groq) throw new Error("Groq API key not configured");
      const completion = await groq.chat.completions.create({
        messages: [{ role: "user", content: prompt }],
        model: "llama-3.3-70b-versatile",
        temperature: 0.7,
        max_tokens: 2048,
      });
      return completion.choices[0]?.message?.content || "";
    },
  },
  gpt4: {
    async generateContent(prompt: string) {
      const openai = getOpenAIClient();
      if (!openai) throw new Error("OpenAI API key not configured");
      const completion = await openai.chat.completions.create({
        messages: [{ role: "user", content: prompt }],
        model: "gpt-4o-mini",
        temperature: 0.7,
        max_tokens: 2048,
      });
      return completion.choices[0]?.message?.content || "";
    },
  },
};

async function getTranscript(videoId: string) {
  logger.info("Fetching transcript", { videoId });

  try {
    const transcriptList = await YoutubeTranscript.fetchTranscript(videoId);

    //log
    logger.info("Transcript fetched successfully", {
      videoId,
      transcriptList,
    });

    if (!transcriptList || transcriptList.length === 0) {
      throw new Error("No transcript available");
    }

    const title = transcriptList
      .slice(0, 5)
      .map((item) => item.text)
      .join(" ")
      .split(".")[0]
      .trim();

    const transcript = transcriptList.map((item) => item.text).join(" ");
    logger.info("YouTube transcript fetched successfully");

    return {
      transcript,
      source: "youtube",
      title: title.length > 10 ? title : "YouTube Video Summary",
    };
  } catch (error) {
    logger.error("Failed to get transcript", { videoId, error });
    throw new Error(
      "No transcript available for this video. Please try a video with captions/subtitles."
    );
  }
}

app.get("/", (c) => {
  return c.json({
    message: "YouTube Summarizer API",
    endpoints: ["/summarize", "/health"],
  });
});

app.get("/health", (c) => {
  return c.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.post("/summarize", async (c) => {
  const startTime = Date.now();
  logger.info("Summarize request received");

  try {
    const {
      url,
      language = "English",
      mode = "video",
      aiModel = "gemini",
    } = await c.req.json();

    if (!url) {
      return c.json({ error: "URL is required" }, 400);
    }

    const videoId = extractVideoId(url);
    if (!videoId) {
      return c.json({ error: "Invalid YouTube URL" }, 400);
    }

    const selectedModel = AI_MODELS[aiModel as keyof typeof AI_MODELS];
    if (!selectedModel) {
      return c.json({ error: "Invalid AI model" }, 400);
    }

    const { transcript, title, source } = await getTranscript(videoId);
    const prompt = createSummaryPrompt(
      transcript,
      AVAILABLE_LANGUAGES[language as keyof typeof AVAILABLE_LANGUAGES] || "en",
      mode
    );

    const summary = await selectedModel.generateContent(prompt);

    const processingTime = Date.now() - startTime;
    logger.info("Summary generated successfully", {
      videoId,
      processingTime: `${processingTime}ms`,
    });

    return c.json({
      success: true,
      data: {
        title,
        summary,
        videoId,
        language,
        mode,
        aiModel,
        source,
        processingTime: `${processingTime}ms`,
      },
    });
  } catch (error: any) {
    const processingTime = Date.now() - startTime;
    logger.error("Summarize request failed", {
      error: error.message,
      processingTime: `${processingTime}ms`,
    });

    return c.json({ error: error.message || "Internal server error" }, 500);
  }
});

logger.info("Starting YouTube Summarizer API");
logger.info("Environment check", {
  geminiConfigured: !!process.env.GEMINI_API_KEY,
  groqConfigured: !!process.env.GROQ_API_KEY,
  openaiConfigured: !!process.env.OPENAI_API_KEY,
});

serve(
  {
    fetch: app.fetch,
    port: 3000,
  },
  (info) => {
    logger.info(
      `YouTube Summarizer API running on http://localhost:${info.port}`
    );
  }
);
