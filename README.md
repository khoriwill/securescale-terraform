SecureScale — AWS Cloud Infrastructure

Production-grade, multi-AZ auto-scaling web infrastructure built and deployed 
using Terraform Infrastructure as Code with automated CI/CD via GitHub Actions.

---

## Architecture

```
Internet
    ↓
Application Load Balancer (SecureScale-ALB)
Public Subnets — us-east-1a + us-east-1b
    ↓               ↓
EC2 (us-east-1a)  EC2 (us-east-1b)
Apache ✓          Apache ✓
    ↓               ↓
RDS MySQL (Private Subnets)
No public access — EC2 only
    ↓
CloudTrail Audit Logging
Every API call recorded to S3
```
---

## What This Demonstrates

- **Multi-AZ High Availability** — instances across two AWS data centers. 
  If one goes down, traffic routes automatically to the other.
- **Infrastructure as Code** — entire AWS environment defined in 5 Terraform 
  files. Destroyed and rebuilt identically in under 3 minutes.
- **CI/CD Pipeline** — every git push triggers automated terraform plan. 
  Gated approval required before terraform apply touches AWS.
- **Remote State Management** — tfstate stored in encrypted S3 with DynamoDB 
  locking. No local state, safe for team collaboration.
- **Zero-Touch Provisioning** — launch template user data script auto-installs 
  Apache on every new instance. ASG self-heals with no manual intervention.
- **Least-Privilege IAM** — dedicated terraform-user and EC2 IAM role with 
  scoped permissions. SSM Session Manager replaces SSH — no open port 22.
- **Security Group Layering** — EC2 instances only accept traffic from the ALB 
  security group, never directly from the internet.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Cloud Provider | AWS (us-east-1) |
| IaC | Terraform v1.14 |
| Compute | EC2 t3.micro (Amazon Linux 2023) |
| Networking | VPC, Subnets, IGW, Route Tables |
| Load Balancing | Application Load Balancer |
| Auto Scaling | Auto Scaling Group + Launch Template |
| Access Control | IAM Roles, SSM Session Manager |
| State Backend | S3 + DynamoDB locking |
| CI/CD | GitHub Actions |
| Web Server | Apache HTTP |
| RDS MySQL | Database layer (private subnets) |

---

## Project Structure
securescale-terraform/
├── main.tf            ← Provider + S3 remote backend
├── variables.tf       ← All configurable inputs
├── outputs.tf         ← ALB, VPC, S3, RDS endpoints
├── vpc.tf             ← Network foundation
├── security_groups.tf ← Layered firewall rules
├── alb.tf             ← Load balancer + health checks
├── asg.tf             ← IAM + EC2 + Auto Scaling
├── cloudtrail.tf      ← Audit logging
├── ssl.tf             ← HTTPS ready to activate
├── rds.tf             ← Database layer
├── s3.tf              ← Asset storage + IAM access
├── monitoring.tf      ← CloudWatch + SNS alerts
├── README.md          ← Portfolio documentation
└── .github/
    └── workflows/
        └── terraform.yml ← CI/CD pipeline
---

## Deploy It Yourself

**Prerequisites:** AWS account, Terraform, AWS CLI

```bash
git clone https://github.com/khoriwill/securescale-terraform.git
cd securescale-terraform
aws configure
terraform init
terraform apply
```

**Tear it down:**
```bash
terraform destroy
```

---

## CI/CD Pipeline

Every push to `main` triggers the GitHub Actions pipeline:

1. `terraform init` — initializes backend
2. `terraform fmt` — checks formatting
3. `terraform validate` — validates syntax
4. `terraform plan` — previews changes
5. **Manual approval gate** — review before apply
6. `terraform apply` — deploys to AWS

---

## Key Concepts Demonstrated

- Availability Zone redundancy and failover
- ALB health check configuration and target group management  
- ASG desired/min/max capacity and self-healing behavior
- IAM least-privilege access patterns
- Terraform state management and remote backends
- Infrastructure dependency ordering

---

*Built as part of SecureScale — a hands-on AWS Solutions Architect portfolio project.*