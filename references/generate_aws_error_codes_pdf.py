from fpdf import FPDF
from fpdf.enums import XPos, YPos

class PDF(FPDF):
    def header(self):
        self.set_font("Helvetica", "B", 10)
        self.set_fill_color(35, 47, 62)
        self.set_text_color(255, 255, 255)
        self.cell(0, 8, "AWS HTTP Error Codes - Support Engineer Reference", align="C", fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(0, 0, 0)
        self.ln(2)

    def footer(self):
        self.set_y(-12)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 8, f"Page {self.page_no()}", align="C")

    def section_title(self, title, color):
        self.set_font("Helvetica", "B", 12)
        self.set_fill_color(*color)
        self.set_text_color(255, 255, 255)
        self.cell(0, 8, f"  {title}", fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(0, 0, 0)
        self.ln(2)

    def sub_title(self, code, meaning, color):
        self.set_font("Helvetica", "B", 11)
        self.set_fill_color(*color)
        self.set_text_color(255, 255, 255)
        self.cell(0, 7, f"  {code} - {meaning}", fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_text_color(0, 0, 0)
        self.ln(1)

    def body_text(self, text):
        self.set_font("Helvetica", "", 9)
        self.multi_cell(0, 5, text, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    def table(self, headers, rows, col_widths):
        self.set_font("Helvetica", "B", 9)
        self.set_fill_color(220, 220, 220)
        for i, h in enumerate(headers):
            self.cell(col_widths[i], 6, h, border=1, fill=True)
        self.ln()
        self.set_font("Helvetica", "", 8)
        for row in rows:
            # Calculate max height needed for this row
            max_lines = 1
            for i, cell in enumerate(row):
                # Estimate lines needed
                chars_per_line = col_widths[i] / 2.1
                lines = max(1, len(cell) / chars_per_line)
                max_lines = max(max_lines, lines)
            row_h = max(5, int(max_lines) * 4.5)

            y_before = self.get_y()
            x_start = self.get_x()
            x = x_start
            for i, cell in enumerate(row):
                self.multi_cell(col_widths[i], row_h, cell, border=1, new_x=XPos.RIGHT, new_y=YPos.TOP)
                x += col_widths[i]
            self.set_xy(x_start, y_before + row_h)
        self.ln(2)

    def code_block(self, text):
        self.set_font("Courier", "", 8)
        self.set_fill_color(245, 245, 245)
        self.set_draw_color(200, 200, 200)
        self.multi_cell(0, 4.5, text, border=1, fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_draw_color(0, 0, 0)
        self.ln(2)

    def note(self, text):
        self.set_font("Helvetica", "I", 8)
        self.set_fill_color(255, 249, 220)
        self.multi_cell(0, 5, f"  Note: {text}", border=0, fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.ln(1)


pdf = PDF()
pdf.set_auto_page_break(auto=True, margin=14)
pdf.add_page()
pdf.set_font("Helvetica", "", 9)

# Golden Rule banner
pdf.set_fill_color(255, 153, 0)
pdf.set_text_color(255, 255, 255)
pdf.set_font("Helvetica", "B", 10)
pdf.cell(0, 8, "  Golden Rule:  4xx = Client / Config Problem  |  5xx = Server / Infrastructure Problem  (YOU OWN THESE)", fill=True, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
pdf.set_text_color(0, 0, 0)
pdf.ln(4)

# ── No HTTP Code ─────────────────────────────────────────────────────────────
pdf.section_title("No HTTP Code - Connection Timeout / Refused", (80, 80, 80))
pdf.body_text("Traffic is blocked at the network level before any HTTP response can be generated.")
pdf.table(
    ["AWS Service", "What to Look For"],
    [
        ["Security Groups", "Inbound rules on the ALB SG - is port 80/443 open to 0.0.0.0/0?"],
        ["Network ACLs (NACLs)", "Stateless rules on the subnet - BOTH inbound AND outbound rules required"],
        ["Route Tables", "Is there a route to an Internet Gateway (IGW) for public subnets?"],
        ["Internet Gateway", "Is an IGW attached to the VPC?"],
        ["NAT Gateway", "For private subnets - is outbound traffic routed through a NAT GW?"],
    ],
    [50, 140]
)
pdf.code_block(
    "VPC -> Security Groups -> Inbound Rules (look for port 80/443)\n"
    "VPC -> Network ACLs -> check both inbound + outbound\n"
    "VPC -> Route Tables -> confirm 0.0.0.0/0 -> igw-xxxxxxxx"
)

# ── 3xx ───────────────────────────────────────────────────────────────────────
pdf.section_title("3xx - Redirects (Usually Not Errors)", (100, 140, 100))
pdf.table(
    ["Code", "Meaning", "AWS Service", "What to Check"],
    [
        ["301/302", "Redirect", "ALB, CloudFront", "ALB listener rules redirecting HTTP -> HTTPS; CloudFront default root object"],
        ["304", "Not Modified", "CloudFront, S3", "Cache headers (ETag, Cache-Control) - usually fine"],
    ],
    [18, 28, 40, 104]
)

# ── 4xx ───────────────────────────────────────────────────────────────────────
pdf.section_title("4xx - Client / Configuration Errors", (200, 80, 50))

pdf.sub_title("400", "Bad Request", (210, 100, 60))
pdf.table(
    ["Service", "What to Check"],
    [
        ["API Gateway", "Malformed JSON body, missing required headers, wrong Content-Type"],
        ["ALB", "Oversized headers exceeding ALB limits"],
        ["WAF", "Request blocked by AWS WAF rule - check WAF logs in CloudWatch"],
    ],
    [45, 145]
)

pdf.sub_title("401", "Unauthorized", (210, 100, 60))
pdf.table(
    ["Service", "What to Check"],
    [
        ["API Gateway", "Cognito authorizer - token expired or missing Authorization header"],
        ["API Gateway", "Lambda authorizer returning Unauthorized policy"],
        ["IAM", "Missing execute-api:Invoke permission on the caller's IAM role"],
    ],
    [45, 145]
)
pdf.code_block(
    "API Gateway -> Authorizers -> check authorizer type and token source\n"
    "CloudWatch Logs -> API Gateway execution logs -> look for 'Unauthorized'"
)

pdf.sub_title("403", "Forbidden", (210, 100, 60))
pdf.table(
    ["Service", "What to Check"],
    [
        ["S3", "Bucket policy denying access; Block Public Access enabled; missing bucket ACL"],
        ["CloudFront", "WAF web ACL blocking request; geo-restriction rules; signed URL/cookie required"],
        ["API Gateway", "Resource policy denying source IP or VPC; IAM auth enabled but caller lacks permission"],
        ["IAM", "Caller's role/policy missing s3:GetObject, execute-api:Invoke, etc."],
        ["ALB", "Listener rule configured to return a fixed 403 response"],
    ],
    [45, 145]
)
pdf.code_block(
    "S3 -> Bucket -> Permissions -> Block Public Access + Bucket Policy\n"
    "CloudFront -> Distribution -> Security -> WAF + Geo Restrictions\n"
    "IAM -> Policy Simulator -> test the specific action being denied"
)
pdf.note("A 403 from S3 often means the bucket exists but access is denied - not that the file is missing (that's a 404).")

pdf.sub_title("404", "Not Found", (210, 100, 60))
pdf.table(
    ["Service", "What to Check"],
    [
        ["ALB", "Listener rules don't match the request path - no rule returns a valid target group"],
        ["API Gateway", "Wrong stage name in URL, resource path doesn't exist, method not defined"],
        ["S3 (static site)", "Wrong object key, wrong bucket region endpoint, index document not configured"],
        ["CloudFront", "Origin path misconfiguration; S3 key prefix mismatch"],
        ["Route 53", "DNS pointing to wrong resource or stale record"],
    ],
    [45, 145]
)
pdf.code_block(
    "ALB -> Listeners -> View/Edit Rules -> check path-based routing\n"
    "API Gateway -> Stages -> confirm stage name matches URL\n"
    "S3 -> Objects -> confirm the exact key exists"
)

pdf.sub_title("429", "Too Many Requests", (210, 100, 60))
pdf.table(
    ["Service", "What to Check"],
    [
        ["API Gateway", "Usage plan throttle limits (requests/sec and burst); stage-level throttling"],
        ["Lambda", "Concurrency limit reached - check reserved vs. account-level concurrency"],
        ["WAF", "Rate-based rule triggered - check WAF sampled requests in console"],
    ],
    [45, 145]
)
pdf.code_block(
    "API Gateway -> Usage Plans -> check throttle rate/burst\n"
    "Lambda -> Configuration -> Concurrency -> check reserved concurrency\n"
    "WAF -> Web ACLs -> Sampled Requests -> look for rate-based rule matches"
)

# ── 5xx ───────────────────────────────────────────────────────────────────────
pdf.add_page()
pdf.section_title("5xx - Server / Infrastructure Errors  (YOU OWN THESE)", (180, 40, 40))

pdf.sub_title("500", "Internal Server Error", (190, 60, 60))
pdf.body_text("Application crashed or threw an unhandled exception.")
pdf.table(
    ["Service", "What to Check"],
    [
        ["Lambda", "Unhandled exception in function code - check CloudWatch Logs for ERROR"],
        ["EC2", "Application process crashed - check app logs via CloudWatch or SSH"],
        ["ECS / Fargate", "Container exiting with non-zero exit code - check ECS task stopped reason"],
        ["API Gateway", "Lambda integration returning malformed response (missing statusCode field)"],
    ],
    [45, 145]
)
pdf.code_block(
    "CloudWatch -> Log Groups -> /aws/lambda/<function-name> -> filter for ERROR\n"
    "ECS -> Clusters -> Tasks -> Stopped -> check 'Stopped Reason'"
)

pdf.sub_title("502", "Bad Gateway", (190, 60, 60))
pdf.body_text("The load balancer or proxy received an invalid response from the backend.")
pdf.table(
    ["Service", "What to Check"],
    [
        ["ALB", "EC2 SG blocking inbound traffic from the ALB SG on the app port"],
        ["ALB", "Target group targets showing unhealthy; app not listening on correct port"],
        ["API Gateway", "Lambda returned a response missing required fields (statusCode, body)"],
        ["CloudFront", "Origin (ALB, S3, EC2) returned invalid response or is unreachable"],
    ],
    [45, 145]
)
pdf.code_block(
    "ALB -> Target Groups -> Targets -> check health status + health check port\n"
    "EC2 -> Security Groups -> confirm inbound rule allows ALB SG on app port (e.g. 8080)\n"
    "CloudWatch -> ALB Access Logs -> look for backend response codes"
)
pdf.note("Most common root cause: EC2/ECS Security Group is missing an inbound rule that allows traffic FROM the ALB's security group.")

pdf.sub_title("503", "Service Unavailable", (190, 60, 60))
pdf.body_text("No healthy targets are available to handle the request.")
pdf.table(
    ["Service", "What to Check"],
    [
        ["ALB", "All targets in the target group are failing health checks"],
        ["Auto Scaling", "Desired capacity is 0 or instances haven't launched/passed status checks yet"],
        ["ECS", "No running tasks in the service; task definition errors preventing launch"],
        ["EKS", "No ready pods available; node group scaled to 0"],
    ],
    [45, 145]
)
pdf.code_block(
    "ALB -> Target Groups -> Targets -> all showing 'unhealthy'\n"
    "EC2 -> Auto Scaling Groups -> check desired / min / max capacity\n"
    "ECS -> Services -> check running task count vs. desired count\n"
    "CloudWatch -> ALB Metrics -> HealthyHostCount = 0 is your signal"
)
pdf.note("Health check port blocked by a Security Group is the #1 cause of 503 on ALB.")

pdf.sub_title("504", "Gateway Timeout", (190, 60, 60))
pdf.body_text("The load balancer timed out waiting for the backend to respond.")
pdf.table(
    ["Service", "What to Check"],
    [
        ["ALB", "ALB idle timeout (default 60s) - target took too long to respond"],
        ["API Gateway", "Hard 29-second maximum integration timeout - Lambda or backend too slow"],
        ["Lambda", "Function timeout setting too low; function hitting configured max duration"],
        ["RDS / Aurora", "Slow query causing the application to hang waiting on the database"],
        ["ECS / EC2", "Application under high CPU/memory load - check CloudWatch metrics"],
    ],
    [45, 145]
)
pdf.code_block(
    "ALB -> Attributes -> Idle Timeout (increase if needed)\n"
    "Lambda -> Configuration -> General -> Timeout setting\n"
    "RDS -> Performance Insights -> identify slow queries\n"
    "CloudWatch -> EC2/ECS metrics -> CPUUtilization, MemoryUtilization"
)
pdf.note("API Gateway's 29-second limit is hard and cannot be increased. If Lambda regularly hits it, consider an async pattern with SQS/SNS.")

# ── Quick Reference Table ─────────────────────────────────────────────────────
pdf.ln(2)
pdf.section_title("Layer -> Error Code Quick Reference", (35, 47, 62))
pdf.table(
    ["Layer", "Typical Error", "AWS Service"],
    [
        ["DNS", "No response", "Route 53"],
        ["Network block", "Connection timeout", "VPC, Security Groups, NACLs"],
        ["Load balancer -> EC2 blocked", "502, 503", "ALB, Security Groups"],
        ["No healthy targets", "503", "ALB Target Groups, Auto Scaling"],
        ["Backend slow", "504", "Lambda, RDS, EC2, ECS"],
        ["App crash", "500", "Lambda (CloudWatch Logs), ECS"],
        ["Auth / permissions", "401, 403", "IAM, Cognito, API Gateway"],
        ["Rate limiting", "429", "API Gateway Usage Plans, WAF"],
        ["Wrong path / resource", "404", "API Gateway, ALB Listener Rules, S3"],
    ],
    [65, 35, 90]
)

# ── First 5 Things ────────────────────────────────────────────────────────────
pdf.section_title("First 5 Things to Check on Any 5xx", (35, 47, 62))
steps = [
    ("1. CloudWatch Logs", "/aws/lambda/<name>, ECS task logs, or ALB access logs"),
    ("2. ALB Target Group health", "Are targets healthy? What port is the health check using?"),
    ("3. Security Groups", "Does the EC2/ECS SG allow inbound FROM the ALB's security group?"),
    ("4. Auto Scaling / ECS desired count", "Is anything actually running? Check desired vs. running count."),
    ("5. CloudWatch Metrics", "CPUUtilization, HealthyHostCount, Lambda Errors/Duration"),
]
for step, detail in steps:
    pdf.set_font("Helvetica", "B", 9)
    pdf.cell(0, 5, f"  {step}", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "", 9)
    pdf.cell(8, 5, "")
    pdf.cell(0, 5, detail, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.ln(1)

output_path = "/home/darrell/sre-lite-lab/references/aws-http-error-codes.pdf"
pdf.output(output_path)
print(f"PDF saved to: {output_path}")
