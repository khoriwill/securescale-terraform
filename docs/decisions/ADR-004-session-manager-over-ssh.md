# ADR-004: Session Manager Over SSH for Instance Access

## Date
2024-07-01

## Status
Accepted

## Context
EC2 instances occasionally need direct shell access for debugging and 
maintenance. Traditional SSH access requires open port 22, key pair 
management, and either a public IP or bastion host. Each of these 
creates security risks and operational overhead.

## Decision
Use AWS Systems Manager Session Manager exclusively for instance access. 
EC2 IAM role includes AmazonSSMManagedInstanceCore policy. No port 22 
open in any security group. No key pairs distributed to team members. 
All session activity logged to CloudTrail automatically.

## Consequences

### Positive
- Zero open inbound ports on EC2 instances — reduced attack surface
- No SSH key management — no lost keys, no key rotation process
- Every session command logged to CloudTrail — full audit trail
- Works from browser — no local SSH client required
- Satisfies compliance requirements for privileged access management

### Negative
- Requires IAM role with SSM permissions on every instance
- Slight session startup latency compared to direct SSH
- Requires SSM agent running on instance (included in Amazon Linux 2023)

## Alternatives Considered
Bastion host — rejected because it adds another instance to manage, 
patch, and secure. It also requires open port 22 on the bastion itself, 
shifting the attack surface rather than eliminating it.

SSH with key pairs — rejected because key distribution and rotation 
creates operational overhead and compliance risk in regulated environments.

## Security Principle Applied
Least privilege and attack surface reduction — eliminate open ports 
entirely rather than restricting them.