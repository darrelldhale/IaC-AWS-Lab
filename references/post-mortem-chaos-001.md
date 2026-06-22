# Post-Mortem: Chaos Deployment - Bad Image Slips Past Health Checks
**Date:** 2026-05-20
**Severity:** P1 — 100% of production traffic serving HTTP 500
**Duration:** ~10 minutes (deployment complete to rollback complete)
**Author:** Darrell Hale
**Status:** Resolved

---

## Summary

A deliberately broken nginx image was manually pushed to ECR and deployed via CodeDeploy as a controlled chaos engineering exercise. The image was designed to return HTTP 500 on all real traffic while returning 200 on the `/health` path. Contrary to expectations, CodeDeploy completed the deployment successfully, shifting 100% of traffic to the bad image before the ALB health checks had time to mark the tasks as unhealthy. Alert emails began firing immediately. The service was recovered via CodeDeploy rollback.

A secondary finding emerged earlier in the exercise: a pipeline-path attempt to deploy the same bad image was **caught by the smoke test** and stopped before anything reached ECR or production.

---

## Timeline

| Time (UTC) | Event |
|---|---|
| T+00:00 | Chaos image (`sre-lab-nginx:chaos`) built locally and pushed to ECR manually, bypassing the pipeline |
| T+01:00 | Task definition revision `:32` registered pointing to chaos image |
| T+02:00 | `aws deploy create-deployment` fired — deployment `d-R5P2NMZJJ` started |
| T+03:30 | Step 1 complete — replacement task set deployed, tasks reporting RUNNING |
| T+04:00 | Step 2 complete — test traffic route setup succeeded |
| T+04:30 | Step 3 complete — 100% of production traffic shifted to chaos image |
| T+04:30 | HTTP 500 alert emails begin arriving — `sre-lab-dev-http-5xx-too-high` alarm firing |
| T+04:30 | Step 4 begins — 5-minute wait window before original task set termination |
| T+08:00 | Rollback initiated via CodeDeploy console — traffic shifted back to original task set |
| T+10:00 | All alarms returned to OK — service fully recovered |

---

## Root Cause

The chaos image returned HTTP 500 on `/` — the path used by the ALB target group health check. The expectation was that CodeDeploy would wait for green tasks to pass health checks before shifting traffic, and that the 500 responses would prevent this.

**What actually happened:**

CodeDeploy evaluates ECS task health (is the container running?) not ALB target group health (is the target passing HTTP health checks?) when deciding to proceed with the traffic shift. Because the nginx process started successfully inside the container, ECS reported the tasks as RUNNING. CodeDeploy interpreted RUNNING as healthy and proceeded through Steps 1–3, completing the full traffic shift before the ALB had accumulated enough failed health checks to mark the targets as unhealthy.

**The distinction that matters:**

| Health signal | What it checks | Who uses it |
|---|---|---|
| ECS task health | Is the container process running? | ECS service, CodeDeploy |
| ALB target health | Is the HTTP response in the expected range? | ALB routing |

These are independent systems. A container can be RUNNING and returning 500 — ECS calls it healthy, the ALB calls it unhealthy. CodeDeploy acted on the ECS signal, not the ALB signal.

---

## What Went Well

**The pipeline smoke test worked perfectly.**
The first attempt to deploy the bad image went through the GitHub Actions pipeline. The smoke test curled the container on `/`, received a 500, and stopped the pipeline before anything was pushed to ECR or deployed. The pipeline protected the production path exactly as designed.

**The observability stack detected the failure immediately.**
The moment 500s started flowing, the `sre-lab-dev-http-5xx-too-high` alarm fired and alert emails were delivered. Detection time was effectively zero — the alarm was already watching.

**The rollback window was available.**
CodeDeploy's Step 4 is a configurable wait period before the original task set is terminated. The original (blue) tasks were still alive and not serving traffic during this window. The "Stop and roll back deployment" button was available in the console, which would have instantly re-routed traffic back to the good tasks. This is the fastest possible recovery path for a bad blue/green deployment.

