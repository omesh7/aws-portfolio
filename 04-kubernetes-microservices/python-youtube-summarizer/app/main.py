"""
YouTube Video Summarizer API
Scalable FastAPI application for summarizing YouTube videos using AI models.
"""

import os
import json
import logging
import asyncio
import tempfile
from typing import Dict, List, Optional, AsyncGenerator
from dataclasses import dataclass
import re
import dotenv
import speech_recognition as sr
import boto3

# Third-party imports
import yt_dlp
import openai
import google.generativeai as genai
from groq import Groq
from youtube_transcript_api import YouTubeTranscriptApi
import sqlite3

# FastAPI imports
from fastapi import FastAPI, WebSocket
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import urllib.parse

# Load environment variables
dotenv.load_dotenv()

# Configuration
LOG_ENABLED = os.getenv("LOG_ENABLED", "true").lower() == "true"
USE_FREE_STT = os.getenv("USE_FREE_STT", "true").lower() == "true"

# Model configuration
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-1.5-flash-latest")
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3-8b-8192")
OPENAI_MODEL = os.getenv("OPENAI_MODEL", "gpt-3.5-turbo")
BEDROCK_MODEL = os.getenv("BEDROCK_MODEL", "anthropic.claude-3-haiku-20240307-v1:0")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

# Logging setup
logger = logging.getLogger("youtube_processor")
if LOG_ENABLED:
    logging.basicConfig(level=logging.INFO)

@dataclass
class TranscriptResult:
    transcript: str
    source: str
    title: str

@dataclass
class ProcessingProgress:
    type: str
    current_chunk: int = 0
    total_chunks: int = 0
    stage: str = ""
    message: str = ""
    summary: str = ""
    source: str = ""
    status: str = ""
    error: str = ""

