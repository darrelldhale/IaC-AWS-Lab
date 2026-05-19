# Northwind Health Group - SLO Definitions

## Service: Patient Portal (ECS/Fargate on ALB)

### SLO 1 - Availability

**SLI:** Percentage of HTTP requests that return a non-5xx response
**Measurement:** `(HttpRequestCount - Http5xxCount) / HttpRequestCount * 100`
**Source:** CloudWatch metric filters on ECS container logs (namespace: SRELab/Nginx)
**Window:** Rolling 30 days

**SLO Target:** 99.5% of requests succeed
**Error Budget:** 0.5% of requests may fail (= 3.6 hours of total downtime per 30 days)

---

### Burn Rate Thresholds

| Burn Rate | What It Means | Action |
|-----------|--------------|--------|
| < 1.0 | Consuming budget slower than pace — healthy | No action |
| 1.0 – 6.0 | On pace or slow burn — monitor | Watch dashboard |
| > 6.0 | Slow burn alert — budget exhausted in ~5 days | Investigate |
| > 14.4 | Fast burn alert — budget exhausted in 50 hours | Page on-call immediately |

---

### Error Budget Policy

- **Budget > 50% remaining:** Deploy freely, experiments allowed
- **Budget 10-50% remaining:** Caution - no risky deploys without review
- **Budget < 10% remaining:** Freeze non-critical changes, ops focus only
- **Budget exhausted:** Incident declared, leadership notified, change freeze

---

### Review Cadence

SLO compliance reviewed monthly by the ops team
Targets renegotiated with stakeholders if consistently exceeded or consistently missed.

*Document owner: SRE team / Last updated: Month 5 Week 3*


