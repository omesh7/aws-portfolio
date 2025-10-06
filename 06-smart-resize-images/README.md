# Smart Image Resizer - Serverless Processing Pipeline

**Professional Image Processing with Modern Full-Stack Architecture**

A production-ready image resizing service combining Next.js frontend with AWS Lambda backend, featuring real-time image processing, multiple format support, and intelligent fallback mechanisms for seamless user experience.

## 🎯 Quick Overview

**Key Technical Highlights:**
- **Frontend:** Next.js 15 + React 19 + TypeScript + Tailwind CSS 4
- **Backend:** Node.js 20 Lambda with Sharp image processing
- **Cloud Services:** AWS Lambda, S3, API Gateway v2, IAM
- **Image Processing:** Sharp library with AWS Lambda Layer optimization
- **Infrastructure:** Terraform with environment-based deployment
- **UI/UX:** shadcn/ui components with responsive design and accessibility

**Live Demo:** Professional image resizing tool | **Source Code:** [GitHub Repository](https://github.com/omesh7/aws-portfolio)

---

## 🏗️ Architecture Overview

**Data Flow:**
1. User uploads image through Next.js interface with drag-and-drop support
2. Frontend validates file size and format before processing
3. API routes handle both Lambda processing and local Sharp fallback
4. Lambda function processes image with Sharp library via optimized layer
5. Resized image stored in S3 with public access and unique naming
6. Public URL returned to frontend with download and sharing options
7. User receives processed image with multiple interaction options

**Hybrid Processing Strategy:**
- **Primary:** AWS Lambda with Sharp layer for production scalability
- **Fallback:** Local Next.js Sharp processing for development/reliability
- **Smart Routing:** Automatic failover ensures 100% uptime

---

## 💼 Technical Implementation

### Frontend Stack
- **Next.js 15** - App Router with Turbopack for fast development
- **React 19** - Concurrent features with modern hooks
- **TypeScript 5** - Strict type safety with comprehensive interfaces
- **Tailwind CSS 4** - Utility-first styling with custom configurations
- **shadcn/ui** - Accessible component library with Radix UI primitives
- **Lucide React** - Consistent icon system

### Backend Stack
- **Node.js 20** - Latest LTS runtime with ES modules
- **Sharp 0.34** - High-performance image processing with WebP optimization
- **Busboy 1.6** - Efficient multipart form data parsing
- **AWS SDK v3** - Modern modular clients for S3 operations
- **UUID v4** - Collision-resistant unique file naming

### Infrastructure Stack
- **Terraform** - Infrastructure as Code with state management
- **AWS Lambda** - Serverless compute with 30-second timeout
- **API Gateway v2** - HTTP API with comprehensive CORS configuration
- **S3 Storage** - Scalable object storage with public access policies
- **IAM Roles** - Least-privilege security with managed policies
- **Lambda Layers** - Optimized Sharp binaries for faster cold starts

---

## 📁 Project Structure

```
06-smart-resize-images/
├── infrastructure/             # Terraform Infrastructure
│   ├── main.tf                # Core AWS resources and networking
│   ├── variables.tf           # Configurable parameters
│   ├── providers.tf           # AWS and Vercel provider configs
│   ├── vercel.tf             # Vercel deployment automation
│   └── .terraform.lock.hcl   # Provider version constraints
├── lambda/                    # Lambda Function Code
│   ├── index.js              # Main handler with Sharp processing
│   ├── package.json          # Dependencies and ES module config
│   └── .env.example          # Environment variable template
├── site/                     # Next.js Application
│   ├── app/                  # App Router structure
│   │   ├── api/              # API routes
│   │   │   ├── resize/       # Primary image processing endpoint
│   │   │   ├── download/     # CORS proxy for file downloads
│   │   │   └── test-lambda/  # Lambda health check endpoint
│   │   ├── globals.css       # Global styles and CSS variables
│   │   ├── layout.tsx        # Root layout with metadata
│   │   └── page.tsx          # Main application page
│   ├── components/           # React Components
│   │   ├── ui/               # shadcn/ui component library
│   │   └── image-resizer.tsx # Main resizer component
│   ├── lib/                  # Utility functions
│   │   └── utils.ts          # Tailwind class merging utilities
│   ├── public/               # Static assets and icons
│   ├── package.json          # Frontend dependencies
│   ├── next.config.ts        # Next.js configuration
│   ├── tailwind.config.js    # Tailwind CSS configuration
│   └── tsconfig.json         # TypeScript configuration
└── README.md                 # This documentation
```

---

## 🚀 Core Functionality

### Lambda Image Processing Engine
```javascript
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import sharp from "sharp";
import busboy from "busboy";
import { v4 as uuidv4 } from "uuid";

const s3 = new S3Client({ region: process.env.REGION || "ap-south-1" });
const BUCKET_NAME = process.env.BUCKET_NAME;

export const handler = async (event) => {
    const method = event?.requestContext?.http?.method || "GET";
    const pathName = event?.rawPath || "/";

    if (method === "POST" && pathName === "/resize") {
        const width = parseInt(event.queryStringParameters?.width);
        const height = parseInt(event.queryStringParameters?.height);
        const formatParam = event.queryStringParameters?.format || "webp";

        // Parse multipart form data with busboy
        const { buffer, filename } = await parseMultipart(
            event.body,
            event.headers["content-type"],
            event.isBase64Encoded
        );

        // Process image with Sharp - high performance resizing
        const outputBuffer = await sharp(buffer)
            .resize(width, height)
            .toFormat(formatParam)
            .toBuffer();

        // Upload to S3 with unique naming
        const key = `resized/${uuidv4()}-${sanitizeFilename(filename, formatParam)}`;
        await s3.send(new PutObjectCommand({
            Bucket: BUCKET_NAME,
            Key: key,
            Body: outputBuffer,
            ContentType: contentTypeMap[formatParam],
        }));

        const url = `https://${BUCKET_NAME}.s3.${process.env.REGION}.amazonaws.com/${key}`;
        return jsonResponse({ url });
    }
};
```

### Next.js Hybrid Processing API
```typescript
export async function POST(request: NextRequest) {
    const formData = await request.formData();
    const imageFile = formData.get("imageFile") as File;
    
    // Primary: Lambda processing with timeout handling
    if (process.env.IMAGE_RESIZE_API_URL) {
        try {
            const apiUrl = new URL(`${process.env.IMAGE_RESIZE_API_URL}/resize`);
            apiUrl.searchParams.set("width", width.toString());
            apiUrl.searchParams.set("height", height.toString());
            apiUrl.searchParams.set("format", format);

            const response = await fetch(apiUrl.toString(), {
                method: "POST",
                body: requestFormData,
                signal: AbortSignal.timeout(30000),
            });

            if (response.ok) {
                const data = await response.json();
                return NextResponse.json({
                    resizedImageUrl: data.url,
                    format: format,
                });
            }
        } catch (lambdaError) {
            console.error("Lambda processing failed, falling back to local");
        }
    }

    // Fallback: Local Sharp processing
    const buffer = Buffer.from(await imageFile.arrayBuffer());
    const processedBuffer = await sharp(buffer)
        .resize(width, height)
        .toFormat(format as keyof sharp.FormatEnum)
        .toBuffer();

    const base64 = processedBuffer.toString('base64');
    const dataUrl = `data:image/${format};base64,${base64}`;
    
    return NextResponse.json({ resizedImageUrl: dataUrl, format });
}
```

### Terraform Infrastructure Automation
```hcl
resource "aws_lambda_function" "resize_upload" {
    function_name = "${var.project_name}-resize-upload-function"
    runtime       = "nodejs20.x"
    handler       = "index.handler"
    timeout       = 30
    
    layers = [
        "arn:aws:lambda:ap-south-1:533674634124:layer:sharp:1"
    ]
    
    environment {
        variables = {
            BUCKET_NAME = aws_s3_bucket.resized_bucket.bucket
            REGION      = var.aws_region
        }
    }
}

