# Northwind Health Group - Incident Response Playbook

**Organization:** Northwind Health Group
**System:** Patient Portal (ECS Fargate on AWS)
**Maintained by:** SRE / Application Support
**Last updated:** 2026-02-14

---

## Purpose

This playbook defines how Northwind Health Group responds to infrastructure and application incidents affecting the Patient Portal. It covers severity levels, roles, the incident lifecycle, alarm-specific response procedures, and communication templates.

Every on-call engineer is expected to have this document nearby before their shift.

---

## Section 1 - Severity Definitions

Severity is assigned the moment an incident is declared. It drives response speed, who gets notified, and whether patient-facing communication is required.

### P1 - Critical (Full Outage)

The Patient Portal is completely unavailable or the error budget will be exhausted within 5 days at the current failure rate.

**Response time:** Immediate. Wake people up.
**Who is paged:** On-call engineer + engineering lead
**Patient communication:** Required within 15 minutes

**Triggered by:**
- `sre-lab-dev-canary-failed` - synthetic monitor failed 2 consecutive checks;
portal is unreachable from outside the VPC
- `sre-lab-dev-slo-burn-rate-too-high` - burn rate exceeded 14.4x; at this rate the entire 30-day error budget is exhausted in 50 hours.

---

### P2 - High (Degraded Service)

The portal is reachable but patients are experiencing errors, or resource pressure makes a full outage imminent within minutes.

**Response time:** Within 15 minutes.
**Who is paged:** On-call engineer
**Patient communication:** Required if degredation exceeds 10 minutes

**Triggered by:**
- `sre-lab-dev-http-5xx-too-high` - more than 5 server errors in 60 seconds;
a subset of patient requests are failing
- `sre-lab-dev-ecs-cpu-too-high` - ECS task CPU above 80% for 2 consecutive minutes; sustained pressure causes request slowdowns and eventual task crashes
- `sre-lab-dev-ecs-memory-too-high` - ECS task memory above 80% for 2 consecutive minutes; memory exhaustion causes ECS to kill and restart tasks, visible to patients as 5xx errors

---

### P3 - Medium (Elevated Risk)

The system is functioning but showing warning signs. No immediate patient impact, but the situation requires investigation before the next check-in.

**Response time:** Within 2 hours during business hours.
**Who is paged:** Nobody. Added to the on-call log.
**Patient communication:** Not required

**Examples:**
- Burn rate between 6.0 and 14.4 (slow burn - budget gone within 5 days)
- 4xx error rate spiking above baseline (visible on dashboard, no alarm yet)
- Single canary failure that self-resolved before the second check

---

### P4 - Low (Informational)

No patient impact. Logged for trend awareness and post-incident review.

**Response time:** Next business day.
**Who is paged:** Nobody.
**Patient communication:** Not required

**Examples:**
- Scanner noise in 4xx logs (PHP probes, .env hunting — expected background
  activity on any public endpoint)
- Canary latency increase without a failure
- Brief CPU or memory spikes that return to baseline within one evaluation period

---

## Section 2 - Incident Lifecycle

Every incident at Northwind Health Group moves through five phases. Each phase has a clear entry point, owner, and exit condition.

### Phase 1 - Detect

**Entry:** An alarm fires and an SNS email is delivered to the on-call address, or a team member directly observes anomalous behavior.
**Owner:** Automated (CloudWatch + SNS)
**Exit:** A human has acknowledged the alert.

The detection layer for Northwind consists of:
- Six CloudWatch alarms wired to the `sre-lab-dev-alerts` SNS topic
- A synthetic canary running every 60 seconds hitting the ALB
- The on-call dashboard at `sre-lab-dev-dashboard` in CloudWatch

---

### Phase 2 - Declare

**Entry:** On-call engineer acknowledges the alert.
**Owner:** On-call engineer
**Exit:** Severity is assigned, incident is logged, and relevant parties are notified

Steps:
1. Open the dashboard and assess which alarms are firing
2. Assign a severity level using Section 1 of this playbook
3. Create an incident log entry (see Section 5 - Comunication Templates)
4. Notify stakeholders per the severity level
5. If P1: page the engineering lead immediately

