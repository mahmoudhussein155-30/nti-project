# Quick Reference Guide

## Common Commands

### Kubernetes

```bash
# Get all resources in namespace
kubectl get all -n voting-app

# Check pod logs
kubectl logs -f -n voting-app deployment/voting-app-vote

# Describe pod for troubleshooting
kubectl describe pod -n voting-app POD_NAME

# Execute command in pod
kubectl exec -it -n voting-app POD_NAME -- /bin/sh

# Port forward to service
kubectl port-forward -n voting-app svc/voting-app-vote 8080:80

# Delete and recreate pod
kubectl delete pod -n voting-app POD_NAME

# Scale deployment
kubectl scale deployment voting-app-vote -n voting-app --replicas=3
```

### Helm

```bash
# Install chart
helm install voting-app ./helm -f ./helm/values-nonprod.yaml -n voting-app --create-namespace

# Upgrade release
helm upgrade voting-app ./helm -f ./helm/values-nonprod.yaml -n voting-app

# Rollback release
helm rollback voting-app -n voting-app

# List releases
helm list -n voting-app

# Get values
helm get values voting-app -n voting-app

# Uninstall
helm uninstall voting-app -n voting-app
```

### ArgoCD

```bash
# Login to ArgoCD CLI
argocd login localhost:8080

# List applications
argocd app list

# Get application details
argocd app get voting-app-nonprod

# Sync application
argocd app sync voting-app-nonprod

# Check sync status
argocd app wait voting-app-nonprod

# View application logs
argocd app logs voting-app-nonprod

# Rollback application
argocd app rollback voting-app-nonprod

# Delete application
argocd app delete voting-app-nonprod
```

### Docker

```bash
# Build image
docker build -t vote:test apps/vote

# Run container locally
docker run -p 8080:80 vote:test

# Login to ECR
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 756148348733.dkr.ecr.eu-west-1.amazonaws.com

# Tag image
docker tag vote:test 756148348733.dkr.ecr.eu-west-1.amazonaws.com/vote:test

# Push to ECR
docker push 756148348733.dkr.ecr.eu-west-1.amazonaws.com/vote:test

# Pull from ECR
docker pull 756148348733.dkr.ecr.eu-west-1.amazonaws.com/vote:nonprod
```

### AWS CLI

```bash
# Update kubeconfig
aws eks update-kubeconfig --name nti-eks-nonprod --region eu-west-1

# List ECR repositories
aws ecr describe-repositories --region eu-west-1

# List images in repository
aws ecr list-images --repository-name vote --region eu-west-1

# Get EKS cluster info
aws eks describe-cluster --name nti-eks-nonprod --region eu-west-1
```

### Git

```bash
# Initialize repo
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/USERNAME/nti-project.git
git push -u origin main

# Create feature branch
git checkout -b feature/new-feature
git add .
git commit -m "Add new feature"
git push origin feature/new-feature

# Update from main
git checkout main
git pull origin main
git checkout feature/new-feature
git merge main
```

## Troubleshooting Checklist

### Pod Won't Start

- [ ] Check pod events: `kubectl describe pod POD_NAME -n voting-app`
- [ ] Check logs: `kubectl logs POD_NAME -n voting-app`
- [ ] Verify image exists in ECR
- [ ] Check resource limits
- [ ] Verify secrets exist
- [ ] Check node capacity: `kubectl top nodes`

### Image Pull Errors

- [ ] Verify ECR repository exists
- [ ] Check IAM permissions for nodes
- [ ] Verify image tag is correct
- [ ] Check if image was pushed successfully
- [ ] Test pull locally with Docker

### Service Not Accessible

- [ ] Check service exists: `kubectl get svc -n voting-app`
- [ ] Verify pod is running and ready
- [ ] Check service selector matches pod labels
- [ ] Test from within cluster: `kubectl run -it --rm debug --image=busybox --restart=Never -- wget -O- SERVICE_NAME`
- [ ] Check ingress configuration

### MongoDB Connection Issues

- [ ] Verify secret exists: `kubectl get secret mongodb-atlas-credentials -n voting-app`
- [ ] Check secret data: `kubectl get secret mongodb-atlas-credentials -n voting-app -o yaml`
- [ ] Verify MongoDB pod is running
- [ ] Test connection from result pod
- [ ] Check environment variables in pod

### CI Pipeline Failures

- [ ] Check GitHub Actions logs
- [ ] Verify AWS credentials in secrets
- [ ] Check ECR repository permissions
- [ ] Review Trivy scan results
- [ ] Verify Dockerfile syntax
- [ ] Check build context path

### ArgoCD Sync Issues

