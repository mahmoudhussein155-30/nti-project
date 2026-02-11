# CI/CD Pipeline Documentation

## Overview

This project uses **GitHub Actions** for Continuous Integration and **ArgoCD** for Continuous Deployment, following GitOps principles.

## CI Pipeline Architecture

```
Code Push → GitHub Actions → Build → Trivy Scan → ECR Push → Update Helm Values
                                ↓
                         (CRITICAL found?)
                                ↓
                            Fail Build
```

## Workflows

### 1. Vote App CI (`ci-vote.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Changes in `apps/vote/**` or workflow file
- Pull requests to `main` or `develop`

**Steps:**
1. Checkout code
2. Set up Docker Buildx
3. Configure AWS credentials
4. Login to Amazon ECR
5. Build Docker image with caching
6. **Run Trivy vulnerability scanner** (SARIF format)
7. Upload results to GitHub Security tab
8. **Run Trivy table output** (human-readable)
9. **Check for CRITICAL vulnerabilities** (fails if found)
10. Push image to ECR (only on `main` branch push)
11. Update Helm values with new image tag
12. Generate build summary

**Security Features:**
- Scans for CRITICAL, HIGH, and MEDIUM vulnerabilities
- Blocks deployment if CRITICAL vulnerabilities found (unfixed)
- Uploads results to GitHub Security for tracking
- Uses image caching for faster builds

### 2. Result App CI (`ci-result.yml`)

Same structure as Vote App CI, but for the Result microservice.

### 3. Worker App CI (`ci-worker.yml`)

Same structure as Vote App CI, but for the Worker microservice.

## Security Scanning with Trivy

### What Trivy Scans

- **OS Packages**: Vulnerabilities in Alpine, Ubuntu, Debian, etc.
- **Application Dependencies**: npm, pip, .NET packages
- **Misconfigurations**: Dockerfile best practices
- **Secrets**: Hardcoded passwords, API keys

### Severity Levels

- **CRITICAL**: Immediate action required, blocks deployment
- **HIGH**: Should be fixed soon
- **MEDIUM**: Fix when possible
- **LOW**: Informational

### Viewing Results

1. **GitHub Security Tab:**
   - Go to Security → Code scanning alerts
   - View all vulnerabilities found
   - Filter by severity

2. **Workflow Logs:**
   - Go to Actions → Select workflow run
   - View Trivy table output in logs

3. **Build Summary:**
   - Each workflow run shows a summary
   - Quick overview of scan results

## CD Pipeline (ArgoCD)

### GitOps Workflow

```
1. Developer pushes code
2. CI builds & scans image
3. CI updates Helm values with new image tag
4. ArgoCD detects Git change
5. ArgoCD syncs cluster to match Git state
6. New pods roll out automatically
```

### ArgoCD Configuration

**Auto-Sync Enabled:**
- Automatically deploys when Git changes
- Self-heal: reverts manual kubectl changes
- Prune: removes resources deleted from Git

**Sync Policy:**
- Creates namespace if needed
- Retries on failure (5 attempts)
- Prunes resources last (safer)

### Manual Sync

```bash
# Trigger manual sync
argocd app sync voting-app-nonprod

# Get sync status
argocd app get voting-app-nonprod
```

## Environment Strategy

### Nonprod Environment

- **Branch**: `main`
- **Namespace**: `voting-app`
- **Values**: `values-nonprod.yaml`
- **Replicas**: 1 per service
- **Resources**: Minimal (dev/test)

### Production Environment (Future)

- **Branch**: `production`
- **Namespace**: `voting-app-prod`
- **Values**: `values-prod.yaml`
- **Replicas**: 2+ per service
- **Resources**: Production-grade
- **Additional**: HPA, PDB, Network Policies

## Image Tagging Strategy

Each build creates 3 tags:
1. **Git SHA**: `756148348733.dkr.ecr.eu-west-1.amazonaws.com/vote:a1b2c3d`
   - Immutable, traceable
2. **Environment**: `756148348733.dkr.ecr.eu-west-1.amazonaws.com/vote:nonprod`
   - Latest for that environment
