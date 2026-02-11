# NTI Project Setup Checklist

Use this checklist to track your progress setting up the complete DevOps platform.

## ☐ Pre-Setup (5 minutes)

- [ ] Download the `nti-project` folder to your local machine
- [ ] Extract to `~/projects/nti-project` (or your preferred location)
- [ ] Verify you have `kubectl` access to your EKS cluster
- [ ] Verify AWS CLI is configured (`aws sts get-caller-identity`)
- [ ] Have your GitHub account ready

## ☐ Step 1: Copy Application Code (5 minutes)

```bash
cd ~/projects

# Copy your existing application code
cp -r nti-redo/app/voting-app/cloud-native-devops-platform/voting-app/vote/* nti-project/apps/vote/
cp -r nti-redo/app/voting-app/cloud-native-devops-platform/voting-app/result/* nti-project/apps/result/
cp -r nti-redo/app/voting-app/cloud-native-devops-platform/voting-app/worker/* nti-project/apps/worker/

# Verify files copied
ls nti-project/apps/vote/
ls nti-project/apps/result/
ls nti-project/apps/worker/
```

**Checklist:**
- [ ] Vote app code copied (Dockerfile, app.py, requirements.txt, etc.)
- [ ] Result app code copied (Dockerfile, server.js, package.json, etc.)
- [ ] Worker app code copied (Dockerfile, Program.cs, Worker.csproj, etc.)

## ☐ Step 2: Create GitHub Repository (3 minutes)

1. [ ] Go to https://github.com/new
2. [ ] Repository name: `nti-project`
3. [ ] Description: "Complete DevOps platform with CI/CD, GitOps, and security scanning"
4. [ ] Choose visibility (Private recommended)
5. [ ] **Do NOT** initialize with README, .gitignore, or license
6. [ ] Click "Create repository"
7. [ ] Copy the repository URL (e.g., `https://github.com/USERNAME/nti-project.git`)

## ☐ Step 3: Configure GitHub Secrets (2 minutes)

1. [ ] Go to your repository Settings
2. [ ] Click "Secrets and variables" → "Actions"
3. [ ] Click "New repository secret"
4. [ ] Add secret: `AWS_ACCESS_KEY_ID`
   - Value: Your AWS access key ID
5. [ ] Add secret: `AWS_SECRET_ACCESS_KEY`
   - Value: Your AWS secret access key

**Verify:**
- [ ] Two secrets created and visible in Actions secrets page

## ☐ Step 4: Initialize Git and Push (3 minutes)

```bash
cd ~/projects/nti-project

# Initialize Git repository
git init
git add .
git commit -m "Initial commit: Complete DevOps platform with CI/CD pipelines"

# Connect to GitHub (replace USERNAME with your GitHub username)
git remote add origin https://github.com/USERNAME/nti-project.git
git branch -M main
git push -u origin main
```

**Verify:**
- [ ] Repository pushed successfully
- [ ] All files visible on GitHub
- [ ] GitHub Actions workflows visible in Actions tab

## ☐ Step 5: Install NGINX Ingress Controller (5 minutes)

```bash
cd ~/projects/nti-project/infra/k8s-platform

# Make scripts executable (if not already)
chmod +x *.sh

# Install NGINX Ingress
./install-nginx-ingress.sh
```

**Verify:**
- [ ] Script completed successfully
- [ ] NGINX pods running: `kubectl get pods -n ingress-nginx`
- [ ] LoadBalancer created: `kubectl get svc -n ingress-nginx`

**Note the LoadBalancer URL - you'll need it for DNS:**
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```
LoadBalancer URL: ___________________________________

## ☐ Step 6: Install ArgoCD (5 minutes)

```bash
cd ~/projects/nti-project/infra/k8s-platform

