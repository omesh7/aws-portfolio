# 🚀 Portfolio Site - Next.js with Email Integration

Modern portfolio website built with Next.js 15, featuring email contact functionality and deployed on Vercel with custom domain.

## 📁 Project Structure

```
portfolio/
├── infrastructure/          # Terraform IaC
│   ├── main.tf             # Vercel & Cloudflare resources
│   ├── providers.tf        # Provider configurations
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   └── terraform.tfvars.example
├── site/                   # Next.js application
│   ├── app/               # Next.js 15 app directory
│   ├── components/        # React components
│   ├── hooks/            # Custom hooks
│   ├── lib/              # Utilities
│   ├── public/           # Static assets
│   ├── .env              # Environment variables
│   └── package.json      # Dependencies
└── README.md
```

## ✨ Features

- **Modern Stack**: Next.js 15, React 19, TypeScript
- **Email Integration**: EmailJS for contact form
- **UI Components**: shadcn/ui with Tailwind CSS
- **Animations**: GSAP with ScrollTrigger
- **Custom Domain**: portfolio.omesh.site
- **Infrastructure as Code**: Terraform deployment
- **Responsive Design**: Mobile-first approach

## 🛠️ Tech Stack

### Frontend
- **Framework**: Next.js 15 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **UI Library**: shadcn/ui components
- **Animations**: GSAP
- **Email**: EmailJS

### Infrastructure
- **Deployment**: Vercel
- **Domain**: Cloudflare DNS
- **IaC**: Terraform
- **SSL**: Automatic HTTPS

## 🚀 Quick Start

### Prerequisites
```bash
Node.js 18+
Terraform >= 1.0
Vercel CLI (optional)
```

### 1. Clone & Setup
```bash
cd misc/portfolio/site
npm install
```

### 2. Environment Configuration
```bash
cp .env.example .env
# Edit .env with your EmailJS credentials
```

### 3. Local Development
```bash
npm run dev
# Visit http://localhost:3000
```

### 4. Infrastructure Deployment
```bash
cd ../infrastructure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your credentials

terraform init
terraform plan
terraform apply
```

## 📧 Email Configuration

The contact form uses EmailJS for sending emails. Configure these environment variables:

```env
NEXT_PUBLIC_EMAILJS_SERVICE_ID=your_service_id
NEXT_PUBLIC_EMAILJS_TEMPLATE_ID=your_template_id
NEXT_PUBLIC_EMAILJS_PUBLIC_KEY=your_public_key
```

## 🌐 Deployment

### Automatic Deployment
- **Trigger**: Push to `main` branch
- **Platform**: Vercel
- **Domain**: portfolio.omesh.site
- **SSL**: Automatic via Vercel

### Manual Deployment
```bash
# Via Vercel CLI
vercel --prod

# Via Terraform
terraform apply
```

## 🔧 Infrastructure Details

### Vercel Configuration
- **Framework**: Next.js
- **Root Directory**: `misc/portfolio/site`
- **Build Command**: `npm run build`
- **Output Directory**: `.next`

### Domain Setup
- **Primary**: portfolio.omesh.site
- **DNS**: Cloudflare (proxied)
- **SSL**: Vercel automatic certificate

### Environment Variables
Automatically configured via Terraform:
- EmailJS credentials
- Build-time variables
- Runtime environment settings

## 📊 Performance

- **Build Time**: ~2 minutes
- **Deploy Time**: ~30 seconds
- **Page Load**: <2 seconds
- **Lighthouse Score**: 95+

## 🔒 Security

- **HTTPS**: Enforced via Vercel
- **Environment Variables**: Encrypted at rest
- **API Keys**: Client-side only (EmailJS)
- **CORS**: Configured for email service

## 🎯 Live Demo

**URL**: [portfolio.omesh.site](https://portfolio.omesh.site)

### Features Showcase
- ✅ Responsive design
- ✅ Contact form with email
- ✅ Smooth animations
- ✅ Dark/light theme
- ✅ Project showcase
- ✅ Tech stack display

## 📝 Development

### Available Scripts
```bash
npm run dev          # Development server
npm run build        # Production build
npm run start        # Production server
npm run lint         # ESLint check
```

### Project Structure
```
site/
├── app/
│   ├── globals.css     # Global styles
│   ├── layout.tsx      # Root layout
│   └── page.tsx        # Home page
├── components/
│   ├── ui/            # shadcn/ui components
│   ├── ContactForm.tsx # Email contact form
│   └── ...            # Other components
└── lib/
    └── utils.ts       # Utility functions
```

## 🔄 CI/CD Pipeline

1. **Code Push** → GitHub
2. **Auto Deploy** → Vercel
3. **Domain Update** → Cloudflare
4. **SSL Renewal** → Automatic

## 💰 Cost Optimization

- **Vercel**: Free tier (Hobby plan)
- **Cloudflare**: Free tier
- **EmailJS**: Free tier (200 emails/month)
- **Total Cost**: $0/month

## 🎉 Key Achievements

- ✅ **Modern Architecture**: Next.js 15 with latest features
- ✅ **Email Integration**: Functional contact form
- ✅ **Custom Domain**: Professional branding
- ✅ **Infrastructure as Code**: Reproducible deployments
- ✅ **Performance Optimized**: Fast loading times
- ✅ **Mobile Responsive**: Works on all devices

Ready for production use! 🚀