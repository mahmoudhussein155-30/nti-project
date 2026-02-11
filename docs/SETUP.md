# Complete Setup Guide

## Prerequisites

- AWS Account with EKS cluster running
- `kubectl` configured to access your cluster
- GitHub account
- AWS CLI configured with credentials

## Step 1: GitHub Repository Setup

1. **Create GitHub repository:**
   ```bash
   # On GitHub, create repo: nti-project (private recommended)
   ```

2. **Configure GitHub Secrets:**
   Go to Settings → Secrets and variables → Actions, add:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

## Step 2: Copy Application Code

Since you already have the app code, copy it to the new structure:

```bash
# From your nti-redo directory
cd ~/projects/nti-redo

# Copy app source code
cp -r app/voting-app/cloud-native-devops-platform/voting-app/vote/* ~/nti-project/apps/vote/
cp -r app/voting-app/cloud-native-devops-platform/voting-app/result/* ~/nti-project/apps/result/
cp -r app/voting-app/cloud-native-devops-platform/voting-app/worker/* ~/nti-project/apps/worker/

# Copy Terraform infrastructure
cp -r infra/* ~/nti-project/infra/terraform/
```

## Step 3: Initialize Git Repository

```bash
cd ~/nti-project

# Initialize and push
git init
git add .
git commit -m "Initial commit: Complete DevOps platform setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/nti-project.git
git push -u origin main
```

## Step 4: Install Platform Tools

### 4.1 Install NGINX Ingress Controller

```bash
cd infra/k8s-platform
chmod +x install-nginx-ingress.sh
./install-nginx-ingress.sh
```

Get the LoadBalancer URL:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

### 4.2 Install ArgoCD

```bash
chmod +x install-argocd.sh
./install-argocd.sh
```

Access ArgoCD UI:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Open https://localhost:8080 and login with admin and the password shown during installation.

### 4.3 Create MongoDB Secret

```bash
# Get MongoDB password (if using Bitnami MongoDB chart)
MONGO_PASS=$(kubectl get secret result-mongo-mongodb -n result -o jsonpath='{.data.mongodb-root-password}' | base64 -d)

# Create voting-app namespace
kubectl create namespace voting-app

# Create MongoDB credentials secret
kubectl create secret generic mongodb-atlas-credentials \
  --from-literal=connection-string="mongodb://root:${MONGO_PASS}@voting-app-mongodb:27017/voting?authSource=admin" \
  -n voting-app
```

## Step 5: Deploy with ArgoCD

1. **Update ArgoCD Application manifest:**
   Edit `infra/k8s-platform/argocd-app.yaml` and replace `YOUR_USERNAME` with your GitHub username.

2. **Deploy the application:**
   ```bash
   kubectl apply -f infra/k8s-platform/argocd-app.yaml
   ```

3. **Monitor deployment in ArgoCD UI:**
   - Navigate to Applications
   - Click on `voting-app-nonprod`
   - Watch the sync progress

## Step 6: Configure DNS (Optional)

If using real domains, update your DNS to point to the NGINX LoadBalancer:

```bash
# Get LoadBalancer hostname
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Create CNAME records:
- `vote-nonprod.nti-project.com` → LoadBalancer hostname
- `result-nonprod.nti-project.com` → LoadBalancer hostname

## Step 7: Trigger CI/CD Pipeline

1. **Make a code change:**
   ```bash
   cd apps/vote
   # Edit app.py or any file
   git add .
   git commit -m "Update vote app"
   git push
   ```

2. **Watch GitHub Actions:**
   - Go to Actions tab in GitHub
   - Watch the CI pipeline run
   - Trivy will scan for vulnerabilities
   - Image will be pushed to ECR

3. **ArgoCD auto-sync:**
   - ArgoCD detects the change
   - Automatically updates the deployment
   - New pods roll out with new image

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        GitHub Repo                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────┐ │
│  │ App Code │  │   Helm   │  │   Infra  │  │  Workflows  │ │
│  └──────────┘  └──────────┘  └──────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
         │                              │
         │ Push Code                    │ GitOps Sync
         ▼                              ▼
┌──────────────────┐           ┌─────────────────┐
│  GitHub Actions  │           │     ArgoCD      │
│  - Build Image   │           │  - Watch Repo   │
│  - Trivy Scan    │◄──────────┤  - Auto Deploy  │
│  - Push to ECR   │  Update   │  - Self Heal    │
└──────────────────┘  Values   └─────────────────┘
                                        │
                                        │ Deploy
                                        ▼
                           ┌─────────────────────────┐
                           │      EKS Cluster        │
                           │  ┌──────────────────┐   │
                           │  │ NGINX Ingress    │   │
                           │  └──────────────────┘   │
                           │  ┌─────┐  ┌─────────┐  │
                           │  │Vote │  │ Result  │  │
                           │  └─────┘  └─────────┘  │
                           │  ┌────────┐ ┌────────┐ │
                           │  │Worker  │ │ Redis  │ │
                           │  └────────┘ └────────┘ │
                           │            ┌─────────┐ │
                           │            │ MongoDB │ │
                           │            └─────────┘ │
                           └─────────────────────────┘
```

## Verification

### Check Deployments
```bash
kubectl get pods -n voting-app
kubectl get svc -n voting-app
kubectl get ingress -n voting-app
```

### Check ArgoCD Status
```bash
kubectl get applications -n argocd
```

### View Logs
```bash
kubectl logs -n voting-app -l app.kubernetes.io/component=vote --tail=50
kubectl logs -n voting-app -l app.kubernetes.io/component=result --tail=50
kubectl logs -n voting-app -l app.kubernetes.io/component=worker --tail=50
```

## Troubleshooting

### CI Pipeline Fails
- Check GitHub Actions logs
- Verify AWS credentials in secrets
- Ensure ECR repositories exist

### ArgoCD Not Syncing
- Check ArgoCD logs: `kubectl logs -n argocd deployment/argocd-application-controller`
- Verify repository URL is correct
- Check if namespace exists

### Pods CrashLooping
- Check logs: `kubectl logs -n voting-app POD_NAME`
- Verify MongoDB secret exists
- Check resource limits

### Ingress Not Working
- Verify NGINX controller is running
- Check ingress resource: `kubectl describe ingress -n voting-app`
- Ensure DNS is configured correctly

## Next Steps

1. **Add Vault for Secrets Management**
2. **Install SonarQube for Code Quality**
3. **Deploy Nexus for Artifact Management**
4. **Set up Prometheus & Grafana for Monitoring**
5. **Configure SSL/TLS with cert-manager**

## Security Best Practices

✅ Trivy scans all images for vulnerabilities
✅ Secrets stored in Kubernetes secrets (move to Vault later)
✅ RBAC enabled on EKS
✅ Network policies (to be implemented)
✅ Image pull from private ECR
✅ Least privilege IAM roles

## Monitoring & Observability

- **Logs**: CloudWatch Container Insights
- **Metrics**: Prometheus (to be installed)
- **Dashboards**: Grafana (to be installed)
- **Tracing**: (to be implemented with Jaeger)
