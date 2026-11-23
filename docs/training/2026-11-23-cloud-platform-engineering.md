# Cloud / Platform Engineering — Hands-on Lab

**Date:** November 23, 2026  
**Environment:** macOS (Apple Silicon), Docker Desktop, local Kubernetes, Terraform, Git, VS Code.

## 1. AWS and Terraform

Reviewed the existing VPC configuration and resource dependencies, public/private subnet isolation, and private route table. The private route table had no default internet route. Earlier repository corrections fixed PostgreSQL ingress to TCP 5432 and added the private subnet route table association (PR #1).

```bash
terraform fmt -check
terraform validate
grep -n '^resource ' main.tf
grep -n 'aws_vpc.main.id' main.tf
grep -A 9 'resource "aws_subnet" "private"' main.tf
grep -A 12 'resource "aws_route_table" "private"' main.tf
```

Local validation is not a live AWS deployment test. No AWS resources were deployed.

## 2. Linux and Git

```bash
ls -lah
ls -l main.tf
git status
git log --oneline -5
```

Observed file permissions: owner read/write, group and others read-only. Reviewed hidden files and Terraform dependency files. Git reported a clean working tree and main matched the locally recorded origin/main. Reviewed the initial infrastructure commit, networking fix and merge commit.

## 3. Docker installation and troubleshooting

Initially the Docker CLI was unavailable. Installed Docker Desktop for Apple Silicon. The CLI subsequently reported an engine connection error; starting Docker Desktop resolved connectivity.

```bash
docker --version
docker info
docker run hello-world
docker ps -a
```

Observed Docker Engine responding, ARM64 architecture, 8 allocated CPUs and approximately 3.825 GiB memory. The hello-world image was downloaded and its container exited successfully (0).

### Container incident investigation

An existing guestbook container had exited with code 2. Inspected logs and state without restarting or deleting it.

```bash
docker logs <container-id>
docker inspect --format '{{.State.ExitCode}} {{.State.OOMKilled}} {{.State.Error}}' <container-id>
```

Evidence: HTTP server listened on port 3000; requests returned 200, 304 and a favicon 404. Exit code 2, OOMKilled false, runtime error field empty. Root cause remained undetermined; the favicon response alone does not explain termination. Further investigation would require application-level diagnostics.

## 4. Kubernetes — local deployment lifecycle

Verified kubectl v1.36.1 and Kustomize v5.8.1.

```bash
kubectl version --client
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
kubectl config current-context
```

Observed one Ready control-plane node, nine running Pods with zero restarts, and the docker-desktop context. Explicitly targeted that local context for all mutations.

```bash
kubectl --context=docker-desktop -n default create deployment nginx-practice --image=nginx:alpine
kubectl --context=docker-desktop -n default get deployment nginx-practice
kubectl --context=docker-desktop -n default delete deployment nginx-practice
```

Observed deployment created, READY 1/1, UP-TO-DATE 1, AVAILABLE 1, and successful deletion. This demonstrates local deployment readiness and cleanup, not an end-to-end HTTP test or production deployment.

## 5. GitHub Actions — CI design introduction

Reviewed a proposed validation-only workflow triggered by pushes and pull requests:

1. Check out repository code.
2. Install Terraform.
3. Run terraform fmt -check.
4. Run terraform init -backend=false.
5. Run terraform validate.

Workflow implementation and execution are future work; no automated CI run was performed during this session. No plan/apply or AWS credentials are required for the proposed validation-only checks.

## Outcomes

- Infrastructure inspection and network security reasoning
- Unix file permissions and Git history review
- Docker installation, engine connectivity, container lifecycle and incident investigation
- Kubernetes cluster inspection, context safety, deployment and cleanup
- CI/CD validation concepts

All exercises were performed locally or reviewed conceptually. No AWS infrastructure was deployed. Existing application containers were preserved. Personal paths, machine identifiers and raw logs are intentionally omitted.