Do not skip declaration. Even a five-minute P3 needs a log entry.

---

### Phase 3 - Respond

**Entry:** Incident is declared and severity is assigned.
**Owner:** On-call engineer (Technical Lead role)
**Exit:** Root cause is identified and a fix is in progess or applied.

Steps:
1. Open the runbook for the firing alarm (see Section 4 - Alarm Response Procedures)
2. Follow the runbook top to bottom - do not skip steps under pressure
3. Post a status update every 15 minutes for P1/P2 incidents
4. If the runbook does not resolve the issue within 30 minutes, escalate

---

### Phase 4 - Resolve

**Entry:** Fix is applied and system metrics return to normal.
**Owner:** On-call engineer
**Exit:** All alarms return to OK state, canary passes two consecutive checks, and a resolution message is sent to stakeholders.

Steps:
1. Confirm all six alarms are green on the dashboard
2. Confirm the canary has passed at least two consecutive 1-minute checks
3. Confirm the SLI success rate is at or above 99.5%
4. Send resolution notification using the template in Section 5
5. Record the resolution time in the incident log

---

### Phase 5 - Review

**Entry:** Incident is resolved
**Owner:** On-call engineer (due within 48 hours of resolution)
**Exit:** Post-mortem is written and action items are assigned.

For P1 and P2 incidents a post-mortem is mandatory. For P3 a brief incident log entry is sufficient. P4 requires no follow-up documentation.

The post-mortem template lives at: `references/post-mortem-xx-xx.md`

---

## Section 3 - Role Definitions

Northwind Health Group runs a lean on-call rotation. Role assignments scale with severity.

### Incident Commander (IC)

**Owns:** The incident from declaration to post-mortem.
**Does not:** Perform hands-on technical investigation during the an active incident.

Responsibilities:
- Declares the incident and assigns severity
- Assigns Technical Lead and Communications Lead
- makes escalation decisions
- Calls the incident resolved when exit conditions are met
- Ensures the post-mortem is written within 48 hours

**On P1:** Engineering lead fills this role.
**On P2/P3:** On-call engineer fills this role.

---

### Technical Lead (TL)

**Owns:** Investigation, diagnosis, and remediation.

Responsibilities:
- Opens and follows the relevant runbook
- Has sole hands-on access to AWS console and CLI during the incident
- Reports findings to the IC every 15 minutes on P1/P2
- Documents every action taken with a timestamp in the incident log
- Hands off a clear resolution summary to the IC when the fix is applied

**On P1/P2:** Dedicated engineer, seperate from the IC.
**On P3/P4:** On-call engineer covers this role alone.

---

### Communications Lead (CL)

**Owns:** All internal and external messaging during the incident.

Responsibilities:
- Sends the initial incident notification within 15 minutes of declaration (P1/P2)
- Posts status updates every 15 minutes for P1, every 30 minutes for P2
- Sends the resolution notification when the IC calls the incident resolved
- Uses the templates in Section 5 — do not write freeform messages during an incident

**On P1:** Dedicated team member, separate from the IC and TL.
**On P2:** IC doubles as CL.
**On P3/P4:** No external communication required.

---

### Role Assignment by Severity

| Severity | Incident Commander | Technical Lead | Communications Lead |
|---|---|---|---|
| P1 | Engineering Lead | On-call engineer | Designated team member |
| P2 | On-call engineer | On-call engineer | On-call engineer |
| P3 | On-call engineer | On-call engineer | Not required |
| P4 | On-call engineer | Not required | Not required |

---

## Section 4 - Alarm Response Procedures

Use this section the moment an alarm fires. Find the alarm name, read what it means, then follow the checklist in order. Do not skip steps.

---

### 4.1 - `sre-lab-dev-canary-failed` (P1)

**What it means:**
The synthetic canary has failed two consecutive one-minute checks. It hit the ALB from outside the VPC and did not receive a 200 response. From the patient's perspective, the portal is down.

**Most likely causes:**
1. ECS tasks have crashed and the service has no healthy targets
2. A bad deployment left containers in a crash loop
3. The ALB listener or target group is misconfigured
4. A networking change broke connectivity between the ALB and ECS tasks

