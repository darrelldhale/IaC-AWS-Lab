#SRE Lite Lab

A self-paced, hands-on SRE engineering lab built over 8 months.
Each month builds on the last — from Linux internals to a production-grade,
fully observable, chaos-tested system on AWS.

## Goal

Build the skills and portfolio through real tools, real infrastructure, and real incident response — not tutorials.

## Environment

- OS: Windows with WSL2 (Ubuntu) in VS Code
- CentOS Stream 10 VM in VMware (Linux hands-on work)
- Cloud: AWS (us-east-1) — iamadmin with AdministratorAccess
- IaC: Terraform v1.14.8
- Source Control: GitHub

## Repo Structure
```
sre-lite-lab/
├── README.md
├── PROGRESS.md                  # Week-by-week progress tracker
├── scripts/                     # Shared bash scripts built in Month 1
│   ├── sre-snapshot.sh          # Full system state capture
│   ├── sre-healthcheck.sh       # 5-layer pass/fail health report
│   ├── sre-watchdog.sh          # Auto-restart with logging and retries
│   └── sre-logdig.sh            # Multi-source log search with time filter
├── references/
│   ├── sre-command-runbook.md   # Command reference built during the lab
│   └── sre-triage-playbook.md   # Incident triage playbook
├── month-1-sre-foundations/     # Linux, Bash, Networking, Git, IAM
├── month-2-aws-infra/           # VPC, EC2, SSM, CloudWatch (original build)
├── month-3-iac/                 # Terraform remote state, modules, workspaces
├── month-4-compute/             # EC2 deep dive, Docker, ECS, EKS intro
├── month-5-observability/       # CloudWatch, X-Ray, SLOs, error budgets
├── month-6-chaos/               # Incident response, FIS, DR testing
├── month-7-security/            # GuardDuty, Secrets Manager, FinOps
└── month-8-capstone/            # Production-grade system, full IaC, CI/CD
```
## Month Summaries

### Month 1 — SRE Foundations ✅
Linux internals (processes, signals, cgroups, systemd), Bash scripting,
networking fundamentals (TCP/IP, DNS, TLS, HTTP), Git workflows, AWS CLI,
and IAM fundamentals. Built 4 production-style bash scripts.

### Month 2 — AWS Infrastructure ✅
Built a full VPC with public/private subnets, NAT Gateway, and an EC2
app server running nginx in a private subnet. Access via SSM Session Manager
(no bastion, no SSH). Added CloudWatch alarms, SNS alerting, log shipping,
and a dashboard. Ran chaos testing to trigger CPU alarms and wrote a
post-mortem. Infrastructure destroyed after the month to save costs.
Original Terraform lives in `month-2-aws-infra/` as a learning artifact.

### Month 3 — Infrastructure as Code 🔄 In Progress
Refactoring Month 2 infra with Terraform best practices: remote state in S3,
DynamoDB state locking, consolidated root module, Terraform modules,
workspaces, and a tagging strategy.

### Month 4 — Compute, Containers & Deployment 📅 Planned
EC2 launch templates, AMIs, Auto Scaling Groups, Docker, ECS Fargate,
blue/green and canary deployments, EKS introduction.

### Month 5 — Observability 📅 Planned
Structured logging, X-Ray tracing, real on-call dashboards, SLIs, SLOs,
error budgets, synthetic monitoring.

### Month 6 — Incident Management & Chaos Engineering 📅 Planned
Full incident response playbook, AWS Fault Injection Simulator, runnable
runbooks, on-call simulation, backup and DR testing.

### Month 7 — Security, Networking & Cost 📅 Planned
Security Hub, GuardDuty, Config, VPC Flow Logs, Secrets Manager,
Parameter Store, FinOps with Cost Explorer and Budgets.

### Month 8 — Capstone 📅 Planned
Multi-tier, highly available production-grade system. Full IaC,
observability stack, CI/CD pipeline, chaos engineering, post-mortem,
and SRE portfolio document.

## Key Decisions & Lessons Learned

- **SSM over SSH** — No bastion host, no key pairs. SSM Session Manager
  provides auditable, IAM-controlled shell access to private instances.
- **Remote state from day one (Month 3)** — S3 backend with DynamoDB locking
  prevents state corruption and makes infra recoverable from any machine.
- **Destroy between months** — NAT Gateways and EC2 instances cost money.
  IaC makes rebuilding trivial, so infrastructure is destroyed between months
  and rebuilt when needed.
- **Scripts centralized** — Bash scripts built in Month 1 live in `scripts/`
  at the repo root for reuse across months.
