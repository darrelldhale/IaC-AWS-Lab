# IaC-AWS-Lab

**A self-directed SRE and cloud infrastructure lab: an 8-month, hands-on build of a production-grade AWS environment defined entirely in Terraform, operated, monitored, deliberately broken, and documented end to end.**

Built and maintained by **Darrell Hale**, Lead Application Support Engineer with a focus on incident response, monitoring, and reliability. Culminated in the **AWS Certified CloudOps Engineer, Associate (SOA-C03)**.

Contact: look585carbon@gmail.com

> **About this lab:** This is a personal, self-directed learning project, not client or employer work. To keep the engineering decisions realistic, the lab is framed around an illustrative scenario: a mid-sized healthcare organization migrating its on-premises infrastructure to AWS. The scenario is fictional. The infrastructure, the incidents, and the fixes are real and were built and operated by one engineer.

---

## The Scenario and the Rules

The illustrative client is a mid-sized healthcare organization with a lean operations team modernizing off of on-premises infrastructure. That premise sets constraints that shaped every decision in the lab:

- **Managed services where possible.** A lean ops team cannot patch servers, manage clusters, or babysit infrastructure. Every service selection favored AWS-managed over self-managed.
- **No standing server access.** Healthcare compliance demands auditable, IAM-controlled access. No SSH, no bastion hosts, no key pairs. All access via SSM Session Manager.
- **Infrastructure as code, always.** Every resource defined in Terraform. Nothing clicked together in the console. Infrastructure is reproducible, version-controlled, and destroyable in minutes.
- **Zero-downtime deployments.** Patient-facing systems cannot tolerate maintenance windows. Deployments use blue/green patterns with instant rollback.
- **Full observability.** Every service monitored, every incident documented with a post-mortem, runbooks maintained for on-call response.
- **Automation first.** Manual operation is the enemy. Scripts, pipelines, and SSM documents replace repetitive human work.

---

## Environment

- **OS:** Windows with WSL2 (Ubuntu) in VS Code
- **Linux hands-on:** CentOS Stream 10 VM in VMware
- **Cloud:** AWS (us-east-1), iamadmin with AdministratorAccess
- **IaC:** Terraform v1.14.8, remote state in S3 with DynamoDB locking
- **Source control:** GitHub

## Repo Structure

```
IaC-AWS-Lab/
├── README.md
├── PROGRESS.md                  # Week-by-week progress tracker
├── scripts/                     # Shared bash scripts built in Month 1
│   ├── sre-snapshot.sh          # Full system state capture
│   ├── sre-healthcheck.sh       # 5-layer pass/fail health report
│   ├── sre-watchdog.sh          # Auto-restart with logging and retries
│   ├── sre-logdig.sh            # Multi-source log search with time filter
│   └── tf-check.sh              # Runs terraform fmt, validate, then apply
├── references/
│   ├── sre-command-runbook.md   # Command reference built during the lab
│   └── sre-triage-playbook.md   # Incident triage playbook
├── month-1-sre-foundations/     # Linux, Bash, Networking, Git, IAM
├── month-2-aws-infra/           # VPC, EC2, SSM, CloudWatch (original build)
├── month-3-iac/                 # Terraform remote state, modules, workspaces
├── month-4-compute/             # EC2 deep dive, Docker, ECS, blue/green
├── month-5-observability/       # CloudWatch, structured logging, SLOs
├── month-6-chaos/               # Incident response, chaos engineering, DR
├── month-7-security/            # GuardDuty, Config, Security Hub, FinOps
└── month-8-capstone/            # Production-grade system, full IaC, CI/CD
```

---

## Month Summaries

### Month 1: SRE Foundations
Established the operational toolkit before touching AWS. Linux internals (processes, signals, cgroups, systemd), production-grade Bash scripting, networking fundamentals (TCP/IP, DNS, TLS, HTTP), Git workflows, AWS CLI, and IAM fundamentals.

Built the scripts used throughout the lab: `sre-snapshot.sh` (full state capture before any change), `sre-healthcheck.sh` (5-layer pass/fail report), `sre-watchdog.sh` (auto-restart with retries), `sre-logdig.sh` (multi-source log search), and `tf-check.sh` (fmt, validate, apply, with no auto-approve).

### Month 2: AWS Infrastructure
Built the first AWS footprint: a production-style VPC with public and private subnets, NAT Gateway, and an EC2 app server running nginx in a private subnet. SSM Session Manager replaced SSH entirely, so no bastion and no key pairs, with a full audit trail.

Added CloudWatch alarms, SNS alerting, log shipping, and an operational dashboard. Ran early chaos testing to trigger CPU alarms and wrote a full post-mortem documenting root cause and corrective actions.

### Month 3: Infrastructure as Code
Refactored Month 2's flat Terraform into a production-grade IaC foundation: remote state in S3, DynamoDB state locking, reusable modules, workspace-aware environments, and a six-tag tagging strategy enabling fleet-wide SSM targeting.

Built a custom SSM Document, `SRELab-HealthCheck`, that runs a multi-step health check across the fleet simultaneously, replacing manual SSH-based checks.

### Month 4: Compute, Containers, and Deployment
Migrated the compute layer from EC2 to containers, evolving through three patterns:

- **EC2 + ASG + ALB:** Launch Template, Auto Scaling Group, Application Load Balancer. A self-healing fleet behind a load balancer.
- **ECS Fargate:** Containerized the app with Docker, pushed to ECR, deployed on Fargate. No EC2 instances to manage.
- **Blue/green via CodeDeploy:** Two target groups, two ALB listeners, all-at-once traffic shift with automatic rollback on failure.

