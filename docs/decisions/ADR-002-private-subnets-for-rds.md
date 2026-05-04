# ADR-002: RDS Database in Private Subnets

## Date
2024-07-01

## Status
Accepted

## Context
SecureScale requires a database layer. The database contains application 
data and should not be directly accessible from the internet. Any 
publicly accessible database is a direct attack surface — exposed to 
brute force, credential stuffing, and direct exploitation attempts.

## Decision
Deploy RDS MySQL in private subnets with no public IP address. The RDS 
security group only accepts connections on port 3306 from the EC2 
security group — not from any CIDR range, not from the internet, only 
from application instances that already passed the ALB.

## Consequences

### Positive
- Database is invisible from the internet — no public endpoint to attack
- Security group chaining means only EC2 instances can reach RDS
- Defense in depth — attacker must compromise EC2 before reaching DB
- Satisfies compliance requirements for data layer isolation

### Negative
- EC2 instances need outbound access to reach RDS (handled via VPC routing)
- No direct database access from developer machines — requires bastion 
  or Session Manager tunnel (acceptable tradeoff)

## Alternatives Considered
Public RDS with security group restrictions — rejected because a public 
IP still exposes the endpoint to enumeration and scanning even with 
port restrictions in place.

## Security Principle Applied
Defense in depth — multiple security layers so compromising one layer 
does not immediately expose the data layer.