3. **Latest**: `756148348733.dkr.ecr.eu-west-1.amazonaws.com/vote:latest`
   - Most recent build

## Deployment Process

### Automatic Deployment (Recommended)

1. Make code changes
2. Commit and push to `main`
3. CI pipeline runs automatically
4. If successful, ArgoCD deploys within 3 minutes

### Manual Deployment

```bash
# Build and push image manually
docker build -t 756148348733.dkr.ecr.eu-west-1.amazonaws.com/vote:manual apps/vote
docker push 756148348733.dkr.ecr.eu-west-1.amazonaws.com/vote:manual

# Update Helm values
cd helm
sed -i 's/tag: .*/tag: "manual"/' values-nonprod.yaml
git add values-nonprod.yaml
git commit -m "Deploy manual build"
git push

# ArgoCD will sync automatically
```

## Rollback Strategy

### Using ArgoCD

```bash
# View history
argocd app history voting-app-nonprod

# Rollback to previous version
argocd app rollback voting-app-nonprod

# Rollback to specific revision
argocd app rollback voting-app-nonprod 5
```

### Using Kubernetes

```bash
# Rollback deployment
kubectl rollout undo deployment/voting-app-vote -n voting-app

# Check rollout status
kubectl rollout status deployment/voting-app-vote -n voting-app
```

## Monitoring CI/CD

### GitHub Actions Dashboard

- View all workflow runs
- Check build times
- Review security scan results

### ArgoCD Dashboard

- Sync status for all apps
- Application health
- Resource utilization
- Sync history

### Alerts (Future)

- Slack notifications on build failures
- Email on CRITICAL vulnerabilities
- Discord webhooks for deployments

## Best Practices

### Code Changes

1. ✅ Create feature branch
2. ✅ Make changes
3. ✅ Commit with descriptive message
4. ✅ Push and create PR
5. ✅ CI runs on PR (no deployment)
6. ✅ Review and merge to `main`
7. ✅ CI runs and deploys automatically

### Security

1. ✅ Never commit secrets
2. ✅ Review Trivy scan results
3. ✅ Fix CRITICAL vulnerabilities immediately
4. ✅ Address HIGH vulnerabilities within a week
5. ✅ Keep base images updated
6. ✅ Use minimal base images (Alpine)

### Testing

1. ✅ Test locally first
2. ✅ Verify Dockerfile builds
3. ✅ Check application logs after deployment
4. ✅ Validate with smoke tests
5. ✅ Monitor metrics

## Troubleshooting

### CI Pipeline Issues

**Build Fails:**
```bash
# Check workflow logs in GitHub Actions
# Common issues:
- Dockerfile syntax errors
- Missing dependencies
- ECR authentication failures
```

**Trivy Scan Fails:**
```bash
# CRITICAL vulnerability found
# Options:
1. Update base image
2. Update dependencies
3. Add exception if false positive
```

**ECR Push Fails:**
```bash
# Check AWS credentials in GitHub secrets
# Verify ECR repository exists
aws ecr describe-repositories --repository-names vote --region eu-west-1
```

### ArgoCD Issues

**App Out of Sync:**
```bash
# Check what's different
argocd app diff voting-app-nonprod

# Force sync
argocd app sync voting-app-nonprod --force
```

**Sync Fails:**
```bash
# Check application events
kubectl describe application voting-app-nonprod -n argocd

# Check controller logs
kubectl logs -n argocd deployment/argocd-application-controller
```

## Metrics & KPIs

Track these metrics for CI/CD health:

- **Build Time**: Target < 5 minutes
- **Deployment Time**: Target < 3 minutes
- **Success Rate**: Target > 95%
- **Vulnerabilities**: Track and trend
- **MTTR**: Mean time to recovery
- **Deployment Frequency**: Track velocity

## Future Enhancements

- [ ] Add unit tests in CI
- [ ] Add integration tests
- [ ] Implement Blue/Green deployments
- [ ] Add Canary releases
- [ ] Set up SonarQube integration
- [ ] Add performance testing
- [ ] Implement approval gates for prod
- [ ] Add Slack notifications
- [ ] Set up Grafana dashboards
- [ ] Implement automated rollbacks on health check failures
