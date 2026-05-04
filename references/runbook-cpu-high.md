# Runbook: High CPU Utilization on App Server

## Alert
- **Alarm:** sre-lab-cpu-high
- **Threshold:** CPU > 80% for 2 consecutive 2-minute periods
- **Severity:** Warning

## Symptoms
- CloudWatch alarm transitions to ALARM state
- Email notification received from SNS topic sre-lab-alerts

## Diagnosis Steps

### 1. Identify the offending process
Connect to the App Server via SSM:
```bash
aws ssm start-session --target <instance-id>
```
Run htop to identify top CPU consumers:
```bash
htop
```

### 2. Check how long the spike has been occurring
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=<instance-id> \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average \
  --output table
```

### 3. Check if nginx is still serving traffic
```bash
curl -I http://localhost
```

### 4. Check system logs for anomalies
```bash
sudo journalctl -n 50 --no-pager
```

## Remediation

### If caused by a runaway process:
```bash
kill <pid>
```
Or if unresponsive:
```bash
kill -9 <pid>
```

### If caused by legitimate traffic spike:
- Consider upgrading instance type
- Consider adding an Auto Scaling Group

## Recovery Confirmation
- CloudWatch alarm returns to OK state
- Email notification received confirming recovery
- nginx responding with HTTP 200

## Escalation
If CPU remains above 80% after remediation steps, escalate to senior SRE.
