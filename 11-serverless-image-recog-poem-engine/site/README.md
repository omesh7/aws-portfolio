# 🎨 AI Poetry Generator - Frontend

A modern React application that transforms images into beautiful poetry using AWS AI services.

## ✨ Features

- **Drag & Drop Upload** - Intuitive image upload with preview
- **Real-time Progress** - Visual progress tracking through each step
- **AI Poetry Generation** - AWS Rekognition + Bedrock for creative content
- **Beautiful UI** - Modern design with animations and glass effects
- **Download & Share** - Export poems or share directly
- **Responsive Design** - Works perfectly on all devices

## 🚀 Quick Start

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

## 🔧 Configuration

1. Copy environment variables:
```bash
cp .env.example .env
```

2. Update `.env` with your Lambda function URL:
```env
VITE_API_URL=https://your-lambda-function-url.lambda-url.ap-south-1.on.aws/
```

## 🏗️ Architecture

```
User Upload → Lambda (Presigned URL) → S3 → Rekognition → Bedrock → Poetry
```

## 🎯 Tech Stack

- **React 18** - Modern React with hooks
- **Vite** - Fast build tool and dev server
- **Tailwind CSS** - Utility-first styling
- **Framer Motion** - Smooth animations
- **Lucide React** - Beautiful icons

## 📱 Components

- `ImageUploader` - Drag & drop file upload
- `ProgressTracker` - Step-by-step progress visualization
- `PoemDisplay` - Beautiful poem presentation with actions

## 🎨 Design Features

- Glass morphism effects
- Gradient backgrounds
- Smooth animations
- Progress indicators
- Responsive layout
- Modern typography

## 🔄 Workflow

1. **Upload** - User selects/drops an image
2. **Process** - Image uploaded to S3 via presigned URL
3. **Analyze** - AWS Rekognition detects image labels
4. **Generate** - AWS Bedrock creates poetry from labels
5. **Display** - Beautiful poem presentation with download/share

## 📦 Build & Deploy

```bash
# Production build
npm run build

# Preview production build
npm run preview

# Deploy to S3 (example)
aws s3 sync dist/ s3://your-bucket-name --delete
```

## 🎯 Performance

- Lazy loading for optimal performance
- Optimized images and assets
- Minimal bundle size
- Fast initial load times

## 🔒 Security

- Client-side file validation
- Secure presigned URL uploads
- No sensitive data in frontend
- CORS-enabled API endpoints

---

**Ready to create beautiful poetry from your images! 🚀**