**First-response checklist:**
- [ ] Open the dashboard - note which other alarms are also firing
- [ ] Check ECS service: is `runningCount` equal to `desiredCount`?
- [ ] Check ALB target group: are the targets healthy?
- [ ] Check for a recent deployment in CodeDeploy - did this start after a push?
- [ ] Check ECS task logs in CloudWatch - are containers crashing on startup?
- [ ] If a bad deployment is confirmed: initiate a CodeDeploy rollback
- [ ] If tasks are healthy but ALB is not routing: check listener rules and target group health check path

**Escalate if:**
Portal is still unreachable 15 minutes after response begins, or root cause cannot be identified from logs and dashboard.

---

### 4.2 - `sre-lab-dev-slo-burn-rate-too-high` (P1)

**What it means:**
The error budget is being consumed at more than 14.4 times the sustainable rate. At this pace, the entire 30-day error budget is exhausted in 50 hours. This alarm fires even when the portal is technically up - a high volume of 5xx errors can burn the budget without triggering a full outage alarm.

**Most likely causes:**
1. A spike in 5xx errors caused by a bad deployment or upstream dependency
2. ECS tasks under extreme resource pressure producing intermittent errors
3. A small number of endpoints consistently returning 500s
4. Scanner or bot traffic generating errors at high volume

**First-response checklist:**
- [ ] Open the dashboard - check the Burn Rate widget for current rate
- [ ] Check the 5xx Errors widget - is this a spike or sustained elevation?
- [ ] Check the SLI widget - how far below 99.5% has the success rate dropped?
- [ ] Cross-reference with the 4xx widget - is this error traffic or legitimate patient requests failing?
- [ ] Check ECS CPU and memory - is resource pressure driving the errors?
- [ ] Check CloudWatch Logs Insights for the specific endpoints returning 5xx
- [ ] If burn rate is above 14.4 but canary is passing: portal is up but degraded - treat as P2 until burn rate confirmed sustained
- [ ] If burn rate is above 14.4 and canary is failing: treat as dual P1, canary runbook takes priority

**Escalate if:**
Burn rate remains above 14.4 for more than 15 minutes with no identified cause.

---

### 4.3 - `sre-lab-dev-http-5xx-too-high` (P2)

**What it means:**
More than 5 server-side errors occurred within a single 60-second window.
Patients are receiving error responses, but the portal is still reachable.
This is a degraded service condition, not a full outage.

**Most likely causes:**
1. A bad deployment introduced a bug causing specific requests to fail
2. An upstrean dependency (database, API) is returning errors
3. ECS tasks under resource pressure are dropping requests
4. A specific endpoint is broken while the rest of the application functions

**First-response checklist:**
- [ ] Open the dashboard - check if CPU or memory alarms are also firing
- [ ] Check the burn rate widget - is the error budget being consumed rapidly?
- [ ] Check CloudWatch Logs Insights - which endpoints are returning 5xx?
- [ ] Check for a recent CodeDeploy deployment - did errors start after a push?
- [ ] Check ECS task count - are all desired tasks running?
- [ ] If a bad deployment is confirmed: initiate a CodeDeploy rollback
- [ ] If no deployment: check ECS task logs for application errors

**Escalate if:**
5xx errors continue for more than 15 minutes with no identified cause, or the burn rate crosses 14.4 - at that point this becomes a P1.

---

### 4.4 - `sre-lab-dev-ecs-cpu-too-high` (P2)

**What it means:**
Average CPU across all ECS tasks has exceeded 80% for two consecutive minutes. The containers are under sustained compute pressure. Left unaddressed, this causes request timeouts and eventual task crashes visible to patients as 5xx errors.

**Most likely causes:**
1. Unexpected traffic spike overwhelming the current task count
2. A runaway process inside a container consuming CPU abnormally
3. Task count is too low for current load - scaling is not keeping up
4. A recent deployment introduced a CPU-intensive code path

**First-response checklist:**
- [ ] Open the dashboard - check if 5xx or memory alarms are also firing
- [ ] Check ECS task count - is `runningCount` equal to `desiredCount`?
- [ ] Check request rate widget - is traffic higher than normal baseline?
- [ ] Check for a recent deployment - did CPU spike after a push?
- [ ] Check ECS task logs - is any single request type consuming excessive time?
- [ ] If traffic spike: consider manually increasing ECS desired task count
- [ ] If runaway process: identify the task and force a task replacement

