import { useState } from 'react'
import './App.css'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div className="app">
      <header className="header">
        <h1>🚀 Static Website Demo</h1>
        <p>Project 01 - AWS S3 + CloudFront + Custom Domain</p>
      </header>

      <main className="main">
        <section className="hero">
          <h2>Simple Static Site Deployment</h2>
          <p>This demonstrates a basic static website hosted on AWS S3 with CloudFront CDN and custom domain.</p>
          
          <div className="counter-section">
            <button onClick={() => setCount((count) => count + 1)}>
              Count is {count}
            </button>
            <p>Click the button to test React functionality</p>
          </div>
        </section>

        <section className="features">
          <h3>🛠️ Tech Stack</h3>
          <ul>
            <li>⚡ Vite + React</li>
            <li>☁️ AWS S3 Static Hosting</li>
            <li>🌐 CloudFront CDN</li>
            <li>🔒 SSL Certificate (ACM)</li>
            <li>🌍 Custom Domain (Cloudflare DNS)</li>
            <li>🚀 Infrastructure as Code (Terraform)</li>
          </ul>
        </section>

        <section className="architecture">
          <h3>📐 Architecture</h3>
          <p>User → CloudFront → S3 Bucket → Static Files</p>
          <div className="architecture-flow">
            <div className="step">🌐 Domain</div>
            <div className="arrow">→</div>
            <div className="step">☁️ CloudFront</div>
            <div className="arrow">→</div>
            <div className="step">🪣 S3</div>
          </div>
        </section>
      </main>

      <footer className="footer">
        <p>© 2025 AWS Portfolio Project 01 - Static Website Demo</p>
      </footer>
    </div>
  )
}

export default App