class YouTubeVideoProcessor:
    MODEL_NAMES = {
        "gemini": f"Google Gemini ({GEMINI_MODEL})", 
        "groq": f"Groq ({GROQ_MODEL})", 
        "gpt4": f"OpenAI ({OPENAI_MODEL})",
        "bedrock": f"AWS Bedrock ({BEDROCK_MODEL})"
    }

    def __init__(self):
        self.db_path = "summaries.db"
        self._setup_database()
        self._initialize_clients()

    def _setup_database(self):
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS summaries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                video_id TEXT NOT NULL,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                language TEXT NOT NULL,
                mode TEXT NOT NULL,
                source TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(video_id, language)
            )
        """)
        conn.commit()
        conn.close()

    def _initialize_clients(self):
        self.clients = {}

        # Gemini
        if os.getenv("GEMINI_API_KEY"):
            genai.configure(api_key=os.getenv("GEMINI_API_KEY"))
            self.clients["gemini"] = genai.GenerativeModel(GEMINI_MODEL)

        # Groq
        if os.getenv("GROQ_API_KEY"):
            self.clients["groq"] = Groq(api_key=os.getenv("GROQ_API_KEY"))

        # OpenAI
        if os.getenv("OPENAI_API_KEY"):
            client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
            self.clients["openai"] = client
            self.clients["gpt4"] = client

        # AWS Bedrock
        try:
            bedrock_client = boto3.client(
                "bedrock-runtime",
                region_name=AWS_REGION,
                aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
                aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY")
            )
            self.clients["bedrock"] = bedrock_client
        except:
            pass

    def check_api_availability(self) -> Dict[str, bool]:
        return {
            "gemini": "gemini" in self.clients,
            "groq": "groq" in self.clients,
            "gpt4": "gpt4" in self.clients,
            "bedrock": "bedrock" in self.clients,
        }

    def extract_video_id(self, url: str) -> str:
        if len(url) == 11 and url.replace('-', '').replace('_', '').isalnum():
            return url
        if url.startswith('v='):
            return url[2:]
        if not url.startswith(('http://', 'https://')):
            if 'youtube.com' in url or 'youtu.be' in url:
                url = 'https://' + url
        
        patterns = [
            r"(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([^&\n?#]+)",
            r"youtube\.com\/v\/([^&\n?#]+)",
            r"youtube\.com\/watch\?.*v=([^&\n?#]+)",
        ]
        
        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1)
        
        raise ValueError(f"Could not extract video ID from URL: {url}")

    async def generate_with_ai(self, prompt: str, model: str = "gemini") -> str:
        if model not in self.clients:
            raise ValueError(f"Model {model} not available")

        if model == "gemini":
            response = await asyncio.to_thread(self.clients["gemini"].generate_content, prompt)
            return response.text
        elif model == "groq":
            response = await asyncio.to_thread(
                self.clients["groq"].chat.completions.create,
                messages=[{"role": "user", "content": prompt}],
                model=GROQ_MODEL,
                temperature=0.7,
                max_tokens=2048,
            )
            return response.choices[0].message.content
        elif model == "gpt4":
            response = await asyncio.to_thread(
                self.clients["openai"].chat.completions.create,
                messages=[{"role": "user", "content": prompt}],
                model=OPENAI_MODEL,
                temperature=0.7,
                max_tokens=2048,
            )
            return response.choices[0].message.content
        elif model == "bedrock":
            body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 2048,
                "temperature": 0.7,
                "messages": [{"role": "user", "content": prompt}]
            }
            response = await asyncio.to_thread(
                self.clients["bedrock"].invoke_model,
                modelId=BEDROCK_MODEL,
                body=json.dumps(body)
            )
            response_body = json.loads(response['body'].read())
            return response_body['content'][0]['text']

    async def get_transcript(self, video_id: str) -> TranscriptResult:
        try:
            # Try different approaches to get transcript
            transcript_list = None
            
            # First try: Get any available transcript
            try:
                transcript_list = YouTubeTranscriptApi.get_transcript(video_id)
            except:
                pass
                
            # Second try: Try specific language codes
            if not transcript_list:
                for lang in ['en', 'en-US', 'en-GB', 'auto']:
                    try:
                        transcript_list = YouTubeTranscriptApi.get_transcript(video_id, languages=[lang])
                        break
                    except:
                        continue
            
            # Third try: Get list of available transcripts and use first one
            if not transcript_list:
                try:
                    transcript_list_info = YouTubeTranscriptApi.list_transcripts(video_id)
                    for transcript_info in transcript_list_info:
                        try:
                            transcript_list = transcript_info.fetch()
                            break
                        except:
                            continue
                except:
                    pass
                
            if not transcript_list:
                raise ValueError("No transcript available for this video")
                
            first_lines = " ".join([item["text"] for item in transcript_list[:5]])
            title = first_lines.split(".")[0].strip()
            if len(title) > 100:
                title = title[:97] + "..."
            if len(title) < 10:
                title = "YouTube Video Summary"
            transcript_text = " ".join([item["text"] for item in transcript_list])
            return TranscriptResult(transcript=transcript_text, source="youtube", title=title)
        except Exception as e:
            if "Sign in to confirm" in str(e) or "bot" in str(e):
                # Try yt-dlp with cookies as fallback
                try:
                    return await self.get_transcript_with_ytdlp(video_id)
                except:
                    raise ValueError("YouTube is blocking access. Try these videos instead: jNQXAC9IVRw, M7lc1UVf-VE, or 9bZkp7q19f0")
            raise ValueError(f"Transcript not available: {str(e)}")
    
    async def get_transcript_with_ytdlp(self, video_id: str) -> TranscriptResult:
        """Fallback method using yt-dlp with cookies to get video info and subtitles."""
        try:
            ydl_opts = {
                'writesubtitles': True,
                'writeautomaticsub': True,
                'subtitleslangs': ['en', 'en-US'],
                'skip_download': True,
                'quiet': not LOG_ENABLED,
                # Try to use browser cookies to avoid bot detection
                'cookiesfrombrowser': ('chrome', None, None, None),
                # Additional options to avoid bot detection
                'extractor_args': {
                    'youtube': {
                        'skip': ['hls', 'dash'],
                        'player_skip': ['configs'],
                    }
                },
            }
            
            video_url = f"https://www.youtube.com/watch?v={video_id}"
            
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = await asyncio.to_thread(ydl.extract_info, video_url, download=False)
                
            title = info.get('title', 'YouTube Video Summary')
            
            # Try to get subtitles from the extracted info
            subtitles = info.get('subtitles', {})
            automatic_captions = info.get('automatic_captions', {})
            
            transcript_text = ""
            
            # Try manual subtitles first
            for lang in ['en', 'en-US', 'en-GB']:
                if lang in subtitles:
                    # This would need additional processing to download and parse subtitle files
                    break
            
            # If no manual subtitles, try automatic captions
            if not transcript_text:
                for lang in ['en', 'en-US', 'en-GB']:
                    if lang in automatic_captions:
                        # This would need additional processing to download and parse caption files
                        break
            
            if not transcript_text:
                raise ValueError("No subtitles available via yt-dlp")
                
            return TranscriptResult(transcript=transcript_text, source="yt-dlp", title=title)
            
        except Exception as e:
            if LOG_ENABLED:
                logger.error(f"yt-dlp fallback failed: {str(e)}")
            raise ValueError(f"yt-dlp fallback failed: {str(e)}")

    def split_transcript_into_chunks(self, transcript: str, chunk_size: int = 7000) -> List[str]:
        words = transcript.split()
        chunks = []
        current_chunk = []
        current_length = 0

        for word in words:
            if current_length + len(word) > chunk_size and current_chunk:
                chunks.append(" ".join(current_chunk))
                current_chunk = []
                current_length = 0
            current_chunk.append(word)
            current_length += len(word) + 1

        if current_chunk:
            chunks.append(" ".join(current_chunk))
        return chunks

    def create_summary_prompt(self, content: str, language: str, mode: str) -> str:
        prompts = {
            "detailed": f"Create a comprehensive summary in {language}. Include all main points and details.",
            "concise": f"Create a concise summary in {language}. Focus on key takeaways.",
            "bullet": f"Create a bullet-point summary in {language}. Use clear bullet points.",
            "academic": f"Create an academic-style summary in {language}. Include analysis and insights.",
        }
        prompt = prompts.get(mode, prompts["detailed"])
        return f"{prompt}\n\nContent:\n{content}"

    async def process_video(self, url: str, language: str = "English", mode: str = "detailed", ai_model: str = "gemini") -> AsyncGenerator[ProcessingProgress, None]:
        try:
            video_id = self.extract_video_id(url)
            
            if ai_model not in self.clients:
                available = list(self.clients.keys())
                raise ValueError(f"AI model '{ai_model}' not available. Available: {available}")

            yield ProcessingProgress(type="progress", stage="analyzing", message="Fetching transcript...")
            
            transcript_result = await self.get_transcript(video_id)
            chunks = self.split_transcript_into_chunks(transcript_result.transcript)
            
            intermediate_summaries = []
            for i, chunk in enumerate(chunks):
                yield ProcessingProgress(
                    type="progress",
                    current_chunk=i + 1,
                    total_chunks=len(chunks),
                    stage="processing",
                    message=f"Processing section {i + 1} of {len(chunks)}..."
                )
                
                prompt = f"Summarize this section in {language}:\n{chunk}"
                summary_chunk = await self.generate_with_ai(prompt, ai_model)
                intermediate_summaries.append(summary_chunk)

            yield ProcessingProgress(type="progress", stage="finalizing", message="Creating final summary...")
            
            combined_summary = "\n\n".join(intermediate_summaries)
            final_prompt = self.create_summary_prompt(combined_summary, language, mode)
            final_summary = await self.generate_with_ai(final_prompt, ai_model)

            yield ProcessingProgress(
                type="complete",
                summary=final_summary,
                source=transcript_result.source,
                status="completed"
            )

        except Exception as e:
            yield ProcessingProgress(type="error", error=str(e), message=f"Failed: {str(e)}")

# FastAPI App
app = FastAPI(title="YouTube Video Summarizer API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

processor = YouTubeVideoProcessor()

class SummaryRequest(BaseModel):
    url: str
    language: str = "English"
    mode: str = "detailed"
    model: str = "gemini"

class ModelInfo(BaseModel):
    name: str
    available: bool

@app.get("/")
async def root():
    return {
        "success": True,
        "message": "YouTube Video Summarizer API",
        "data": {"version": "1.0.0", "endpoints": ["/", "/models", "/summarize"]},
    }

@app.get("/models")
async def get_models():
    availability = processor.check_api_availability()
    models = [ModelInfo(name=name, available=available) for name, available in availability.items()]
    return {"models": models}

@app.post("/summarize")
async def summarize(request: SummaryRequest):
    try:
        availability = processor.check_api_availability()
        if not availability.get(request.model, False):
            available_models = [name for name, avail in availability.items() if avail]
            return {
                "success": False,
                "message": f"Model {request.model} not available",
                "error": f"Available models: {', '.join(available_models)}",
            }

        video_id = processor.extract_video_id(request.url)
        return {
            "success": True,
            "message": "Processing started",
            "data": {
                "video_id": video_id,
                "stream_url": f"/ws/{video_id}?language={request.language}&mode={request.mode}&model={request.model}",
            },
        }
    except Exception as e:
        return {"success": False, "message": "Failed to process request", "error": str(e)}

@app.get("/summarize")
async def summarize_get(url: str = None, language: str = "English", mode: str = "concise", model: str = "gemini"):
    if not url:
        return HTMLResponse("""
        <html><body>
        <h1>YouTube Summarizer</h1>
        <p>Usage: /summarize?url=VIDEO_URL_OR_ID</p>
        <p>Examples:</p>
        <ul>
            <li>/summarize?url=https://www.youtube.com/watch?v=jNQXAC9IVRw (TED Talk)</li>
            <li>/summarize?url=M7lc1UVf-VE (Educational)</li>
            <li>/summarize?url=9bZkp7q19f0 (Tech Talk)</li>
            <li>/summarize?url=dQw4w9WgXcQ (Classic)</li>
        </ul>
        <p><strong>Note:</strong> Some videos may be blocked. Try the suggested videos above.</p>
        </body></html>
        """)
    
    try:
        url = urllib.parse.unquote(url)
        video_id = processor.extract_video_id(url)
        
        return HTMLResponse(f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>YouTube Summarizer - {video_id}</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}
                .progress {{ background: #f0f0f0; padding: 10px; margin: 10px 0; border-radius: 5px; }}
                .summary {{ background: #e8f5e8; padding: 15px; margin: 10px 0; border-radius: 5px; white-space: pre-wrap; }}
                .error {{ background: #ffe8e8; padding: 15px; margin: 10px 0; border-radius: 5px; }}
            </style>
        </head>
        <body>
            <h1>YouTube Video Summarizer</h1>
            <p><strong>Video ID:</strong> {video_id}</p>
            <p><strong>Language:</strong> {language} | <strong>Mode:</strong> {mode} | <strong>Model:</strong> {model}</p>
            <div id="status">Connecting...</div>
            <div id="progress"></div>
            <div id="summary"></div>
            
            <script>
                const ws = new WebSocket(`ws://${{window.location.host}}/ws/{video_id}?language={language}&mode={mode}&model={model}`);
                
                ws.onopen = function() {{
                    document.getElementById('status').innerHTML = '<div class="progress">Connected! Processing video...</div>';
                }};
                
                ws.onmessage = function(event) {{
                    const data = JSON.parse(event.data);
                    
                    if (data.type === 'progress') {{
                        document.getElementById('progress').innerHTML = 
                            `<div class="progress">${{data.stage}}: ${{data.message}} (${{data.current_chunk}}/${{data.total_chunks}})</div>`;
                    }} else if (data.type === 'complete') {{
                        document.getElementById('progress').innerHTML = '<div class="progress">✅ Complete!</div>';
                        document.getElementById('summary').innerHTML = 
                            `<div class="summary"><h3>Summary:</h3>${{data.summary}}</div>`;
                    }} else if (data.type === 'error') {{
                        document.getElementById('progress').innerHTML = 
                            `<div class="error">❌ Error: ${{data.error}}</div>`;
                    }}
                }};
                
                ws.onerror = function(error) {{
                    document.getElementById('status').innerHTML = '<div class="error">Connection error</div>';
                }};
            </script>
        </body>
        </html>
        """)
        
    except Exception as e:
        return HTMLResponse(f"<html><body><h1>Error</h1><p>{str(e)}</p></body></html>")

@app.websocket("/ws/{video_id}")
async def websocket_endpoint(websocket: WebSocket, video_id: str, language: str = "English", mode: str = "detailed", model: str = "gemini"):
    await websocket.accept()
    
    try:
        video_url = f"https://www.youtube.com/watch?v={video_id}"
        async for progress in processor.process_video(
            url=video_url, language=language, mode=mode, ai_model=model
        ):
            await websocket.send_text(json.dumps(progress.__dict__))
    except Exception as e:
        error_data = {
            "type": "error",
            "error": str(e),
            "message": f"Failed to process video: {str(e)}",
        }
        await websocket.send_text(json.dumps(error_data))
    finally:
        await websocket.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)