**Escalate if:**
CPU remains above 80% for more than 15 minutes, or 5xx errors begin appearing alongside the CPU pressure.

---

### 4.5 - `sre-lab-dev-ecs-memory-too-high` (P2)

**What is means:**
Average memory across all ECS tasks has exceeded 80% for two consecutive minutes. When a container exhausts its memory limit, ECS kills and restarts it. During that restart window, the task is pulled from the ALB  target group and patients receive 5xx errors.

**Most likely causes:**
1. A memory leak indroduced by a recent deployment
2. Traffic volume exceeding what the current task memory allocation can handle
3. Task memory limit set too low for the application's normal footprint
4. A specific request type holding large payloads in memory

**First-response checklist:**
- [ ] Open the dashboard - check if CPU or 5xx alarms are also firing
- [ ] Check ECS task count - are any tasks being stopped and restarted?
- [ ] Check ECS task logs - are there out-of-memory errors in the logs?
- [ ] Check for a recent deployment - did memory climb after a push?
- [ ] Check request rate - is traffic volume higher than normal?
- [ ] If memory leak suspected: initiate a CodeDeploy rollback to previous image
- [ ] If task limit too low: note for post-incident - task definition update required.

**Escalate if:**
Tasks begin restarting and 5xx errors appear, or memory remains above 80% for more than 15 minutes with no identified cause.

---

## Section 5 — Communication Templates

Use these templates exactly as written. Fill in the bracketed fields only.
Do not rewrite or improvise during an active incident.

---

### Initial Incident Notification

Use this template when declaring a P1 or P2 incident. Send within 15 minutes
of declaration.

---

**Subject:** [P1/P2] Northwind Patient Portal — Incident Declared

**Body:**

Incident declared at [TIME] UTC.

**Severity:** [P1 / P2]
**Status:** Investigating
**Impact:** [One sentence — what patients are experiencing right now]

Our on-call engineer is actively investigating. The next update will be sent
in 15 minutes.

**Incident Commander:** [Name]
**Technical Lead:** [Name]

---

### Status Update (every 15 min for P1, every 30 min for P2)

---

**Subject:** [P1/P2] Northwind Patient Portal — Incident Update [HH:MM UTC]

**Body:**

Update as of [TIME] UTC.

**Severity:** [P1 / P2]
**Status:** [Investigating / Root cause identified / Fix in progress]
**Current findings:** [One or two sentences — what has been confirmed so far]
**Next update:** [TIME] UTC

---

### Resolution Notification

Send only when all exit conditions are met: all alarms green, canary passing
two consecutive checks, SLI at or above 99.5%.

---

**Subject:** [RESOLVED] Northwind Patient Portal — Incident Closed [HH:MM UTC]

**Body:**

Incident resolved at [TIME] UTC.

**Duration:** [Start time] UTC to [End time] UTC
**Root cause:** [One sentence — what caused the incident]
**Resolution:** [One sentence — what was done to fix it]
**Follow-up:** A post-mortem will be completed within 48 hours.

The Patient Portal is fully operational. All alarms have returned to OK state.

**Incident Commander:** [Name]

---

## Quick Reference — Severity at a Glance

30 days = 720 hours of error budget

Burn rate simply means: how many times faster than "sustainable" are you burning through it?

Burn rate of 1x = you'll exhaust the budget in exactly 720 hours (right on pace)
Burn rate of 14.4x = 720 / 14.4 = 50 hours
Burn rate of 720x = 720 / 720 = 1 hour

| Alarm | Severity | Page Who | Comms Required |
|---|---|---|---|
| `canary-failed` | P1 | On-call + Eng Lead | Yes — within 15 min |
| `slo-burn-rate-too-high` | P1 | On-call + Eng Lead | Yes — within 15 min |
| `http-5xx-too-high` | P2 | On-call only | Yes — if >10 min |
| `ecs-cpu-too-high` | P2 | On-call only | Yes — if >10 min |
| `ecs-memory-too-high` | P2 | On-call only | Yes — if >10 min |