# Install ArgoCD
./install-argocd.sh
```

**Note the admin password shown during installation:**

ArgoCD Admin Password: ___________________________________

**Verify:**
- [ ] Script completed successfully
- [ ] ArgoCD pods running: `kubectl get pods -n argocd`
- [ ] Can access ArgoCD UI via port-forward

**Access ArgoCD UI:**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then open: https://localhost:8080
- [ ] Login successful with username: `admin` and password from above

## ☐ Step 7: Prepare Application Namespace (3 minutes)

```bash
# Create namespace
kubectl create namespace voting-app

# Get MongoDB password from existing deployment
MONGO_PASS=$(kubectl get secret result-mongo-mongodb -n result -o jsonpath='{.data.mongodb-root-password}' | base64 -d)

# Create MongoDB secret in new namespace
kubectl create secret generic mongodb-atlas-credentials \
  --from-literal=connection-string="mongodb://root:${MONGO_PASS}@voting-app-mongodb:27017/voting?authSource=admin" \
  -n voting-app
```

**Verify:**
- [ ] Namespace created: `kubectl get namespace voting-app`
- [ ] Secret created: `kubectl get secret -n voting-app mongodb-atlas-credentials`

## ☐ Step 8: Update ArgoCD Configuration (2 minutes)

```bash
cd ~/projects/nti-project

# Update argocd-app.yaml with your GitHub username
# Replace YOUR_USERNAME with your actual GitHub username
sed -i 's/YOUR_USERNAME/your-actual-username/' infra/k8s-platform/argocd-app.yaml

# Verify the change
grep "repoURL" infra/k8s-platform/argocd-app.yaml
```

**Expected output:**
```
repoURL: https://github.com/your-actual-username/nti-project.git
```

- [ ] GitHub username updated correctly in argocd-app.yaml

## ☐ Step 9: Deploy Application with ArgoCD (3 minutes)

```bash
# Deploy the ArgoCD Application
kubectl apply -f infra/k8s-platform/argocd-app.yaml

# Watch deployment progress
kubectl get pods -n voting-app -w
```

**Verify in ArgoCD UI:**
- [ ] Application appears in ArgoCD
- [ ] Application is syncing
- [ ] All resources are healthy
- [ ] Pods are running

**Check deployment:**
```bash
kubectl get all -n voting-app
```

**Expected resources:**
- [ ] vote deployment and pods running
- [ ] result deployment and pods running
- [ ] worker deployment and pods running
- [ ] redis deployment and pods running
- [ ] All services created
- [ ] Ingress created

## ☐ Step 10: Test CI/CD Pipeline (5 minutes)

```bash
cd ~/projects/nti-project

# Make a small test change
echo "# CI/CD Test" >> apps/vote/README.md

# Commit and push
git add .
git commit -m "Test: Trigger CI/CD pipeline"
git push
```

**Verify:**
- [ ] Go to GitHub Actions tab
- [ ] Workflow "CI - Vote App" is running
- [ ] Build step completes successfully
- [ ] Trivy scan runs
- [ ] Image pushed to ECR
- [ ] Check GitHub Security tab for Trivy results
- [ ] ArgoCD detects change and syncs
- [ ] New pods roll out in cluster

**Monitor:**
```bash
# Watch pods update
kubectl get pods -n voting-app -w

# Check new image tag
kubectl describe pod -n voting-app -l app.kubernetes.io/component=vote | grep Image:
```

## ☐ Step 11: Access Applications (3 minutes)

### Option A: Port Forward (Quick Test)

```bash
# Vote app
kubectl port-forward -n voting-app svc/voting-app-vote 8080:80

# Result app (in another terminal)
kubectl port-forward -n voting-app svc/voting-app-result 8081:80
```

- [ ] Vote app accessible at http://localhost:8080
- [ ] Can vote for Cats or Dogs
- [ ] Result app accessible at http://localhost:8081
- [ ] Results update in real-time

### Option B: Via Ingress (Production)

**If using real domains:**
1. [ ] Configure DNS CNAME records:
   - `vote-nonprod.your-domain.com` → NGINX LoadBalancer URL
   - `result-nonprod.your-domain.com` → NGINX LoadBalancer URL

2. [ ] Update `helm/values-nonprod.yaml` with your domain:
   ```yaml
   ingress:
     hosts:
       - host: vote-nonprod.your-domain.com
       - host: result-nonprod.your-domain.com
   ```

3. [ ] Commit and push changes
4. [ ] Wait for ArgoCD to sync
5. [ ] Access via your domains

## ☐ Post-Setup Verification (5 minutes)

### Check All Components

```bash
# Platform tools
kubectl get pods -n ingress-nginx
kubectl get pods -n argocd

