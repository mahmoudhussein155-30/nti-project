# NTI DevOps Platform Project

A complete cloud-native voting application with full CI/CD pipeline, GitOps deployment, and security scanning.

## 🏗️ Architecture

- **Infrastructure**: AWS EKS, VPC, Bastion (Terraform)
- **Applications**: Voting App (Python), Result App (Node.js), Worker (.NET)
- **Platform**: ArgoCD, Vault, SonarQube, Nexus, NGINX Ingress
- **CI/CD**: GitHub Actions with Trivy SAST, automated deployments

## 📁 Project Structure

```
nti-project/
├── apps/                    # Application source code
│   ├── vote/               # Python voting frontend
│   ├── result/             # Node.js results frontend  
│   └── worker/             # .NET vote processor
├── infra/                  # Infrastructure as Code
│   ├── terraform/          # AWS infrastructure (VPC, EKS)
│   └── k8s-platform/       # Platform tools (ArgoCD, Vault, etc.)
├── helm/                   # Helm charts for applications
├── .github/workflows/      # CI/CD pipelines
└── docs/                   # Documentation
```

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured
- kubectl installed
- Terraform >= 1.0
- Helm >= 3.0

### Setup

1. **Deploy Infrastructure**
```bash
cd infra/terraform/envs/nonprod
terraform init
terraform apply
```

2. **Configure kubectl**
```bash
aws eks update-kubeconfig --name nti-eks-nonprod --region eu-west-1
```

3. **Deploy Platform Tools**
```bash
cd infra/k8s-platform
kubectl apply -k argocd/
```

4. **Deploy Applications via ArgoCD**
```bash
# Applications auto-deploy via GitOps
```

## 🔒 Security

- Trivy container scanning in CI
- SonarQube code quality analysis
- Vault for secrets management
- Network policies and RBAC

## 📊 Monitoring

- Prometheus metrics
- Grafana dashboards
- Application logs via CloudWatch

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. CI runs tests + security scans
4. PR review
5. Merge triggers deployment

## 📝 License

MIT