Chose Fargate specifically because the scenario's ops team cannot manage underlying EC2 instances at scale.

### Month 5: Observability
Instrumented the ECS Fargate stack with production-grade observability, chosen to run natively in CloudWatch so the small ops team has no separate observability platform to operate or secure:

- **Structured logging:** JSON-formatted nginx logs with CloudWatch metric filters, queryable by field through Logs Insights rather than grep.
- **On-call dashboard:** A single CloudWatch dashboard showing the metrics that matter during an incident: request rate, error rate, latency, task health, and target group status.
- **SLIs, SLOs, and error budgets:** Defined indicators and objectives for the patient-facing service (99.9% availability target) and translated them into error budgets and burn-rate alarms that make the reliability versus velocity tradeoff concrete.
- **Synthetic monitoring:** A CloudWatch Canary runs a scripted check against the ALB endpoint every minute, catching failures before real users report them.

### Month 6: Incident Management and Chaos Engineering
Built a complete incident-management practice from the ground up:

- **Incident response playbook and runbook suite:** Step-by-step runbooks for known failure modes (task crashes, ALB health-check failures, deployment rollbacks), written to be executable under pressure. A `triage.sh` entry point plus alarm-specific investigate scripts run the first minutes of response.
- **Chaos engineering without FIS:** AWS Fault Injection Simulator proved ineffective against Fargate, because the service self-heals faster than a scenario can observe the failure. The technique that worked instead was a deliberately broken nginx image that passes ALB health checks but returns 500 to real traffic, producing a realistic partial outage that monitoring and runbooks had to catch.
- **On-call simulation:** Ran full incident simulations against a live broken system with a runbook and a timer, building triage muscle memory before a real outage would demand it.
- **Backup and DR testing:** Verified the infrastructure could be rebuilt from Terraform state in minutes, and documented recovery objectives.

The philosophy: chaos engineering is not breaking things for sport. It is finding failure modes in a controlled environment so they are not found in production during a critical moment.

### Month 7: Security, Networking, and Cost
**Security:**
- **GuardDuty, Security Hub, and AWS Config:** Continuous threat detection, security posture scoring, and configuration-drift evaluation across the account, with findings triaged as part of the operational workflow.
- **VPC Flow Logs:** Network traffic logged at the VPC level, with REJECT metric filters and alarms for detecting unexpected traffic patterns.
- **Secrets Manager and Parameter Store:** Credentials and certificates stored and rotated automatically. Non-sensitive config versioned centrally and delivered to tasks via IAM, never hardcoded into images or committed to state.

**Cost:**
- **Cost Explorer and Budgets:** Spend tracked by service and tag, with budget alerts that fire before overspend, not after the invoice.
- **Rightsizing:** Fargate task CPU and memory reviewed against actual utilization, since over-allocated tasks are direct waste under per-vCPU pricing.

Native AWS security services were chosen because the scenario's team cannot operate or license a separate security stack.

### Month 8: Capstone
Everything from the prior seven months assembled into a single production-grade system, reproducible from one `terraform apply`:

- **The stack:** A load-balanced ECS Fargate application behind an ALB, deployed blue/green through CodeDeploy, with images in ECR, all defined in Terraform with remote state.
- **CI/CD pipeline:** GitHub Actions builds the Docker image on every push to main, tags it with the commit SHA, pushes to ECR, and triggers a CodeDeploy blue/green deployment automatically.
- **Full observability:** Structured logging, CloudWatch dashboards, SLO burn-rate alarms, and synthetic monitoring, so one dashboard tells the on-call engineer what they need.
- **Chaos engineering:** Two controlled chaos scenarios run against the live system. A pipeline-path failure caught by the deployment smoke test, and a manual bad-image push that exposed a gap between the CodeDeploy and ALB health checks. The second produced a real post-mortem and a corrective change to the CodeDeploy termination wait time.
- **Post-mortem and portfolio:** Each incident triaged with the runbooks, resolved, and documented with root cause analysis. A written SRE portfolio summarizes the system, the decisions, the incidents, and the lessons.

The capstone is evidence that this infrastructure can be built, operated, broken, fixed, and handed off by one engineer, with documented process, in a way that scales.

---

## Key Decisions and Lessons Learned

**SSM over SSH.** No bastion, no key pairs. SSM Session Manager provides auditable, IAM-controlled shell access, required for the scenario's compliance posture.

**Fargate over EC2.** A lean ops team cannot absorb EC2 patching, capacity planning, and AMI management for the container workload.

**Blue/green over rolling.** Rolling deployments create a window where old and new versions serve traffic at once. For patient-facing systems that is unacceptable, so blue/green shifts all traffic at once with instant rollback.

**Remote state from day one.** S3 backend with DynamoDB locking prevents state corruption and makes infrastructure recoverable from any machine.

**Destroy nightly, rebuild daily.** NAT Gateways and load balancers cost money. IaC makes rebuilding trivial, so non-production infrastructure is destroyed overnight and rebuilt each morning in minutes.

**Broken-image chaos over FIS.** FIS was the planned chaos tool but proved ineffective against Fargate's fast self-healing. A deliberately broken nginx image that passes health checks while failing real traffic produced far more realistic incidents, and exposed a genuine CodeDeploy versus ALB health-check gap that a synthetic fault would have missed.

**CloudWatch dimensions bug (early build).** Alarms were created but never evaluated. Root cause: the dimensions block referenced resource tags instead of the instance ID, so the alarm was never pointed at an actual resource. Fixed by correcting the dimensions to reference the EC2 instance ID directly. A good early lesson that an alarm that exists is not the same as an alarm that works.
