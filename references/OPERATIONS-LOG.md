# Operations Log

# Operations Log

## 2026-05-20
- Started Track 2: Lab as a Living System
- Created morning-check.sh and added CANARY_NAME to config.sh
- Installed and authenticated GitHub CLI (gh)
- All 6 alarms: OK
- Canary: PASSING (3/3 last runs)
- VPC rejects: 10,698 (24h) — internet scanner noise, no new patterns, alarm OK
- GitHub Actions: 1 failed run at 00:45Z — intentional chaos test, smoke test caught
  bad image before ECR push, pipeline stopped correctly. Subsequent run at 00:55Z clean.
- Notes: morning-check.sh running cleanly, daily routine established

## 2026-05-21
- Morning check: all 6 alarms OK, canary 3/3 PASSED, VPC rejects 6,511 (scanner noise)
- Identified v9 running after spinup — root cause: terraform.tfvars still referenced v9
- Lesson: pipeline deploys and Terraform spinups are independent — tfvars is source of truth
- Week 1 rotation: bumped to v11, pushed via pipeline, deployed via CodeDeploy
- Pipeline: 28s clean run — build, smoke test, ECR push, task def, CodeDeploy all green
- Promoted v11 image to last-known-good in terraform.tfvars
- ALB DNS changed after spinup — new load balancer created by fresh terraform apply
- Certification track: targeting AWS Certified CloudOps Engineer – Associate (SOA-C03)
