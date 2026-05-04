# ADR-003: Remote State in S3 with DynamoDB Locking

## Date
2024-07-01

## Status
Accepted

## Context
Terraform requires a state file to track what infrastructure it has 
built. The default behavior stores state locally on the machine running 
Terraform. Local state has critical problems — it is lost if the machine 
fails, cannot be shared with teammates, and has no locking mechanism 
to prevent concurrent modifications.

## Decision
Store Terraform state in an S3 bucket with the following configuration:
- Bucket: securescale-terraform-state-485141928563
- Key: securescale/terraform.tfstate
- Versioning: enabled — every state change is preserved and reversible
- Encryption: AES256 server-side encryption
- DynamoDB table: securescale-terraform-locks for state locking

## Consequences

### Positive
- State survives machine failure — stored durably in S3
- DynamoDB locking prevents two simultaneous applies corrupting state
- Versioning allows rollback to previous state if needed
- Encryption protects sensitive resource IDs in state file
- Team-ready — any authorized user can run Terraform against same state

### Negative
- Requires S3 bucket and DynamoDB table to exist before terraform init
- Slight latency on state reads compared to local file

## Alternatives Considered
Terraform Cloud — rejected to maintain full AWS-native architecture 
and avoid external service dependency. HashiCorp Consul — rejected as 
over-engineered for a single-project state backend.

## Lessons Learned
State must be bootstrapped manually before Terraform can manage it — 
the S3 bucket and DynamoDB table cannot be created by the same 
Terraform configuration that uses them as a backend.