resource "aws_apigatewayv2_api" "api" {
    name          = "resize-upload-api-aws-portfolio"
    protocol_type = "HTTP"
    
    cors_configuration {
        allow_methods = ["GET", "POST", "OPTIONS"]
        allow_origins = ["*"]
        allow_headers = ["Content-Type"]
    }
}
```

---

## 🎨 Advanced Features

### Image Processing Capabilities
- **Multiple Formats** - WebP (recommended), JPEG, PNG with quality optimization
- **Custom Dimensions** - Preset sizes (200x200 to 1200x1200) and custom pixel values
- **Smart Validation** - File size limits (10MB), dimension constraints (minimum 10px)
- **Format Optimization** - Automatic WebP conversion for better compression

### User Experience Enhancements
- **Drag & Drop Upload** - Intuitive file selection with visual feedback
- **Real-time Preview** - Immediate display of processed images
- **Multiple Download Options** - Direct download, URL copying, new tab opening
- **Progress Indicators** - Loading states with descriptive messages
- **Error Handling** - Comprehensive error messages with fallback suggestions

### Performance Optimizations
- **Lambda Layers** - Pre-compiled Sharp binaries for faster cold starts
- **Hybrid Processing** - Automatic failover between Lambda and local processing
- **Efficient Parsing** - Busboy for memory-efficient multipart data handling
- **S3 Integration** - Direct upload with public access for CDN-like performance

### Security & Reliability
- **Input Validation** - File type, size, and dimension validation
- **Unique Naming** - UUID-based file naming prevents collisions
- **CORS Configuration** - Proper cross-origin resource sharing setup
- **IAM Policies** - Least-privilege access with managed AWS policies

---

## 🛠️ Setup & Deployment

### Prerequisites
- **AWS CLI** configured with appropriate permissions
- **Terraform** >= 1.0 for infrastructure management
- **Node.js** 20+ for local development
- **Sharp** compatible system (automatic with Lambda layers)

### Local Development
```bash
# Clone and navigate to project
git clone https://github.com/omesh7/aws-portfolio.git
cd aws-portfolio/06-smart-resize-images

