# ADR-005: Terraform IaC Over Manual Console Configuration

## Date
2024-07-01

## Status
Accepted

## Context
AWS infrastructure can be built through the console (point and click), 
AWS CLI, CloudFormation, or Terraform. Console-built infrastructure is 
not reproducible, not version controlled, and not reviewable. Any 
deviation from the intended configuration is invisible until something 
breaks.

## Decision
All SecureScale infrastructure is defined as Terraform HCL code across 
13 files. Infrastructure is version controlled in GitHub. Changes go 
through a CI/CD pipeline with plan review and gated approval before 
apply. Remote state in S3 tracks all built resources.

## Consequences

### Positive
- Entire environment reproducible in under 3 minutes from terraform apply
- Infrastructure changes reviewed like code — pull request workflow
- State file provides authoritative record of all built resources
- Variables make configuration reusable across environments and regions
- Outputs expose key values (ALB DNS, VPC ID) after every deployment
- Drift detection — terraform plan shows if real infra differs from code

### Negative
- Learning curve for HCL syntax and Terraform concepts
- Resources built outside Terraform (manually) create state conflicts
- Backend must be bootstrapped before Terraform can manage state

## Alternatives Considered
AWS CloudFormation — rejected in favor of Terraform for multi-cloud 
portability, better state management, and more readable HCL syntax 
compared to CloudFormation JSON/YAML.

AWS CDK — considered but rejected to keep the stack simple and 
language-agnostic for this project phase.

## Lessons Learned
Resources built manually before Terraform adoption cause 
EntityAlreadyExists conflicts. Going forward — if Terraform owns a 
resource, never touch it manually. Terraform is the single source of 
truth.