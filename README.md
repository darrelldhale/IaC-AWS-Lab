# SRE Lite Lab — Northwind Health Group

## The Scenario

Northwind Health Group is a mid-sized healthcare organization modernizing
their on-premises infrastructure by migrating to AWS. As their infrastructure and reliability engineer, the mandate was clear:

- **Managed services where possible** — Northwind's lean ops team cannot
  afford to patch servers, manage clusters, or babysit infrastructure.
  Every service selection favored AWS-managed over self-managed.
- **No standing server access** — Healthcare compliance requirements demand
  auditable, IAM-controlled access. No SSH, no bastion hosts, no key pairs.
  All access via SSM Session Manager.
- **Infrastructure as code, always** — Every resource defined in Terraform.
  Nothing clicked together in the console. Infrastructure is reproducible,
  version-controlled, and destroyable in minutes.
- **Zero-downtime deployments** — Patient-facing systems cannot tolerate
  maintenance windows. All deployments use blue/green patterns with
  instant rollback capability.
- **Full observability** — Every service monitored, every incident
  documented with a post-mortem, runbooks maintained for on-call response.
- **Automation first** — Manual toil is the enemy. Scripts, pipelines,
  and SSM documents replace repetitive human work across the fleet.

---

## What Was Built

Eight months of real infrastructure, built and operated as if Northwind
were a production client. Each month added a permanent layer to the system.

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

### Month 1 — SRE Foundations
Established the operational toolkit before touching AWS. Linux internals
(processes, signals, cgroups, systemd), production-grade Bash scripting,
networking fundamentals (TCP/IP, DNS, TLS, HTTP), Git workflows, AWS CLI,
and IAM fundamentals.

Built five scripts still used throughout the lab:
- `sre-snapshot.sh` — full system state capture before any change
- `sre-healthcheck.sh` — 5-layer pass/fail health report
- `sre-watchdog.sh` — auto-restart with logging and max retries
- `sre-logdig.sh` — multi-source log search with time filtering
- `tf-check.sh` - runs terraform fmt, validate, and apply

---

### Month 2 — AWS Infrastructure
Built Northwind's first AWS footprint: a production-style VPC with
public/private subnets, NAT Gateway, and an EC2 app server running nginx
in a private subnet. SSM Session Manager replaced SSH entirely — no
bastion, no key pairs, full audit trail.

Added CloudWatch alarms, SNS alerting, log shipping, and an operational
dashboard. Ran chaos testing to trigger CPU alarms and wrote a full
post-mortem documenting root cause and corrective actions.

---

### Month 3 — Infrastructure as Code
Refactored Month 2's flat Terraform into a production-grade IaC foundation:
remote state in S3, DynamoDB state locking, reusable Terraform modules,
workspace-aware environments, and a six-tag tagging strategy enabling
fleet-wide SSM targeting.

Built a custom SSM Document — `SRELab-HealthCheck` — that runs a
multi-step health check across the entire fleet simultaneously, replacing
manual SSH-based checks.

---

### Month 4 — Compute, Containers & Deployment
Migrated Northwind's compute layer from EC2 to containers. Built a custom
AMI with the full SRE toolkit baked in, then evolved through three compute
patterns:

- **EC2 + ASG + ALB** — Launch Template, Auto Scaling Group, Application
  Load Balancer. Self-healing fleet behind a load balancer.
- **ECS Fargate** — Containerized the app with Docker, pushed to ECR,
  deployed on Fargate. No EC2 instances to manage.
- **Blue/Green via CodeDeploy** — Two target groups, two ALB listeners,
  instant all-at-once traffic shift. Zero inconsistency window during
  deployments. Automatic rollback on failure.

Chose Fargate specifically because Northwind's ops team cannot manage
underlying EC2 instances at scale.

---

### Month 5 — Observability
Running infrastructure without visibility is operating blind. Northwind's
compliance requirements demand audit trails, and their on-call team needs
to know about problems before patients do.

Instrumented the entire ECS Fargate stack with production-grade observability:
- **Structured logging** — CloudWatch Container Insights with JSON-formatted
  logs, queryable by field rather than grep. Every container log has a
  permanent home regardless of task lifecycle.
- **Distributed tracing** — X-Ray traces requests end to end across services,
  identifying latency bottlenecks and failure points that logs alone can't
  surface.
- **Real on-call dashboard** — A single CloudWatch dashboard showing the
  metrics that matter during an incident: request rate, error rate, latency,
  task health, and target group status.
- **SLIs and SLOs** — Defined Service Level Indicators (what to measure)
  and Service Level Objectives (what acceptable looks like) for
  Northwind's patient-facing services. Availability target: 99.9%.
- **Error budgets** — Translated SLOs into error budgets that make the
  tradeoff between reliability and velocity concrete and visible.
- **Synthetic monitoring** — CloudWatch Canaries run scripted browser
  checks against the ALB endpoint every minute, catching failures before
  real users report them.

Chose CloudWatch as the observability platform specifically because
Northwind's team is small and cannot operate a separate observability
stack. Native AWS integration means zero additional infrastructure to
manage or secure.

---

### Month 6 — Incident Management & Chaos Engineering
Northwind's previous on-premises environment had no formal incident
process. Outages were resolved by whoever was available, with no
documentation, no post-mortems, and no way to prevent repeat failures.
That changes here.

