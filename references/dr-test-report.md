# DR Test Report

**Northwind Health Group — Patient Portal**
**Test Date:** 2026-05-17
**Engineer:** Darrell Hale
**Scenario Tested:** Scenario 1 — Bad deployment (application returning errors)

---

## Test Objective

Verify that the Northwind on-call engineer can detect a bad deployment, work through
the recovery runbooks, and restore the patient portal to a known-good state within
the target recovery time of 30 minutes.

---

## What Was Tested

A deliberately broken image (v10) was deployed to the ECS Fargate service via
CodeDeploy. The image passed ELB health checks but returned HTTP 500 to all real
traffic, simulating a post-deployment application failure that automated rollback
cannot catch.

The engineer worked the incident from first alert through full recovery using only
the triage script, investigation runbook, and DR restore runbook — no AWS Console,
no prior knowledge of the specific failure.

---

## Test Results

| Step                 | Action                                                                | Result                                                                 |
| -------------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Detection            | `sre-lab-dev-http-5xx-too-high` alarm fired                           | Pass — alarm fired within 2 minutes of bad deployment going live       |
| Notification         | SNS email delivered to on-call engineer                               | Pass — email received promptly                                         |
| Triage               | `triage.sh` run — identified firing alarm                             | Pass — correct alarm identified, routed to investigate-5xx.sh          |
| Investigation        | `investigate-5xx.sh` run — confirmed 500s, identified deployment      | Pass — root cause confirmed within 2 minutes of starting investigation |
| Recovery attempt 1   | `stop-deployment` — deployment already completed                      | Failed — deployment window had closed                                  |
| Recovery attempt 2   | `aws ecs update-service` — rejected by CodeDeploy controller          | Failed — runbook gap identified                                        |
| Recovery attempt 3-5 | CodeDeploy deployment to previous revision — task definition inactive | Failed — Terraform had deregistered old revisions                      |
| Recovery (final)     | Updated `terraform.tfvars` to v9, applied, redeployed via CodeDeploy  | Pass — service restored to v9                                          |
| Verification         | `triage.sh` — all alarms OK, ALB returning 200                        | Pass                                                                   |

---

## Recovery Time

| Milestone                | Time (UTC) |
| ------------------------ | ---------- |
| Bad deployment triggered | 17:46      |
| Alarm fired              | 17:48      |
| Investigation began      | 17:50      |
| Root cause identified    | 17:52      |
| Recovery path found      | ~18:05     |
| Service restored         | ~18:15     |

**Total time from alarm to restoration: ~27 minutes**
**Target RTO: 30 minutes**
**Result: PASS — within target**

---

## What Slowed Recovery

Three failed recovery attempts added approximately 13 minutes to the incident.
Each attempt followed a path documented in the runbook that turned out to be
invalid for this stack configuration:

1. `stop-deployment` — valid only while deployment is InProgress
2. `aws ecs update-service` — invalid when CodeDeploy controls the deployment controller
3. CodeDeploy deployment to previous revision — blocked by deregistered task definitions

All three gaps have been corrected in `scripts/runbooks/investigate-5xx.sh`.

---

## RTO / RPO Assessment

**RTO (Recovery Time Objective): 30 minutes**
Achieved in 27 minutes including three failed recovery attempts. With the runbook
fixes applied, future recovery via Path C (Terraform re-register) should take
under 15 minutes from alarm to restoration.

**RPO (Recovery Point Objective): 0 data loss**
The patient portal is stateless. No patient data is stored in the application layer.
There is no data loss possible in an application-level failure of this stack.
RPO is not a meaningful constraint until a database is introduced in Month 8.

---

## Follow-Up Actions

- [x] Runbook gap fixed — `investigate-5xx.sh` updated with correct recovery paths
- [x] `dr-restore.sh` created — runnable recovery guide for Scenario 1
- [x] `backup-restore-strategy.md` written — documents full artifact chain and recovery scenarios
- [ ] Consider maintaining at least one previous ECR image tag as an explicit
      "last known good" reference in `terraform.tfvars.example`
