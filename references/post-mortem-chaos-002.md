# Post-Mortem: ECS service scaled to zero.

**Date:** 2026-06-15
**Severity:** P1 — 100% of production traffic serving HTTP 503
**Duration:** ~23 minutes
**Author:** Darrell Hale
**Status:** Resolved

---

## Summary

Our monitoring system detected that the patient portal at http://sre-lab-dev-app-load-balancer-2110554248.us-east-1.elb.amazonaws.com/ was returning HTTP 503 errors. The ECS service desired count was set to 0. This was a critical issue as it rendered the patient portal completely inaccessible, impacting all users.

---

## Timeline

14:52 — First canary failure
14:53 — Second failure confirmed, detection noted
14:57 — Triage complete, incident declared, engineering engaged
15:15 — Service restored, canary passing

---

## Root Cause

The ECS service desired count was set to 0. This was caused by a misconfiguration in the deployment process, where an incorrect value was applied to the ECS service configuration, leading to all tasks being stopped.

---

## What Went Well

**The observability stack detected the failure immediately.**
The moment 503s started flowing, the `investigate-canary` alarm fired and alert emails were delivered. Detection time was effectively zero — the alarm was already watching.

**The runbooks were ready.**
`triage.sh` and `investigate-canary.sh` were run after receiving the first alarm, confirming the issue.

---

## What Went Wrong

The 5xx alarm, burn rate alarm, and CPU/memory alarms all stayed OK while the platform was completely down. Log-based alarms can't fire when there are no tasks running to generate logs. The canary was the only thing that caught a 100% outage. Any monitoring strategy that relies solely on log-based alarms has a blind spot when the compute layer disappears entirely.

---

## Action Items

| Item                                                                      | Priority | Owner        |
| ------------------------------------------------------------------------- | -------- | ------------ |
| Update `investigate-canary.sh` to handle ECS task failures more robustly. | P1       | Darrell Hale |
| Add a CloudWatch alarm that fires when ECS running task count drops to 0  | P1       | Darrell Hale |

---
