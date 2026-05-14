# SRE Lite Lab — Progress Tracker

## Environment
- OS: Windows with WSL (Ubuntu) in VS Code
- AWS Account: iamadmin user with admin access
- Region: us-east-1
- Terraform: v1.14.8
- GitHub: https://github.com/darrelldhale/sre-lite-lab

---

## Month 1 — SRE Foundations

### Week 1 — Linux Internals
- [x] Processes, PIDs, parent/child relationships
- [x] Signals and how the kernel communicates with processes
- [x] File descriptors and why everything is a file
- [x] systemd: units, targets, journald
- [x] cgroups: resource limits and container foundations

### Week 2 — Bash Scripting
- [x] Variables, conditionals, loops, functions
- [x] Error handling: set -euo pipefail, exit codes, || true
- [x] Argument validation: $#, $1, $2, default values
- [x] Arrays and for loops
- [x] Built sre-snapshot.sh — full system state capture
- [x] Built sre-healthcheck.sh — 5-layer pass/fail health report
- [x] Built sre-watchdog.sh — auto-restart with logging and max retries
- [x] Built sre-logdig.sh — multi-source log search with time filtering

### Week 3 — Networking Fundamentals
- [x] TCP/IP: how packets actually move
- [x] DNS: resolution from stub to root
- [x] HTTP: requests, responses, status codes
- [x] TLS: handshake, certificates, trust chains
- [x] Debugging tools: curl, dig, netstat, tcpdump

### Week 4 — Git Workflows + AWS CLI + IAM
- [x] Git branching: checkout -b, merge, fast-forward vs merge commit
- [x] Branch cleanup and push workflow
- [x] AWS CLI output formats: json, table, text
- [x] JMESPath filtering with --query
- [x] IAM users, groups, policies, roles
- [x] AdministratorAccess policy — what it means
- [x] Service-linked roles — what they are and where they come from
- [x] Least privilege principle

---

## Month 2 — AWS Infrastructure

### Week 1
- Configured AWS CLI and Terraform in WSL
- Created GitHub repo and pushed initial structure

### Week 2
- Built VPC, public/private subnets, IGW, NAT Gateway, route tables
- Built App Server (EC2) in private subnet with nginx via user_data
- Dropped Bastion in favor of SSM Session Manager for access
- Verified nginx serving HTTP 200 via SSM session
- Learned: agent forwarding, SSM vs SSH, .gitignore discipline

### Week 3
- Created SNS topic and email subscription for alerts
- Built CloudWatch CPU alarm (triggers >80% for 4 minutes)
- Built CloudWatch log group and nginx 4xx metric filter
- Built CloudWatch dashboard with CPU and error widgets
- Installed and configured CloudWatch agent on App Server via SSM
- Verified nginx logs shipping to CloudWatch log group
- Learned: data sources, IAM policy attachments, CloudWatch agent config

### Week 4
- Installed stress tooling on App Server via SSM
- Diagnosed and fixed misconfigured CloudWatch alarm dimensions
- Successfully triggered CPU alarm above 80% threshold
- Received ALARM and OK email notifications via SNS
- Wrote runbook for high CPU incident response
- Wrote post-mortem documenting root cause and lessons learned
- Learned: chaos engineering, CPU burst credits, alarm dimensions, incident documentation

---

## Month 3 — Infrastructure as Code
Week 1 — Remote state + rebuild infra
Week 2 — Terraform modules + workspaces
Week 3 — CloudFormation
Week 4 — SSM at scale + Tagging strategies

### Week 1 — Remote State + Infrastructure Rebuild
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

### Week 2 — Terraform Modules + Workspaces
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

### Week 3 — CloudFormation
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

### Week 4 — SSM at Scale + Tagging Strategies
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
  [x] Enhanced SRELab-HealthCheck SSM document — added TOP CPU CONSUMERS step (ps aux sorted by CPU)

---

## Month 4 — Compute, Containers & Deployment
- EC2 deep dive: launch templates, AMIs, Auto Scaling Groups
- Docker fundamentals and ECS Fargate
- Blue/Green and canary deployment patterns
- Introduction to EKS

### Week 1 — EC2 Deep Dive: AMI, Launch Template, ASG
- [x] Destroyed Month 3 week-2 stack — AMI survived independently
- [x] Installed SRE toolkit on existing instance: htop, jq, net-tools, tcpdump, git, stress
- [x] Baked custom AMI: sre-lab-base-ami-v1 (ami-06e35715bc33b8177)
- [x] Built self-contained Month 4 Terraform root with networking and compute modules
- [x] Refactored networking module to use consistent variable naming and aws_region data source
- [x] Built compute module: Security Groups, IAM Role, Launch Template, ALB, Target Group, Listener, ASG
- [x] Deployed 25 resources in single terraform apply
- [x] Verified nginx serving HTTP 200 via ALB DNS in browser
- [x] Verified both ASG instances healthy in target group
- [x] Verified SSM access into private instance — no public IP, no SSH


