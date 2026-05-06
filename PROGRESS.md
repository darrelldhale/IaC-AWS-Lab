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
Week 1 — Remote state + rebuild infra        ✅ Done
Week 2 — Terraform modules + workspaces
Week 3 — CloudFormation
Week 4 — SSM at scale + Tagging strategies

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

### Week 2 — Terraform Modules + Workspaces ✅
- [x] Refactored flat main.tf into three reusable modules: networking, compute, observability
- [x] Each module has its own variables.tf, main.tf, and outputs.tf
- [x] Wired module outputs to module inputs via root main.tf
- [x] Verified data flow: networking → compute → observability
- [x] Ran terraform init, plan, and apply with modular structure
- [x] Verified nginx HTTP 200 via SSM on modular stack
- [x] Created dev, prod, and default workspaces
- [x] Made code workspace-aware: prod gets t3.small/30d logs, dev gets t2.micro/7d logs
- [x] Verified ternary expressions drive correct values per workspace
- [x] Learned: modules, data flow between modules, workspaces, ternary expressions

### Week 3 — CloudFormation ✅
- [x] Learned CloudFormation vocabulary: stacks, parameters, resources, outputs
- [x] Mapped CloudFormation concepts to Terraform equivalents
- [x] Learned CloudFormation intrinsic functions: !Sub, !Ref
- [x] Built a CloudFormation template with SNS topic, email subscription, and CloudWatch alarms
- [x] Deployed stack with aws cloudformation deploy
- [x] Updated stack by adding a second alarm — CloudFormation diffed and added only the new resource
- [x] Deleted stack with aws cloudformation delete-stack
- [x] Verified stack resources and outputs with describe-stacks and list-stack-resources
- [x] Enabled AWS CLI auto-complete in WSL
- [x] Learned: CloudFormation vs Terraform tradeoffs, when each is used in production

### Week 4 — SSM at Scale + Tagging Strategies ✅
- [x] Built SSM Document — SRELab-HealthCheck with 4 steps: service, disk, memory, failed services
- [x] Registered document with AWS via aws ssm create-document
- [x] Ran document against EC2 instance via aws ssm send-command
- [x] Verified health check output — nginx running, disk 24%, memory healthy, no failed services
- [x] Demonstrated SSM fleet targeting by tag in AWS Console
- [x] Defined six-tag schema: Name, Project, Environment, Owner, ManagedBy, CostCenter
- [x] Built tagging-strategy.md documenting the schema and rationale
- [x] Added locals block to all three modules with merge pattern
- [x] Applied tags to all 17 resources via terraform apply
- [x] Verified Environment tag enables SSM fleet targeting — 1 target, 1 completed, 0 errors
- [x] Learned: SSM Documents vs interactive sessions, tag-based targeting, merge pattern in Terraform

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
