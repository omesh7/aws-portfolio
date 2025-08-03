# AWS Portfolio Architecture Diagrams

## Project 01 - Static Portfolio Website on S3 with CI/CD

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   GitHub    │───▶│ GitHub       │───▶│    AWS S3   │
│ Repository  │    │ Actions      │    │   Bucket    │
│   (site/)   │    │   CI/CD      │    │ (Website)   │
└─────────────┘    └──────────────┘    └─────────────┘
                                              │
┌─────────────┐    ┌──────────────┐          │
│   Route 53  │◄───│ CloudFront   │◄─────────┘
│   (DNS)     │    │    (CDN)     │
└─────────────┘    └──────────────┘
       │                  │
       │           ┌──────────────┐
       └──────────▶│     ACM      │
                   │ (SSL Cert)   │
                   └──────────────┘
```

**Flow:**
1. Code push to GitHub triggers Actions
2. Vite builds static files
3. Files deployed to S3 bucket
4. CloudFront serves content globally
5. Route 53 handles DNS routing
6. ACM provides SSL certificate

---

## Project 02 - Mass Emailing System using AWS Lambda and SES

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   GitHub    │───▶│ GitHub       │───▶│ AWS Lambda  │
│ Repository  │    │ Actions      │    │ Function    │
└─────────────┘    └──────────────┘    └─────────────┘
                                              │
                                              ▼
┌─────────────┐                    ┌─────────────────┐
│    AWS S3   │◄───────────────────│   Lambda        │
│email-list.csv│                   │   Runtime       │
└─────────────┘                    └─────────────────┘
                                              │
                                              ▼
                                   ┌─────────────────┐
                                   │   Amazon SES    │
                                   │ (Email Service) │
                                   └─────────────────┘
                                              │
                                              ▼
                                   ┌─────────────────┐
                                   │   Recipients    │
                                   │    (Email)      │
                                   └─────────────────┘
```

**Flow:**
1. GitHub Actions deploys Lambda function
2. Lambda reads CSV from S3
3. Parses email list and sends via SES
4. SES delivers emails to recipients

---

## Project 03 - Alexa Skill for Portfolio Projects

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│    User     │───▶│    Alexa     │───▶│   Alexa     │
│   Voice     │    │   Device     │    │ Developer   │
│  Command    │    │              │    │  Console    │
└─────────────┘    └──────────────┘    └─────────────┘
                                              │
                                              ▼
                                   ┌─────────────────┐
                                   │  AWS Lambda     │
                                   │ (Skill Logic)   │
                                   └─────────────────┘
                                              │
                                              ▼
┌─────────────┐                    ┌─────────────────┐
│    AWS S3   │◄───────────────────│   Response      │
│(Documentation)│                  │  Generation     │
└─────────────┘                    └─────────────────┘
```

**Flow:**
1. User speaks to Alexa device
2. Alexa processes intent via Developer Console
3. Lambda function handles business logic
4. Optional S3 lookup for project details
5. Response sent back to user

---

## Project 04 - Text-to-Speech Generator with Amazon Polly

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Client    │───▶│ API Gateway  │───▶│ AWS Lambda  │
│ (Frontend)  │    │   (POST)     │    │ Function    │
└─────────────┘    └──────────────┘    └─────────────┘
                                              │
                                              ▼
                                   ┌─────────────────┐
                                   │ Amazon Polly    │
                                   │(Text-to-Speech) │
                                   └─────────────────┘
                                              │
                                              ▼
┌─────────────┐                    ┌─────────────────┐
│    AWS S3   │◄───────────────────│   Audio Stream  │
│ (.mp3 files)│                    │   Processing    │
└─────────────┘                    └─────────────────┘
       │
       ▼
┌─────────────┐
│   Public    │
│ S3 URL      │
│ (Response)  │
└─────────────┘
```

**Flow:**
1. Client sends text via API Gateway
2. Lambda receives text input
3. Polly converts text to audio
4. Audio uploaded to S3
5. Public S3 URL returned to client

---

## Project 05 - Music Recommendation API with Custom ML

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Spotify   │───▶│    AWS S3    │───▶│  SageMaker  │
│  Dataset    │    │ (Training    │    │   /Local    │
│   (1GB)     │    │   Data)      │    │  Training   │
└─────────────┘    └──────────────┘    └─────────────┘
                                              │
                                              ▼
┌─────────────┐                    ┌─────────────────┐
│   Client    │◄───────────────────│  Trained Model  │
│  Request    │                    │   (Stored)      │
└─────────────┘                    └─────────────────┘
       │                                     │
       ▼                                     ▼
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│ API Gateway │───▶│ AWS Lambda   │───▶│   Model     │
│             │    │ (Prediction) │    │ Inference   │
└─────────────┘    └──────────────┘    └─────────────┘
```

**Flow:**
1. Spotify dataset stored in S3
2. Model trained using SageMaker/Local Python
3. Client requests recommendations via API Gateway
4. Lambda loads model and generates predictions
5. Recommendations returned to client

---

## Project 06 - Serverless Image Resizer

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐
│   Vite UI   │───▶│ API Gateway  │───▶│ AWS Lambda  │
│(shadcn/ui)  │    │  (/resize)   │    │ Function    │
└─────────────┘    └──────────────┘    └─────────────┘
       │                                     │
       │ (Image URL/Upload)                  ▼
       │                          ┌─────────────────┐
       │                          │     Sharp       │
       │                          │ (Image Resize)  │
       │                          └─────────────────┘
       │                                     │
       │                                     ▼
       │                          ┌─────────────────┐
       │                          │    AWS S3       │
       │                          │ (Resized Image) │
       │                          └─────────────────┘
       │                                     │
       │                                     ▼
       └─────────────────────────── ┌─────────────────┐
                                   │  Public S3 URL  │
                                   │   (Download)    │
                                   └─────────────────┘
```

**Flow:**
1. User uploads image or provides URL via Vite UI
2. API Gateway receives resize request
3. Lambda processes image with Sharp library
4. Resized image stored in S3 with public access
5. Download link returned to frontend

---

## Recommended Tools for Visual Diagrams

### 1. **draw.io (diagrams.net)** - FREE
- Web-based, no installation required
- AWS architecture icons included
- Export to PNG, SVG, PDF
- URL: https://app.diagrams.net/

### 2. **Lucidchart** - Freemium
- Professional diagrams
- AWS shape libraries
- Collaboration features
- URL: https://lucidchart.com/

### 3. **AWS Architecture Icons**
- Official AWS icon set
- Download: https://aws.amazon.com/architecture/icons/

### 4. **Cloudcraft** - AWS Specific
- 3D AWS architecture diagrams
- Cost estimation integration
- URL: https://cloudcraft.co/

### Quick Start with draw.io:
1. Go to https://app.diagrams.net/
2. Choose "Create New Diagram"
3. Select "AWS" template
4. Use the text diagrams above as reference
5. Drag and drop AWS services from the left panel