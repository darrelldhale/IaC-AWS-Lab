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

## 2026-05-21 (continued)
- SOA-C03 study plan committed — target exam 2026-06-25
- Track 1, 2, and 3 all open and defined
- Primary focus confirmed: troubleshooting and chaos engineering
- Next session: begin Route 53 study (Track 1) and/or HTTPS build (Track 3)

## 2026-06-15
- Morning check: all 6 alarms OK, canary 3/3 PASSED, VPC rejects 746
- Ran chaos scenario: ECS service scaled to 0 — simulated accidental scale-down
- Detected: 14:52 — canary first failure caught by synthetic monitoring
- Declared: 14:57 — triage complete, 4 min detection-to-declaration
- Recovered: 15:15 — desired count restored to 2, canary passing
- Total outage duration: 23 minutes
- Key finding: log-based alarms blind when compute layer disappears — canary
  was the only signal during a 100% outage
- Drafted initial and resolution merchant communications end to end
- Fixed investigate-canary.sh — curl now handles connection failures gracefully
- Fixed config.sh — ALB_DNS now dynamic, survives terraform destroy/apply
- Wrote post-mortem-chaos-002.md