Built a complete incident management practice from the ground up:
- **Incident response playbook** — Step-by-step runbooks for every
  known failure mode: ECS task crashes, ALB health check failures,
  deployment rollbacks, database connectivity loss. Written to be
  executable under pressure at 2am.
- **SSM fleet runbooks** — The `SRELab-HealthCheck` document built in
  Month 3 is extended into a suite of operational runbooks executable
  across the entire fleet simultaneously with a single CLI command.
- **AWS Fault Injection Simulator** — Deliberately broke the system
  under controlled conditions: killed ECS tasks, injected network
  latency, throttled CPU. Verified that auto-recovery, alerting, and
  runbooks all behaved as expected before a real incident forced the test.
- **On-call simulation** — Ran full incident simulations with a live
  broken system, a runbook, and a timer. Built muscle memory for the
  triage process before a real patient-facing outage demanded it.
- **Backup and DR testing** — Defined and tested recovery time objectives.
  Verified that infrastructure could be rebuilt from Terraform state in
  under ten minutes. Verified data recovery procedures.

The philosophy: chaos engineering is not about breaking things for sport.
It is about discovering failure modes in a controlled environment so they
are not discovered by patients during a critical moment.

---

### Month 7 — Security, Networking & Cost
Healthcare infrastructure carries unique obligations. HIPAA requires
strict access controls, audit trails, and encryption. Northwind's board
requires cost predictability. Both are addressed here.

**Security:**
- **AWS Security Hub and GuardDuty** — Continuous threat detection and
  security posture scoring across the entire AWS account. Findings
  surfaced and triaged as part of the operational workflow.
- **AWS Config** — Every resource configuration change recorded and
  evaluated against compliance rules. Drift from approved baselines
  triggers alerts before auditors find it first.
- **VPC Flow Logs** — Network traffic logged at the VPC level. Essential
  for forensic investigation and detecting unexpected communication
  patterns between services.
- **Secrets Manager** — Database credentials, API keys, and certificates
  stored and rotated automatically. No secrets in environment variables,
  no secrets in code, no secrets in Terraform state.
- **Parameter Store** — Non-sensitive configuration stored centrally,
  versioned, and accessible to ECS tasks via IAM — not hardcoded into
  container images.

**Cost:**
- **Cost Explorer and Budgets** — Monthly spend tracked by service and
  tagged resource. Budget alerts fire before overspend happens, not after
  the invoice arrives.
- **Rightsizing** — ECS task CPU and memory allocations reviewed against
  actual utilization. Fargate pricing is per vCPU and GB — over-allocated
  tasks are direct waste.

Chosen because Northwind cannot afford a dedicated security team. Native
AWS security services provide enterprise-grade coverage without additional
tooling to operate or license.

---

### Month 8 — Capstone
Everything built across seven months assembled into a single production-grade
system that Northwind could operate on day one.

- **Multi-tier architecture** — A load-balanced ECS Fargate application
  tier backed by an RDS database tier and ElastiCache caching layer.
  Each tier isolated by security groups, each accessible only to the
  tier directly above it.
- **Full IaC** — Every resource, every tier, every configuration defined
  in Terraform. The entire system reproducible from a single
  `terraform apply` with no manual steps.
- **CI/CD pipeline** — GitHub Actions builds the Docker image on every
  push to main, tags it with the commit SHA, pushes to ECR, and triggers
  a CodeDeploy blue/green deployment automatically. Engineers push code,
  the pipeline handles the rest.
- **Full observability stack** — Every tier instrumented with structured
  logging, X-Ray tracing, CloudWatch dashboards, and synthetic monitoring.
  One dashboard tells the on-call engineer everything they need to know.
- **Chaos engineering** — AWS FIS scenarios run against the production-grade
  system: task failures, AZ outages, database failovers. Each scenario
  paired with a runbook and verified to recover within SLO.
- **Post-mortem** — A deliberately introduced incident, triaged using
  the runbooks, resolved, and documented with root cause analysis and
  corrective actions.
- **SRE portfolio document** — A written summary of the system, the
  decisions made, the incidents handled, and the lessons learned.
  Suitable for sharing with a hiring manager or engineering team.

The capstone is not a tutorial completion. It is evidence that Northwind's
infrastructure can be built, operated, broken, fixed, and handed off —
by one engineer, with documented processes, in a way that scales.

---

## Key Decisions & Lessons Learned

**SSM over SSH** — No bastion host, no key pairs. SSM Session Manager
provides auditable, IAM-controlled shell access. Required for Northwind's
compliance posture.

**Fargate over EC2** — Northwind's ops team is lean. Fargate eliminates
EC2 patching, capacity planning, and AMI management for the container
workload.

**Blue/green over rolling** — Rolling deployments create a window where
old and new versions serve traffic simultaneously. For patient-facing
systems that's unacceptable. Blue/green shifts all traffic at once with
instant rollback.

**Remote state from day one** — S3 backend with DynamoDB locking prevents
state corruption and makes infrastructure recoverable from any machine.

**Destroy nightly, rebuild daily** — NAT Gateways and load balancers cost
money. IaC makes rebuilding trivial, so non-production infrastructure is
destroyed overnight and rebuilt each morning in under five minutes.

**CloudWatch dimensions bug** — Alarms were created but never evaluated.
Root cause: dimensions block contained resource tags instead of the
instance ID. The alarm was never pointed at an actual resource. Fixed by
correcting the dimensions to reference the EC2 instance ID directly. This was in the early stages before Fargate.