# Application
kubectl get pods -n voting-app
kubectl get svc -n voting-app
kubectl get ingress -n voting-app

# ArgoCD application status
kubectl get application -n argocd
```

**Expected:**
- [ ] All NGINX Ingress pods running (1/1 Ready)
- [ ] All ArgoCD pods running (1/1 Ready)
- [ ] All voting app pods running (vote, result, worker, redis)
- [ ] All services have endpoints
- [ ] Ingress has address/host

### Check CI/CD

- [ ] GitHub Actions workflows visible
- [ ] Latest workflow run successful
- [ ] Security scanning results in GitHub Security tab
- [ ] ECR repositories contain images
- [ ] ArgoCD application synced and healthy

### Test Functionality

- [ ] Can submit votes
- [ ] Can view results
- [ ] Results update when voting
- [ ] Worker processing votes (check logs)
- [ ] MongoDB storing data

## ☐ Documentation Review (Optional)

Read through the documentation to understand the system:

- [ ] `README.md` - Project overview
- [ ] `GETTING_STARTED.md` - This guide you just completed!
- [ ] `docs/SETUP.md` - Detailed setup instructions
- [ ] `docs/CICD.md` - CI/CD architecture explanation
- [ ] `docs/QUICKREF.md` - Common commands reference

## 🎉 Setup Complete!

Congratulations! You now have:

✅ Complete CI/CD pipelines with security scanning
✅ GitOps deployment with ArgoCD
✅ Production-ready Helm charts
✅ NGINX Ingress Controller
✅ Automated deployments on Git push
✅ Vulnerability scanning with Trivy
✅ Comprehensive documentation

## 📝 Next Steps

Now that your platform is running, consider:

1. **Add SSL/TLS certificates** with cert-manager
2. **Set up Vault** for secrets management
3. **Install SonarQube** for code quality analysis
4. **Deploy Nexus** for artifact management
5. **Add monitoring** with Prometheus & Grafana
6. **Implement network policies** for security
7. **Set up log aggregation** with ELK or Loki
8. **Configure backup strategy** for critical data

## 🆘 Troubleshooting

If something didn't work:

1. **Check the relevant log:**
   ```bash
   kubectl logs -n voting-app deployment/voting-app-vote
   kubectl logs -n argocd deployment/argocd-application-controller
   ```

2. **Review the documentation:**
   - `docs/QUICKREF.md` has common troubleshooting commands
   - `docs/SETUP.md` has detailed troubleshooting section

3. **Verify prerequisites:**
   - AWS credentials configured
   - kubectl access to cluster
   - GitHub secrets set correctly
   - Correct permissions on EKS cluster

## 📊 Final Status Check

Run this comprehensive check:

```bash
#!/bin/bash
echo "=== NTI Project Status Check ==="
echo ""
echo "--- Platform Tools ---"
kubectl get pods -n ingress-nginx
kubectl get pods -n argocd
echo ""
echo "--- Application ---"
kubectl get pods -n voting-app
echo ""
echo "--- Services ---"
kubectl get svc -n voting-app
echo ""
echo "--- Ingress ---"
kubectl get ingress -n voting-app
echo ""
echo "--- ArgoCD Application ---"
kubectl get application -n argocd
echo ""
echo "=== Status Check Complete ==="
```

All green? **You're done! 🚀**

---

**Setup completed on:** ___________________

**Notes:**
________________________________________________________
________________________________________________________
________________________________________________________