### Week 2 — Docker Fundamentals
- [x] Verified Docker installation in WSL
- [x] Pulled and ran hello-world image — understood local cache behavior
- [x] Built custom nginx image with two-line Dockerfile: sre-lab-nginx:v1
- [x] Ran container with port mapping, verified custom HTML in browser and curl
- [x] Exec'd into running container — explored ps aux, hostname, filesystem
- [x] Inspected container logs — identified curl vs browser requests
- [x] Inspected image layers with docker history — understood layer caching
- [x] Built sre-lab-nginx:v2 — observed base layer cache reuse
- [x] Simulated rollback — understood image tags as deployment artifacts
- [x] Demonstrated volume mounts — live file changes without rebuild
- [x] Learned: images vs containers, Dockerfile, layer caching, volumes, docker exec, rmi
- [x] Learned: Docker vs ECS vs EKS — packaging vs orchestration vs scale


### Week 3 — ECS Fargate
- [x] Built self-contained Week 3 Terraform root — networking module reused, compute module rebuilt for ECS
- [x] Created ECR repository with scan on push enabled
- [x] Built ECS compute module: Security Groups, IAM execution and task roles, ECS Exec policy
- [x] Built ALB, Target Group (target_type=ip), and Listener for Fargate
- [x] Built CloudWatch Log Group for container logs with 7 day retention
- [x] Built ECS Cluster with Container Insights enabled
- [x] Built ECS Task Definition — Fargate launch type, awsvpc network mode
- [x] Built ECS Service — desired count 2, rolling deployment, ECS Exec enabled
- [x] Authenticated Docker to ECR and pushed custom nginx image
- [x] Deployed custom image to Fargate — two healthy tasks across two AZs
- [x] Performed rolling deployment — observed task drain/register cycle live
- [x] Verified runningCount == desiredCount as primary health indicator
- [x] Learned: ECR, ECS cluster, task definition, ECS service, task vs execution role
- [x] Learned: target_type=ip for Fargate, rolling deployments, task definition revisions

In summary, here is what I accomplished this week:

-Created a custom HTML page and wrote a Dockerfile to package it with nginx
-Built a Docker image from the Dockerfile — containerized the app
-Tagged the image — once for local use, once with the ECR URL for pushing
-Pushed the image to ECR — AWS's private container registry
-Deployed via Terraform — ECS pulled the image from ECR and ran it as Fargate tasks
-Verified via ALB DNS — traffic flowing through the load balancer to the containers

### Week 4 — Blue/Green Deployments
- [x] Built Week 4 Terraform root — networking reused, compute module rebuilt for blue/green
- [x] Added second ALB target group (green) alongside existing blue target group
- [x] Added test listener on port 8080 — allows testing green before traffic shift
- [x] Changed ECS service deployment controller from ECS to CODE_DEPLOY
- [x] Added lifecycle ignore_changes on ECS service — prevents Terraform fighting CodeDeploy
- [x] Built CodeDeploy IAM role with AWSCodeDeployRoleForECS policy
- [x] Built CodeDeploy application and deployment group
- [x] Configured CodeDeployDefault.ECSAllAtOnce — 100% traffic shift, no gradual rollout
- [x] Configured auto rollback on deployment failure
- [x] Built and pushed v4 image to ECR
- [x] Triggered blue/green deployment via aws deploy create-deployment
- [x] Verified v4 on port 8080 (green) before traffic shift completed
- [x] Verified port 80 serving v4 after traffic shift — zero inconsistency window
- [x] Read deployment logs — confirmed all-at-once swap vs rolling drain pattern
- [x] Learned: blue/green vs rolling, CodeDeploy application/deployment group, deployment controller types, lifecycle ignore_changes


---

## Month 5 — Observability
- CloudWatch the right way: structured logging
- Real on-call dashboard
- SLIs, SLOs, error budgets
- Synthetic monitoring and canaries

### Week 1 — Structured Logging + Metric Filters
- [x] Switched nginx from plain-text to JSON structured logging via custom nginx.conf
- [x] Built and pushed v5 image with JSON logging baked in
- [x] Created month-5-observability/week-1 as self-contained Terraform root
- [x] Built observability module: metric filters and CloudWatch alarm
- [x] Metric filter: Http5xxCount — counts every 5xx response from JSON status field
- [x] Metric filter: Http4xxCount — counts every 4xx response from JSON status field
- [x] Metric filter: HttpRequestCount — counts every request regardless of status
- [x] CloudWatch alarm: sre-lab-dev-http-5xx-too-high — fires above 5 errors in 60 seconds
- [x] Added ecs_log_group_name output to compute module — feeds into observability module
- [x] Deployed v5 via CodeDeploy blue/green — Northwind Health Group Patient Portal
- [x] Verified JSON logs arriving in CloudWatch Logs Insights
- [x] Verified metric filters producing data points in SRELab/Nginx namespace
- [x] Learned: structured logging, metric filters, Logs Insights queries, log-to-metric pipeline

