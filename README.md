# IaC-AWS-Lab

**A self-directed monitoring and incident-response lab. I built a production-grade AWS environment so I would have a real system to observe, alarm on, deliberately break, and run incidents against, then documented every failure and fix end to end.**

Built and operated by **Darrell Hale**, Lead Application Support Engineer focused on incident response, monitoring, and reliability. Culminated in the **AWS Certified CloudOps Engineer, Associate (SOA-C03)**.

Contact: look585carbon@gmail.com

> **Why this lab exists:** Monitoring and incident response are hard to practice without something real to monitor and break. Reading about golden signals or writing a runbook in the abstract teaches almost nothing. So I built the substrate first, a real load-balanced application running on AWS infrastructure defined entirely in Terraform, specifically so I would have a live system with real metrics, real logs, and real failure modes to work against. The infrastructure is the means. Observability and incident response are the point.

> **About the scenario:** This is a personal learning project, not client or employer work. To keep the engineering decisions realistic, it is framed around an illustrative fictional scenario: a mid-sized healthcare organization migrating off on-premises infrastructure with a lean operations team. That premise forces the constraints that make monitoring and on-call practice meaningful. The scenario is fictional. The infrastructure, the incidents, and the fixes are real and were built and operated by one engineer.

---

## What This Lab Is Really About

The center of gravity is the operational work, not the build:

- **Observability I can read under pressure.** A single on-call dashboard covering the golden signals, structured logs queryable by field, SLOs with error budgets and burn-rate alarms, and synthetic canaries that catch failures before users report them.
- **Incident response with real muscle memory.** An incident playbook, executable runbooks for known failure modes, a triage entry point that routes to alarm-specific investigation scripts, and timed on-call simulations against a live broken system.
- **Chaos engineering that produces real incidents.** Deliberately breaking the system in controlled ways to find failure modes before production does, then triaging and documenting each one with a post-mortem.
- **Detection-gap hunting.** Several of the most valuable findings were not the failures themselves but the fact that existing monitoring did not catch them. Closing those gaps is the actual work of a monitoring engineer.

The infrastructure underneath all of this (VPC, ECS Fargate, ALB, blue/green deploys, IaC, CI/CD) is built to production standard because monitoring a toy system teaches toy lessons. But it is the stage, not the play.

---

## The Substrate: What I Am Monitoring

A brief description of the system the observability and incident work runs against, so the rest makes sense:

A load-balanced application running on ECS Fargate behind an Application Load Balancer, deployed blue/green through CodeDeploy, with container images in ECR, all defined in Terraform with remote state in S3 and DynamoDB locking. Access is through SSM Session Manager, so no SSH, no bastion, and a full audit trail. A GitHub Actions pipeline builds, tags, pushes, and deploys on every merge to main. The whole environment stands up from one `terraform apply` and is destroyed and rebuilt daily to control cost.

That is the system under observation. Everything below is about watching it, breaking it, and responding when it breaks.

---

## Monitoring and Observability

Built to run natively in CloudWatch, chosen so the scenario's lean team has no separate observability platform to operate, secure, or license.

- **On-call dashboard.** One CloudWatch dashboard showing the signals that matter during an incident: request rate, error rate, latency, task health, and target-group status. Built in golden-signal reading order so a first responder knows where to look first.
- **Structured logging.** JSON-formatted nginx logs with CloudWatch metric filters, queryable by field through Logs Insights rather than grep. Filter on the failures that matter, then group and count to turn "something is failing" into "this specific thing is failing."
- **SLIs, SLOs, and error budgets.** Defined indicators and a 99.9 percent availability objective for the patient-facing service, translated into error budgets and burn-rate alarms that make the reliability-versus-velocity tradeoff concrete rather than theoretical.
- **Synthetic monitoring.** A CloudWatch Canary runs a scripted check against the ALB endpoint every minute, so failures on quiet paths surface from the absence of expected success, not from waiting for a user to complain.
- **Alarm configuration as a first-class decision.** Learned directly that an alarm that exists is not an alarm that works. An early build created alarms whose dimensions referenced resource tags instead of the instance ID, so they were never evaluated against a real resource. The fix taught the lesson that carried through the whole lab: verify the alarm actually fires before trusting it.

---

## Incident Response

A complete incident-management practice built from the ground up, then exercised repeatedly against live failures.

- **Incident playbook.** P1 to P4 severity definitions, a five-phase lifecycle (detect, declare, respond, resolve, review), role definitions, and communication templates.
- **Executable runbooks.** Step-by-step runbooks for known failure modes (task crashes, ALB health-check failures, deployment rollbacks), written to be run under pressure. A `triage.sh` entry point routes to alarm-specific investigate scripts that run the first minutes of response so diagnosis is not improvised.
- **On-call simulations.** Full incident drills against a live broken system with a runbook and a timer, building triage muscle memory before a real outage would demand it. One simulation recovered a zeroed-out service inside the RTO with the response worked end to end.
- **Post-mortems.** Every incident triaged with the runbooks, resolved, and documented with root-cause analysis and corrective actions, treating the review phase as where the real learning lives.

