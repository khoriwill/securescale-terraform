# ADR-001: Multi-AZ Architecture

## Date
2024-07-01

## Status
Accepted

## Context
SecureScale needs to serve web traffic reliably. A single availability 
zone deployment means one physical data center failure takes the entire 
application offline. AWS availability zones are physically separate 
facilities with independent power, cooling, and networking.

## Decision
Deploy EC2 instances and ALB across two availability zones — us-east-1a 
and us-east-1b. The Auto Scaling Group spans both zones. The ALB sits 
in public subnets in both zones.

## Consequences

### Positive
- If us-east-1a loses power tonight, us-east-1b continues serving traffic
- ALB automatically stops routing to unhealthy AZ instances
- ASG launches replacements in the healthy AZ automatically
- No manual intervention required for AZ-level failures

### Negative
- Slightly higher cost — two instances instead of one
- More complex networking — subnets and route tables per AZ

## Alternatives Considered
Single AZ deployment — rejected because a single data center failure 
would cause complete downtime with no automatic recovery path.

## Lessons Learned
During build we discovered both public subnets were initially placed in 
the same AZ — caught and corrected. AWS subnet AZ placement must be 
explicitly specified, not assumed.