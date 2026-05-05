# SRE Lite Lab — Progress Tracker

## Environment
- OS: Windows with WSL (Ubuntu) in VS Code
- AWS Account: iamadmin user with admin access
- Region: us-east-1
- Terraform: v1.14.8
- GitHub: https://github.com/darrelldhale/sre-lite-lab

---

## Month 1 — SRE Foundations ⬅️ IN PROGRESS

### Week 1 — Linux Internals (In Progress)
- [x] Processes, PIDs, parent/child relationships
- [x] Signals and how the kernel communicates with processes
- [x] File descriptors and why everything is a file
- [x] systemd: units, targets, journald
- [x] cgroups: resource limits and container foundations

### Week 2 — Bash Scripting ✅
- [x] Variables, conditionals, loops, functions
- [x] Error handling: set -euo pipefail, exit codes, || true
- [x] Argument validation: $#, $1, $2, default values
- [x] Arrays and for loops
- [x] Built sre-snapshot.sh — full system state capture
- [x] Built sre-healthcheck.sh — 5-layer pass/fail health report
- [x] Built sre-watchdog.sh — auto-restart with logging and max retries
- [x] Built sre-logdig.sh — multi-source log search with time filtering

### Week 3 — Networking Fundamentals (Planned)
- [x] TCP/IP: how packets actually move
- [x] DNS: resolution from stub to root
- [x] HTTP: requests, responses, status codes
- [x] TLS: handshake, certificates, trust chains
- [x] Debugging tools: curl, dig, netstat, tcpdump

### Week 4 — Git Workflows + AWS CLI + IAM ✅
- [x] Git branching: checkout -b, merge, fast-forward vs merge commit
- [x] Branch cleanup and push workflow
- [x] AWS CLI output formats: json, table, text
- [x] JMESPath filtering with --query
- [x] IAM users, groups, policies, roles
- [x] AdministratorAccess policy — what it means
- [x] Service-linked roles — what they are and where they come from
- [x] Least privilege principle

---

## Month 2 — AWS Infrastructure ✅

### Week 1 ✅
- Configured AWS CLI and Terraform in WSL
- Created GitHub repo and pushed initial structure

### Week 2 ✅
- Built VPC, public/private subnets, IGW, NAT Gateway, route tables
- Built App Server (EC2) in private subnet with nginx via user_data
- Dropped Bastion in favor of SSM Session Manager for access
- Verified nginx serving HTTP 200 via SSM session
- Learned: agent forwarding, SSM vs SSH, .gitignore discipline

### Week 3 ✅
- Created SNS topic and email subscription for alerts
- Built CloudWatch CPU alarm (triggers >80% for 4 minutes)
- Built CloudWatch log group and nginx 4xx metric filter
- Built CloudWatch dashboard with CPU and error widgets
- Installed and configured CloudWatch agent on App Server via SSM
- Verified nginx logs shipping to CloudWatch log group
- Learned: data sources, IAM policy attachments, CloudWatch agent config

### Week 4 ✅
- Installed stress tooling on App Server via SSM
- Diagnosed and fixed misconfigured CloudWatch alarm dimensions
- Successfully triggered CPU alarm above 80% threshold
- Received ALARM and OK email notifications via SNS
- Wrote runbook for high CPU incident response
- Wrote post-mortem documenting root cause and lessons learned
- Learned: chaos engineering, CPU burst credits, alarm dimensions, incident documentation

---

## Month 3 — Infrastructure as Code

### Week 1 — Remote State + Infrastructure Rebuild ✅
- [x] Created S3 bucket for Terraform remote state with versioning and public access blocked
- [x] Created DynamoDB table for state locking
- [x] Consolidated Month 2 week-2 and week-3 configs into a single Terraform root
- [x] Wired S3 backend — state lives at month-3/week-1/terraform.tfstate
- [x] Rebuilt full infrastructure: VPC, subnets, IGW, NAT Gateway, EC2, SSM, CloudWatch, SNS
- [x] Verified nginx serving HTTP 200 via SSM session
- [x] Verified SSM agent and CloudWatch agent installed via user_data
- [x] Centralized Month 1 bash scripts into repo-level scripts/ directory
- [x] Wrote full repo README.md with month summaries and key decisions
- [x] Learned: remote state, state locking, bootstrap problem, consolidated roots

---

## Month 4 — Compute, Containers & Deployment (Planned)
- EC2 deep dive: launch templates, AMIs, Auto Scaling Groups
- Docker fundamentals and ECS Fargate
- Blue/Green and canary deployment patterns
- Introduction to EKS

---

## Month 5 — Observability (Planned)
- CloudWatch the right way: structured logging, X-Ray tracing
- Real on-call dashboard
- SLIs, SLOs, error budgets
- Synthetic monitoring and canaries

---

## Month 6 — Incident Management & Chaos Engineering (Planned)
- Full incident response playbook
- AWS Fault Injection Simulator (FIS)
- Runnable runbooks
- On-call simulation exercises
- Backup/restore and DR testing

---

## Month 7 — Security, Networking & Cost (Planned)
- AWS Security Hub, GuardDuty, Config
- VPC Flow Logs
- Secrets Manager and Parameter Store
- FinOps: Cost Explorer, Budgets, rightsizing

---

## Month 8 — Capstone (Planned)
- Multi-tier, highly available production-grade system
- Full IaC, observability, CI/CD pipeline
- Chaos engineering with own runbooks
- Post-mortem
- SRE portfolio document
