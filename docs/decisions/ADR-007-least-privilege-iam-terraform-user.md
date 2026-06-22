# ADR-007: Least-Privilege IAM for Terraform Automation User

## Date
2026-06-22

## Status
Accepted

## Context
The terraform-user IAM user authenticates the GitHub Actions CI/CD
pipeline and local Terraform runs against AWS. Initially this user
held AdministratorAccess -- an AWS managed policy granting unrestricted
access to all AWS services and resources. This violates the principle
of least privilege. A compromised terraform-user credential with
AdministratorAccess would give an attacker full control of the AWS
account including the ability to create IAM users, exfiltrate data,
and deploy malicious infrastructure.

## Decision
Replace AdministratorAccess with two custom scoped IAM policies:
SecureScalePolicy1 covers infrastructure services -- EC2, VPC, ALB,
ASG, RDS, and their supporting networking primitives.
SecureScalePolicy2 covers platform services -- S3, IAM role management,
Lambda, EventBridge, CloudTrail, CloudWatch, SNS, DynamoDB, Bedrock,
and SSM. Each policy grants only the specific actions Terraform
actually calls -- no wildcard service access, no administrative
privileges beyond what the codebase requires.

## Consequences

### Positive
- Compromised credentials cannot escalate to full account takeover
- Blast radius of credential leak limited to SecureScale resources
- Satisfies CISM governance principle of least privilege
- Passes terraform plan with zero permission errors -- fully validated
- Auditable -- policy documents are version controlled alongside IaC

### Negative
- Two policies required due to AWS 6144 character policy size limit
- New Terraform resources may require policy updates before deploying
- Initial scoping required careful analysis of all tf file API calls

## Alternatives Considered
PowerUser managed policy -- rejected because it still grants broad
service access beyond what SecureScale requires.

IAM permissions boundary -- considered as an additional guardrail
but deferred as the scoped policies already satisfy least privilege
for the current project scope.

## Security Principle Applied
Least privilege -- every identity receives only the permissions it
needs to perform its function, nothing more.

## Validation
terraform plan executed successfully with zero AccessDenied errors
after replacing AdministratorAccess with the two scoped policies.
