# ADR-001: Multi-AZ Architecture for High Availability

## Date
2024-07-01

## Status
Accepted

## Context
SecureScale simulates a production-grade regulated workload. Single availability zone deployments have a single point of failure -- if the AWS data center hosting us-east-1a experiences an outage, the entire application goes down. Production systems in regulated environments (healthcare, federal, financial) require high availability guarantees that a single AZ cannot provide.

## Decision
Deploy all compute and load balancing across two availability zones: us-east-1a and us-east-1b. The Application Load Balancer spans both public subnets. The Auto Scaling Group distributes EC2 instances across both AZs. Private subnets for RDS are created in both AZs to support future Multi-AZ RDS failover. If one AZ goes offline, the ALB detects unhealthy targets and routes all traffic to the healthy AZ automatically with zero manual intervention.

## Consequences

### Positive
- No single point of failure at the infrastructure layer
- ALB health checks automatically reroute traffic on AZ failure
- ASG replaces failed instances in the healthy AZ automatically
- Satisfies high availability requirements for regulated workloads
- Foundation for Multi-AZ RDS failover when needed

### Negative
- Double the subnets to manage (2 public, 2 private)
- Slightly higher complexity in VPC and route table configuration
- Free tier EC2 hours consumed faster with 2 instances vs 1

## Alternatives Considered
Single AZ deployment -- rejected because it creates a single point of failure. Acceptable for development but not for production simulation.

Three or more AZs -- considered but rejected as over-engineered for this project scope. Two AZs provide the HA pattern without unnecessary complexity.

## Architecture Principle Applied
High availability through redundancy -- no single component failure should take down the system.