# Setup Lambda function
cd lambda
npm install
cp .env.example .env
# Configure environment variables

# Setup Next.js frontend
cd ../site
npm install
cp .env.example .env.local
# Configure API endpoints

# Start development server
npm run dev
```

### Infrastructure Deployment
```bash
# Navigate to infrastructure directory
cd infrastructure

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Deploy infrastructure
terraform apply

# Get API endpoint
terraform output api_endpoint
```

### Production Deployment
```bash
# Build and deploy frontend to Vercel
cd site
npm run deploy

# Package and deploy Lambda function
cd ../lambda
zip -r ../infrastructure/06_lambda.zip .
cd ../infrastructure
terraform apply -var="environment=ci"
```

---

## 📊 Technical Specifications

### Performance Metrics
- **Cold Start Time** - ~2-3 seconds with Lambda layers
- **Processing Time** - 500ms-2s depending on image size and format
- **Concurrent Users** - 1000+ with Lambda auto-scaling
- **File Size Limit** - 10MB per image (configurable)

### Supported Formats
- **Input** - JPEG, PNG, WebP, TIFF, GIF
- **Output** - WebP (recommended), JPEG, PNG
- **Dimensions** - 10px minimum to 4096px maximum

### AWS Resource Usage
- **Lambda** - 512MB memory, 30-second timeout
- **S3** - Standard storage class with public read access
- **API Gateway** - HTTP API with request/response logging
- **IAM** - Managed policies for secure service integration

---

## 🔧 Configuration Options

### Environment Variables
```bash
# Lambda Configuration
BUCKET_NAME=your-s3-bucket-name
REGION=ap-south-1

# Next.js Configuration
IMAGE_RESIZE_API_URL=https://your-api-gateway-url
NEXT_PUBLIC_APP_URL=https://your-vercel-app-url
```

### Terraform Variables
```hcl
# infrastructure/terraform.tfvars
project_name = "06-resized-images-bucket-aws-portfolio"
aws_region = "ap-south-1"
environment = "production"
vercel_project_name = "image-resizer-aws-portfolio"
```

---

## 🚀 Live Demo

**Frontend Application:** [https://image-resizer-aws-portfolio.vercel.app](https://image-resizer-aws-portfolio.vercel.app)

**API Endpoint:** Available after Terraform deployment

**Features to Test:**
- Upload various image formats (JPEG, PNG, WebP)
- Try different resize dimensions and custom sizes
- Test format conversion (PNG to WebP for optimization)
- Experience the hybrid processing fallback mechanism

---

## 📈 Future Enhancements

- **Batch Processing** - Multiple image upload and processing
- **Advanced Filters** - Blur, sharpen, brightness, contrast adjustments
- **CDN Integration** - CloudFront distribution for global performance
- **User Authentication** - AWS Cognito for personalized image galleries
- **Analytics Dashboard** - Usage metrics and performance monitoring

---

## 🤝 Contributing

This project demonstrates production-ready AWS serverless architecture patterns. Feel free to explore the code, suggest improvements, or use it as a reference for your own serverless image processing solutions.

**Key Learning Areas:**
- Serverless architecture with AWS Lambda
- Hybrid processing strategies for reliability
- Modern React development with Next.js 15
- Infrastructure as Code with Terraform
- Image processing optimization techniques