- [ ] Check application status: `argocd app get voting-app-nonprod`
- [ ] View sync differences: `argocd app diff voting-app-nonprod`
- [ ] Check ArgoCD controller logs
- [ ] Verify Git repository is accessible
- [ ] Check Helm values syntax
- [ ] Review ArgoCD events

## Quick Deployment

### Deploy Everything from Scratch

```bash
# 1. Install platform tools
cd infra/k8s-platform
./install-nginx-ingress.sh
./install-argocd.sh

# 2. Create namespace and secrets
kubectl create namespace voting-app
kubectl create secret generic mongodb-atlas-credentials \
  --from-literal=connection-string="mongodb://root:PASSWORD@voting-app-mongodb:27017/voting?authSource=admin" \
  -n voting-app

# 3. Deploy with ArgoCD
kubectl apply -f argocd-app.yaml

# 4. Monitor deployment
watch kubectl get pods -n voting-app
```

### Update Single Service

```bash
# Make code changes to vote app
cd apps/vote
# Edit files

# Commit and push
git add .
git commit -m "Update vote app UI"
git push

# CI will automatically build, scan, and push
# ArgoCD will automatically deploy
# Watch progress:
kubectl get pods -n voting-app -w
```

## Access URLs

### Local Access (Port Forward)

```bash
# Vote app
kubectl port-forward -n voting-app svc/voting-app-vote 8080:80
# Access at: http://localhost:8080

# Result app
kubectl port-forward -n voting-app svc/voting-app-result 8081:80
# Access at: http://localhost:8081

# ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8443:443
# Access at: https://localhost:8443
```

### Production Access (Ingress)

```bash
# Get LoadBalancer URL
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Configure DNS:
# vote-nonprod.nti-project.com → LoadBalancer URL
# result-nonprod.nti-project.com → LoadBalancer URL
```

## Monitoring

### Check Application Health

```bash
# All pods running?
kubectl get pods -n voting-app

# Any errors in logs?
kubectl logs -n voting-app -l app.kubernetes.io/component=vote --tail=100 | grep -i error
kubectl logs -n voting-app -l app.kubernetes.io/component=result --tail=100 | grep -i error
kubectl logs -n voting-app -l app.kubernetes.io/component=worker --tail=100 | grep -i error

# Resource usage
kubectl top pods -n voting-app
kubectl top nodes
```

### Check Platform Health

```bash
# NGINX Ingress
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50

# ArgoCD
kubectl get pods -n argocd
argocd app list
```

## Security

### Rotate Secrets

```bash
# MongoDB credentials
kubectl delete secret mongodb-atlas-credentials -n voting-app
kubectl create secret generic mongodb-atlas-credentials \
  --from-literal=connection-string="NEW_CONNECTION_STRING" \
  -n voting-app

# Restart pods to pick up new secret
kubectl rollout restart deployment/voting-app-result -n voting-app
```

### Review Vulnerabilities

```bash
# Check GitHub Security tab
# https://github.com/USERNAME/nti-project/security/code-scanning

# Run manual Trivy scan
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image 756148348733.dkr.ecr.eu-west-1.amazonaws.com/vote:nonprod
```

## Backup & Recovery

### Backup ArgoCD Applications

```bash
# Export all applications
kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml
```

### Backup Helm Values

```bash
# Values are in Git, but also export current running config
helm get values voting-app -n voting-app > current-values-backup.yaml
```

## Performance Tuning

### Scale Applications

```bash
# Horizontal scaling
kubectl scale deployment voting-app-vote -n voting-app --replicas=5

# Update in Helm values for permanence
# Edit helm/values-nonprod.yaml:
# replicaCount:
#   vote: 5
```

### Resource Limits

```bash
# Check current usage
kubectl top pods -n voting-app

# Update in Helm values if needed
# Edit resources section in values files
```

## Emergency Procedures

### Complete Rollback

```bash
# Rollback via ArgoCD
argocd app rollback voting-app-nonprod

# Or via Helm
helm rollback voting-app -n voting-app

# Or via Kubernetes
kubectl rollout undo deployment/voting-app-vote -n voting-app
kubectl rollout undo deployment/voting-app-result -n voting-app
kubectl rollout undo deployment/voting-app-worker -n voting-app
```

### Emergency Pod Restart

```bash
# Restart all deployments
kubectl rollout restart deployment -n voting-app

# Or delete specific pods (they'll be recreated)
kubectl delete pod -n voting-app -l app.kubernetes.io/component=vote
```

### Clear Stuck State

```bash
# Delete and recreate application
kubectl delete application voting-app-nonprod -n argocd
kubectl apply -f infra/k8s-platform/argocd-app.yaml

# Force sync
argocd app sync voting-app-nonprod --force --prune
```
