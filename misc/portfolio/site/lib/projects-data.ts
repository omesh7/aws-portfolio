export interface Project {
  id: string;
  title: string;
  category: string;
  description: string;
  achievement: string;
  techStack: string[];
  deployable: boolean;
  liveUrl?: string;
  githubUrl?: string;
  architectureDiagram?: string;
}

export const projects: Project[] = [
  {
    id: "static-portfolio",
    title: "Static  Website",
    category: "Frontend & Static Hosting",
    description:
      "React 19 portfolio with Three.js animations, global CDN distribution, and automated CI/CD deployment pipeline.",
    achievement: "Global CDN with SSL automation and performance optimization",
    techStack: [
      "React 19",
      "Three.js",
      "Vite",
      "Terraform",
      "S3",
      "CloudFront",
      "GitHub Actions",
    ],
    deployable: true,
    liveUrl: "https://static.omesh.site",
    githubUrl: "https://github.com/omesh7/portfolio",
    architectureDiagram: "/architecture-diagrams/01.png",
  },
  {
    id: "mass-email-system",
    title: "Mass Email System",
    category: "Serverless Computing",
    description:
      "Serverless bulk email processing system with CSV parsing, delivery tracking, and comprehensive error handling.",
    achievement: "1000+ emails/batch processing with cost-effective scaling",
    techStack: [
      "TypeScript",
      "Lambda",
      "SES",
      "S3",
      "CloudWatch",
      "Node.js 18",
    ],
    deployable: false,
    githubUrl: "https://github.com/omesh7/mass-email-system",
    architectureDiagram: "/architecture-diagrams/02.png",
  },
  {
    id: "alexa-skill",
    title: "Custom Alexa Skill",
    category: "Voice Interface",
    description:
      "Voice-activated portfolio queries with custom intents and natural language processing capabilities.",
    achievement: "Natural language processing with voice UI design",
    techStack: ["Node.js", "Alexa Skills Kit", "Lambda", "Voice UI"],
    deployable: false,
    githubUrl: "https://github.com/omesh7/alexa-skill",
    architectureDiagram: "/architecture-diagrams/03.png",
  },
  {
    id: "text-to-speech",
    title: "Text-to-Speech Generator",
    category: "AI/ML Services",
    description:
      "Real-time audio generation with multiple voice options, MP3 conversion, and public URL distribution.",
    achievement: "AI-powered speech synthesis with scalable processing",
    techStack: ["Node.js", "Amazon Polly", "Lambda", "S3", "API Gateway"],
    deployable: true,
    githubUrl: "https://github.com/omesh7/text-to-speech",
    architectureDiagram: "/architecture-diagrams/04.png",
  },
  {
    id: "recommendation-engine",
    title: "Content Recommendation Engine",
    category: "Machine Learning",
    description:
      "Custom ML implementation using collaborative filtering on 1GB Spotify dataset for user-based recommendations.",
    achievement: "Custom ML implementation with large dataset processing",
    techStack: [
      "Python",
      "Pandas",
      "Scikit-learn",
      "Collaborative Filtering",
      "Amazon Personalize",
    ],
    deployable: false,
    githubUrl: "https://github.com/omesh7/recommendation-engine",
  },
  {
    id: "image-resizer",
    title: "Smart Image Resizer",
    category: "Image Processing",
    description:
      "High-performance image processing with multiple formats, custom dimensions, and modern responsive UI.",
    achievement: "High-performance image processing with modern frontend",
    techStack: [
      "Next.js 15",
      "React 19",
      "Sharp",
      "TypeScript",
      "Lambda",
      "S3",
    ],
    deployable: true,
    liveUrl: "https://resize.omesh.site",
    githubUrl: "https://github.com/omesh7/image-resizer",
  },
  {
    id: "receipt-processor",
    title: "Automated Receipt Processor",
    category: "Document AI",
    description:
      "OCR-powered receipt analysis with automated data extraction, parsing, and structured storage for expense tracking.",
    achievement: "Document AI with automated data processing",
    techStack: [
      "Python",
      "Textract",
      "Lambda",
      "DynamoDB",
      "S3",
      "API Gateway",
    ],
    deployable: true,
    githubUrl: "https://github.com/omesh7/receipt-processor",
  },
  {
    id: "rag-portfolio-chat",
    title: "AI RAG Portfolio Chat",
    category: "Conversational AI",
    description:
      "Advanced AI chatbot with vector database integration for intelligent portfolio Q&A and context-aware responses.",
    achievement:
      "Advanced AI integration with vector search and RAG architecture",
    techStack: [
      "Python",
      "LangChain",
      "OpenAI",
      "Vector Embeddings",
      "Lambda",
      "DynamoDB",
    ],
    deployable: false,
    githubUrl: "https://github.com/omesh7/rag-portfolio-chat",
  },
  {
    id: "lex-chatbot",
    title: "Amazon Lex Chatbot",
    category: "Conversational Interface",
    description:
      "Enterprise chatbot solution with intent recognition, slot filling, and multi-channel deployment support.",
    achievement: "Enterprise chatbot solution with NLP capabilities",
    techStack: ["Amazon Lex", "Lambda", "DynamoDB", "CloudWatch", "NLP"],
    deployable: false,
    githubUrl: "https://github.com/omesh7/lex-chatbot",
  },
  {
    id: "kinesis-ml-pipeline",
    title: "Kinesis ECR ML Pipeline",
    category: "Real-Time Processing",
    description:
      "Real-time data ingestion and processing pipeline with containerized ML models and scalable streaming architecture.",
    achievement:
      "Real-time analytics with containerized ML and stream processing",
    techStack: ["Python", "Docker", "Kinesis", "ECR", "Lambda", "DynamoDB"],
    deployable: true,
    githubUrl: "https://github.com/omesh7/kinesis-ml-pipeline",
  },
  {
    id: "image-recognition-poem",
    title: "Image Recognition + Poem Engine",
    category: "Creative AI",
    description:
      "Computer vision combined with generative AI to analyze images and create contextual poetry based on detected scenes.",
    achievement: "Computer vision + generative AI for creative applications",
    techStack: [
      "Python",
      "Rekognition",
      "OpenAI",
      "Lambda",
      "S3",
      "API Gateway",
    ],
    deployable: true,
    liveUrl: "https://image-recog.omesh.site/",
    githubUrl: "https://github.com/omesh7/image-recognition-poem",
  },
  {
    id: "kubernetes-app",
    title: "Kubernetes Simple App",
    category: "Container Orchestration",
    description:
      "Microservices architecture with container orchestration, featuring YouTube summarizer and scalable web services.",
    achievement: "Container orchestration with microservices and scalability",
    techStack: ["Node.js", "Python", "Docker", "Kubernetes", "EKS", "Flask"],
    deployable: false,
    githubUrl: "https://github.com/omesh7/kubernetes-app",
  },
  {
    id: "2048-game-cicd",
    title: "2048 Game - CI/CD Pipeline",
    category: "DevOps Automation",
    description:
      "Full-stack game with enterprise CI/CD pipeline, automated testing, multi-stage deployment, and rollback capabilities.",
    achievement:
      "Enterprise CI/CD with automated testing and deployment automation",
    techStack: [
      "React",
      "Vite",
      "Python Flask",
      "Docker",
      "CodePipeline",
      "CodeBuild",
    ],
    deployable: true,
    liveUrl: "https://2048.omesh.site",
    githubUrl: "https://github.com/omesh7/2048-game-cicd",
  },
  {
    id: "multi-cloud-weather",
    title: "Multi-Cloud Weather Tracker",
    category: "Disaster Recovery",
    description:
      "Multi-cloud architecture with automated failover, health monitoring, and zero-downtime disaster recovery across AWS and GCP.",
    achievement: "Enterprise disaster recovery with multi-cloud architecture",
    techStack: [
      "JavaScript",
      "Node.js",
      "Terraform",
      "AWS",
      "GCP",
      "Cloudflare",
      "Route53",
    ],
    deployable: false,
    liveUrl: "https://weather.portfolio.omesh.site",
    githubUrl: "https://github.com/omesh7/multi-cloud-weather",
  },
];
