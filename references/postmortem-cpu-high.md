# Post-Mortem: High CPU Utilization on App Server

## Incident Summary
- **Date:** 2026-05-02
- **Duration:** ~5 minutes
- **Severity:** Warning
- **Status:** Resolved

## Timeline
| Time (UTC) | Event |
|------------|-------|
| 21:21 | CPU exceeded 80% threshold |
| 21:23 | CloudWatch alarm transitioned to ALARM state |
| 21:23 | SNS notification delivered to email |
| 21:25 | Runaway processes identified via htop |
| 21:25 | Processes killed via pkill yes |
| 21:27 | CloudWatch alarm transitioned to OK state |
| 21:27 | SNS recovery notification delivered to email |

## Root Cause
Deliberate chaos engineering exercise. Multiple 'yes' processes were spawned to simulate a runaway CPU workload on a t2.micro instance, consuming available CPU burst credits and pushing utilization above 80%

## Impact
- No user-facing impact - nginx continued serving traffic throughout the incident
- No data loss or corruption

## What Worked Well
- CloudWatch alarm fired within expected timeframe
- SNS email notification delivered promptly
- Recovery notification confirmed remediation success
- htop clearly identified offending processes

## What Didn't Work Well
- Initial alarm misconfiguration - dimensions block had tags instead of InstanceId, alarm never evaluated
- t2.micro CPU credit system made it difficult to sustain CPU above threshold using standard stress tools

## Action Items
| Action | Owner | Due Date |
|--------|-------|----------|
| Add InstanceId validation to alarm Terraform module | Darrell | 2026-05-09 |
| Document t2.micro burst credit behavior in wiki | Darrell | 2026-05-09 |
| Consider switching to t3.micro for more predictable CPU | Darrell | 2026-05-09 |

## Lessons Learned
- Always verify CloudWatch alarm dimensions before apply
- t2.micro instances use CPU burst credits - not suitable for sustained load testing
- Detailed monitoring (1-minute intervals) is essential for alarm accuracy