---

## Chaos Engineering

The philosophy: chaos engineering is not breaking things for sport. It is finding failure modes in a controlled environment so they are not discovered in production during a critical moment. The most useful chaos runs did not just confirm the system fails, they exposed where monitoring was blind.

- **Broken-image chaos over FIS.** AWS Fault Injection Simulator was the planned tool but proved ineffective against Fargate, which self-heals faster than a scenario can observe the failure. The technique that worked was a deliberately broken nginx image that passes ALB health checks (returns 200 to the health checker) while returning 500 to real traffic, producing a realistic partial outage that monitoring and runbooks had to catch.
- **A real detection gap, found and closed.** That broken-image run exposed a genuine gap between the CodeDeploy and ALB health checks, and drove a corrective change to the CodeDeploy termination wait time. A synthetic fault would have missed it entirely.
- **Log-based versus infrastructure-native alarms.** A service scaled to zero went undetected because the log-based alarms watching it went silent when nothing was running to produce logs. The fix was adding infrastructure-native alarms (RunningTaskCount and HealthyHostCount with treat-missing-data set to breaching) that publish from the infrastructure itself regardless of application state. This is the single most important alarm-configuration lesson in the lab.
- **Pipeline-path chaos.** A deliberately broken build caught by the deployment smoke test, verifying the pipeline fails safely before bad code reaches traffic.

---

## The Substrate Build, In Brief

The infrastructure exists to be monitored, so it is documented here as supporting context rather than the headline. It was built up over the first several months of the lab:

- **Foundations.** Linux internals, production Bash scripting, networking (TCP/IP, DNS, TLS, HTTP), Git, AWS CLI, and IAM. Built the operational scripts used throughout: full state capture, layered health checks, an auto-restart watchdog, multi-source log search, and a Terraform wrapper that runs fmt, validate, and apply with no auto-approve.
- **AWS infrastructure.** A production-style VPC with public and private subnets and a NAT gateway, with SSM Session Manager replacing SSH entirely.
- **Infrastructure as code.** Remote state in S3, DynamoDB locking, reusable modules, workspace-aware environments, and a tagging strategy enabling fleet-wide SSM targeting.
- **Compute and deployment.** Evolved from EC2 with an Auto Scaling Group and ALB, to containers on ECS Fargate, to blue/green deployments through CodeDeploy with automatic rollback. Fargate was chosen because the scenario's team cannot manage EC2 at scale.
- **Security and cost.** GuardDuty, Security Hub, and AWS Config for continuous detection and posture scoring; VPC Flow Logs with REJECT metric filters and alarms; Secrets Manager and Parameter Store for credentials and config; Cost Explorer, Budgets, and Fargate rightsizing to keep spend visible.
- **Capstone.** Everything assembled into one production-grade system, reproducible from a single `terraform apply`, with the full observability stack, CI/CD, and chaos scenarios described above running against it.

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

## Key Decisions and Lessons Learned

**Infrastructure-native alarms over log-based alarms for liveness.** Log-based alarms go blind when nothing is running to produce logs, which is exactly when you most need to know. Metrics that publish from the infrastructure itself catch a service scaled to zero when a log-based alarm never fires. This was the highest-value monitoring lesson in the lab.

**An alarm that exists is not an alarm that works.** An early alarm was never evaluated because its dimensions pointed at resource tags instead of the instance ID. Verifying that an alarm actually fires became a standing habit.

**Broken-image chaos over FIS.** FIS could not outrun Fargate's self-healing. A broken image that passes health checks while failing real traffic produced far more realistic incidents, and exposed a genuine CodeDeploy versus ALB health-check gap a synthetic fault would have missed.

**CloudWatch-native observability over a separate platform.** A lean team cannot operate, secure, or license a second observability stack. Leading with CloudWatch depth kept the whole practice inside one pane of glass.

**SSM over SSH.** No bastion, no key pairs. SSM Session Manager provides auditable, IAM-controlled access, required for the scenario's compliance posture.

**Fargate over EC2, blue/green over rolling.** A lean ops team cannot absorb EC2 patching at scale, and patient-facing systems cannot tolerate the mixed-version window a rolling deploy creates.

**Destroy nightly, rebuild daily.** NAT gateways and load balancers cost money. IaC makes rebuilding trivial, so non-production infrastructure is torn down overnight and rebuilt each morning in minutes.
