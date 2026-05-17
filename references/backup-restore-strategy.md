# Backup and Restore Strategy

**Northwind Health Group — Patient Portal**
**Last Updated:** 2026-05-17
**Owner:** Darrell Hale

---

## Overview

The Northwind patient portal is a stateless ECS Fargate application. There is no
database, no patient records stored in the application layer, and no persistent
volumes. Traditional data backup does not apply to this stack.

What requires protection are the **deployment artifacts** — the versioned components
needed to restore the service to a known-good state after a failure. These artifacts
already exist as a natural result of how the stack is built. This document makes
them explicit and defines the recovery procedure.

---

## What Is Backed Up

| Artifact                      | Location                                                    | Retention                              | What It Recovers                                          |
| ----------------------------- | ----------------------------------------------------------- | -------------------------------------- | --------------------------------------------------------- |
| Docker images                 | ECR — tagged by version (v1, v2 ... vN)                     | Until manually deleted                 | The running application at any prior version              |
| ECS task definition revisions | AWS ECS — versioned automatically                           | Until manually deregistered            | Container config, resource limits, IAM roles, log routing |
| Terraform state file          | S3 (`sre-lab-tfstate-425924867120`) with versioning enabled | S3 version history                     | Current infrastructure state                              |
| Terraform source code         | GitHub (`darrelldhale/sre-lite-lab`)                        | Git history                            | Full ability to rebuild infrastructure from zero          |
| Runbooks and playbook         | GitHub (`scripts/runbooks/`, `references/`)                 | Git history                            | Operational knowledge and recovery procedures             |
| Canary artifacts              | S3 (`sre-lab-dev-canary-results-425924867120`)              | 7 days (CloudWatch Synthetics default) | Historical pass/fail record for the synthetic monitor     |

---

## What Is NOT Backed Up

| Item               | Reason                                                                                          |
| ------------------ | ----------------------------------------------------------------------------------------------- |
| Patient records    | Not stored in the application layer — no database in this stack                                 |
| Application state  | The portal is stateless — no session data, no persistent storage                                |
| ALB access logs    | Not enabled in this lab — would require separate S3 bucket and log shipping configuration       |
| CloudWatch metrics | Retained per CloudWatch defaults (15 months for standard resolution) — not explicitly backed up |

---

## Recovery Chain

All recovery paths flow in one direction:

```
GitHub (source of truth)
  → Terraform (infrastructure)
    → ECR (container images)
      → CodeDeploy (deployment)
        → Running ECS service
```

A failure at any layer is recovered by going back one step up the chain.

---

## Recovery Scenarios

### Scenario 1 — Bad deployment (application returning errors)

**Symptoms:** 5xx alarm firing, canary failed, patients seeing errors
**Recovery path:** CodeDeploy or Terraform

1. Run `triage.sh` to confirm which alarm is firing
2. Run `investigate-5xx.sh` to identify whether a deployment caused the issue
3. If deployment is InProgress → `aws deploy stop-deployment --auto-rollback-enabled`
4. If deployment succeeded → check active task definition revisions:
   ```
   aws ecs list-task-definitions \
     --family-prefix sre-lab-dev-ecs-task \
     --status ACTIVE \
     --query 'taskDefinitionArns' \
     --output table
   ```
5. If a previous active revision exists → update `deployment.json` and redeploy via CodeDeploy
6. If only the bad revision is active → update `terraform.tfvars` to last known good image tag,
   run `terraform apply`, update `deployment.json`, redeploy via CodeDeploy

**Target recovery time:** Under 30 minutes

---

### Scenario 2 — Infrastructure failure (ECS cluster, ALB, networking)

**Symptoms:** Service unreachable, ECS tasks not starting, ALB returning no response
**Recovery path:** Terraform

1. Confirm the failure scope with AWS Console or CLI
2. Run `terraform plan` from the active week directory to see what drift exists
3. Run `terraform apply` to restore infrastructure to the declared state
4. Verify ECS tasks are running and ALB is healthy
5. Run `triage.sh` to confirm all alarms are OK

**Target recovery time:** Under 60 minutes

---

### Scenario 3 — Full rebuild from zero (region outage, accidental destroy)

**Symptoms:** All infrastructure gone, state file intact in S3
**Recovery path:** GitHub → Terraform → ECR → CodeDeploy

1. Clone the repo: `git clone https://github.com/darrelldhale/sre-lite-lab`
2. Navigate to the active week directory
3. Confirm S3 state bucket and DynamoDB lock table still exist (they survive most failures)
4. Run `terraform init` to connect to remote state
5. Run `terraform apply` to rebuild all infrastructure
6. Authenticate Docker to ECR and push the last known good image
7. Update `deployment.json` with the new task definition ARN
8. Trigger a CodeDeploy deployment

**Target recovery time:** Under 2 hours

---

### Scenario 4 — State file corruption or accidental state deletion

**Symptoms:** `terraform plan` fails, state file missing or corrupt
**Recovery path:** S3 version history

The S3 state bucket has versioning enabled. To restore a previous state file:

```bash
# List available versions of the state file
aws s3api list-object-versions \
  --bucket sre-lab-tfstate-425924867120 \
  --prefix month-6/week-4/terraform.tfstate \
  --query 'Versions[*].{VersionId:VersionId,LastModified:LastModified}' \
  --output table

# Restore a specific version
aws s3api get-object \
  --bucket sre-lab-tfstate-425924867120 \
  --key month-6/week-4/terraform.tfstate \
  --version-id <VERSION_ID> \
  terraform.tfstate.restored
```

**Target recovery time:** Under 30 minutes

---

## Key Decisions

**Why ECR image tagging matters:**
Images tagged only as `latest` make recovery harder — you cannot identify which
version was last known good without inspecting the image contents. Semantic version
tags (`v1`, `v2`, `vN`) make the recovery target unambiguous.

**Why Terraform is the source of truth:**
Task definition revisions managed by Terraform may be deregistered when new revisions
are applied. The recovery path for a bad deployment is always to update `terraform.tfvars`
and re-register the good image — not to rely on a previous task definition revision
being available in ECS.

**Why the state bucket uses versioning:**
Terraform state is the map of what exists in AWS. If it is lost or corrupted,
Terraform cannot safely manage infrastructure. S3 versioning provides a recovery
path without needing a separate backup process.