**The runbooks were ready.**
`dr-restore.sh` was run before chaos began, confirming baseline state. All three recovery paths (A, B, C) were documented and available.

---

## What Went Wrong

**The health check assumption was incorrect.**
The prediction was that ALB health checks would prevent CodeDeploy from shifting traffic to unhealthy tasks. This was wrong. CodeDeploy uses ECS task state, not ALB target health, as its deployment gate. This is a documented AWS behavior but was not accounted for in the chaos scenario design.

**No CodeDeploy alarm guardrail was wired.**
AWS CodeDeploy supports wiring CloudWatch alarms as deployment guardrails. If the `sre-lab-dev-http-5xx-too-high` alarm had been wired to the deployment group, CodeDeploy would have detected the alarm firing during the deployment window and triggered an automatic rollback. This gap means post-deployment application failures require manual intervention.

**ECR write access is not restricted to the pipeline.**
The `iamadmin` user was able to push a bad image directly to ECR, bypassing the pipeline and all its safety checks entirely. In a production environment, direct ECR push access should be restricted to the pipeline IAM user only. Human-triggered pushes should not be possible outside of a break-glass procedure.

---

## Action Items

| Item | Priority | Owner |
|---|---|---|
| Wire `sre-lab-dev-http-5xx-too-high` alarm to CodeDeploy deployment group as a guardrail | High | SRE |
| Restrict ECR push permissions — remove direct push from `iamadmin`, pipeline IAM user only | High | Security |
| Add ALB target group health check verification step to deployment runbook — confirm targets are healthy in both TGs after every deployment | Medium | SRE |
| Document the ECS task health vs ALB target health distinction in the incident response playbook | Medium | SRE |
| Shorten Step 4 wait time from 5 minutes to 2 minutes — the window is useful but 5 minutes extends incident duration unnecessarily | Low | SRE |

---

## Lessons Learned

**1. ECS RUNNING ≠ application healthy.**
A container process can start successfully and still serve nothing but errors. ECS has no visibility into what the application inside the container is actually doing. ALB health checks are the only signal that reflects real user-facing behavior. These must be treated as separate, independent health signals.

**2. CodeDeploy auto-rollback only protects against deployment failures, not application failures.**
If the deployment completes successfully (tasks running, traffic shifted) and the application then starts failing, no automated recovery fires. The on-call engineer owns recovery from that point. This is not a gap unique to this lab — it is a fundamental property of CodeDeploy's design.

**3. The pipeline is a safety net, not a guarantee.**
The smoke test caught the bad image when it came through the pipeline. It did not and cannot catch a bad image pushed directly to ECR. The pipeline protects one path. Any other path to production is unprotected. Access controls are the only protection for those paths.

**4. The Step 4 window is a recovery asset.**
During a blue/green deployment, the original task set remains alive until Step 4 completes. This is not dead time — it is a rollback window. An engineer who catches the problem during Step 4 can roll back instantly without a new deployment. Knowing this window exists and how long it lasts is operationally important.

**5. Chaos engineering surfaces real gaps.**
This exercise was designed to demonstrate a controlled auto-rollback. Instead it produced a real P1 incident with a finding that wasn't anticipated. That is exactly what chaos engineering is for — discovering failure modes before they are discovered by production traffic under uncontrolled conditions.

---

## References

- Incident runbook: `scripts/runbooks/investigate-5xx.sh`
- DR runbook: `scripts/runbooks/dr-restore.sh`
- Triage script: `scripts/runbooks/triage.sh`
- Deployment that caused incident: `d-R5P2NMZJJ`
- Bad image: `425924867120.dkr.ecr.us-east-1.amazonaws.com/sre-lab-dev-ecr-repo:chaos`
- Task definition revision (bad): `sre-lab-dev-ecs-task:32`
- Task definition revision (good): `sre-lab-dev-ecs-task:31`