### Week 2 — Alarms, SNS, and On-Call Dashboard
- [x] Built SNS topic: sre-lab-dev-alerts — central notification channel for all alarms
- [x] Added email subscription and confirmed — alarm notifications delivered to on-call email
- [x] Wired alarm_actions and ok_actions to SNS topic on all alarms
- [x] Built CloudWatch alarm: sre-lab-dev-ecs-cpu-too-high — fires above 80% CPU for 2 minutes
- [x] Built CloudWatch alarm: sre-lab-dev-ecs-memory-too-high — fires above 80% memory for 2 minutes
- [x] Built CloudWatch dashboard: sre-lab-dev-dashboard — Northwind on-call view
- [x] Dashboard row 1: alarm status panel — all three alarms green/red at a glance
- [x] Dashboard row 2: request rate, 4xx errors, 5xx errors — HTTP health
- [x] Dashboard row 3: ECS CPU and memory utilization — container resource health
- [x] Deployed v6 via CodeDeploy blue/green — verified dashboard reflects live traffic
- [x] Discovered internet scanner activity in 4xx logs — PHP webshell probes, .git/config theft attempts, .env secrets hunting
- [x] Learned: SNS topics and subscriptions, alarm actions, CloudWatch dashboard JSON, scanner noise vs real errors


### Week 3 — SLIs, SLOs, and Error Budgets
- [ ] Defined Northwind SLO: 99.5% success rate over 30-day rolling window
- [ ] Wrote SLO definitions doc: references/slo-definitions.md
- [ ] Added Row 4 to on-call dashboard — SLI success rate, burn rate, SLO reference card
- [ ] SLI widget uses metric math: (total - 5xx) / total * 100 with 99.5% annotation line
- [ ] Burn rate widget: (5xx rate) / 0.005 with fast/slow burn threshold annotations
- [ ] Added burn rate alarm using metric_query blocks — fires when burn rate exceeds 14.4x
- [ ] Learned: SLIs, SLOs, error budgets, burn rate math, metric math alarms vs single-metric alarms, (known after apply) in Terraform plan diffs


### Week 4 — Synthetic Monitoring and Canaries
- [x] Introduced terraform.tfvars — separated environment values from variable definitions
- [x] Added terraform.tfvars.example as committed reference — real values gitignored
- [x] Added archive provider to root — zips canary script at plan time
- [x] Created canary.js.tftpl — Node.js script that hits ALB and verifies 200 response
- [x] Built S3 bucket for canary artifacts — screenshots and logs stored after every run
- [x] Built IAM role and policy for canary — S3 write, CloudWatch metrics, log access
- [x] Deployed CloudWatch Synthetics canary — runs every minute, start_canary = true
- [x] Added canary failed alarm — fires on 2 consecutive failures, treat_missing_data = breaching
- [x] Added canary alarm to dashboard Row 1 — all 5 alarms visible in one panel
- [x] Learned: synthetic vs reactive monitoring, templatefile, archive provider, path.module, zip_file path vs filebase64, terraform import for state drift, terraform.tfvars pattern
---

## Month 6 — Incident Management & Chaos Engineering
- Full incident response playbook
- AWS Fault Injection Simulator (FIS)
- Runnable runbooks
- On-call simulation exercises
- Backup/restore and DR testing

### Week 1 — Incident Response Playbook
- [x] Created month-6-incident-chaos-engineering/week-1 — copied Week 4 infra files as baseline
- [x] Cut month-6-week-1 branch
- [x] Built references/incident-response-playbook.md — full Northwind playbook
- [x] Defined P1/P2/P3/P4 severity levels mapped to all 5 CloudWatch alarms
- [x] Defined 5-phase incident lifecycle: Detect, Declare, Respond, Resolve, Review
- [x] Defined IC, Technical Lead, and Communications Lead roles with severity matrix
- [x] Wrote alarm-specific first-response checklists for all 5 alarms
- [x] Wrote communication templates: initial notification, status update, resolution
- [x] Learned: playbook vs runbook distinction, severity classification, incident lifecycle

### Week 2 — AWS Fault Injection Simulator (FIS)
### Week 3 — Runnable Runbooks
### Week 4 — On-call Simulation, Backup/Restore + DR Testing

---

## Month 7 — Security, Networking & Cost
- AWS Security Hub, GuardDuty, Config
- VPC Flow Logs
- Secrets Manager and Parameter Store
- FinOps: Cost Explorer, Budgets, rightsizing

---

## Month 8 — Capstone
- Multi-tier, highly available production-grade system
- Full IaC, observability, CI/CD pipeline
- Chaos engineering with own runbooks
- Post-mortem
- SRE portfolio document
- Python
