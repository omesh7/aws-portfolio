# AWS DevOps Portfolio

10 production-grade projects demonstrating end-to-end DevOps, cloud infrastructure, and platform engineering skills on AWS (with multi-cloud where relevant).

Every project is deployable, uses Infrastructure as Code, and follows real-world operational patterns.

---

## Projects

| # | Project | Key Skills | Tools |
|---|---|---|---|
| 01 | [**Static Site — S3 + CloudFront**](01-static-site-s3-cloudfront/) | IaC, CDN, CI/CD | Terraform, S3, CloudFront, GitHub Actions |
| 02 | [**CI/CD Pipeline — CodePipeline**](02-cicd-pipeline-codepipeline/) | CI/CD, Containers, ECS | CodePipeline, Docker, ECR, ECS Fargate, Terraform |
| 03 | [**Kinesis Streaming Pipeline**](03-kinesis-streaming-pipeline/) | Stream Processing, Containers | Kinesis, ECR, Lambda, Terraform |
| 04 | [**Kubernetes Microservices**](04-kubernetes-microservices/) | Container Orchestration | Docker, K8s Deployments & Services |
| 05 | [**Multi-Cloud Disaster Recovery**](05-multicloud-disaster-recovery/) | DR, Multi-Cloud, Failover | AWS + GCP, Terraform, Cloudflare |
| 06 | [**Cross-Cloud K8s GitOps**](06-cross-cloud-k8s-gitops/) | GitOps, Multi-Cloud K8s | Terraform, Kubespray, Argo CD |
| 07 | [**DevSecOps Pipeline**](07-devsecops-pipeline/) | Shift-Left Security, CI/CD | Trivy, Checkov, OWASP, OIDC, ECS Fargate |
| 08 | [**EKS Observability Stack**](08-eks-observability-stack/) | Monitoring, Alerting, HPA | EKS, Prometheus, Grafana, Helm, Terraform |
| 09 | [**Ansible EC2 Hardening**](09-ansible-ec2-hardening/) | Config Management, Security | Ansible, Vault, Molecule, Terraform |
| 10 | [**Vault Secrets on ECS**](10-vault-secrets-ecs/) | Secrets Management, Dynamic Creds | HashiCorp Vault, KMS, ECS Fargate, Terraform |

---

## Skills Demonstrated

```
Infrastructure as Code     Terraform (modules, remote state, multi-provider)
CI/CD                      GitHub Actions, AWS CodePipeline, Argo CD (GitOps)
Containers                 Docker, ECR, ECS Fargate, Kubernetes
Security                   DevSecOps (Trivy, Checkov, OWASP), Ansible hardening, Vault
Monitoring                 Prometheus, Grafana, Alertmanager, CloudWatch
Configuration Management   Ansible (roles, vault, molecule, dynamic inventory)
Multi-Cloud                AWS + GCP, Cloudflare DNS failover
Streaming                  Kinesis Data Streams, Lambda consumers
```

---

## Repository Structure

```
├── 01-static-site-s3-cloudfront/
├── 02-cicd-pipeline-codepipeline/
├── 03-kinesis-streaming-pipeline/
├── 04-kubernetes-microservices/
├── 05-multicloud-disaster-recovery/
├── 06-cross-cloud-k8s-gitops/
├── 07-devsecops-pipeline/
├── 08-eks-observability-stack/
├── 09-ansible-ec2-hardening/
├── 10-vault-secrets-ecs/
├── .github/workflows/           # CI/CD pipelines
├── Makefile                     # Repo-level commands
└── README.md
```

---

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform >= 1.0
- Docker
- kubectl (for K8s projects)
- Ansible >= 2.12 (for config management projects)
- Node.js 18+ (for frontend projects)

## Quick Start

```bash
git clone https://github.com/omesh7/aws-portfolio.git
cd aws-portfolio

# Pick a project
cd 07-devsecops-pipeline

# Each project has its own README with setup instructions
cat README.md
```

---

## License

MIT — see [LICENSE](LICENSE) for details.