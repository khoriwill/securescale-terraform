# ADR-009: Read Permissions for the Terraform Automation User
## Date
2026-08-02
## Status
Accepted (supersedes the Validation claim in ADR-007)
## Context
ADR-007 scoped terraform-user down from AdministratorAccess to two custom
policies (SecureScalePolicy1, SecureScalePolicy2) and validated the change
with `terraform plan` returning zero AccessDenied errors. That validation
was necessary but incomplete.

`terraform plan` does not exercise every permission the tool requires.
Terraform reads a resource back after creating it (to record it in state)
and reads all resources during the refresh that precedes both plan and
destroy. Some of these read actions are only invoked during apply and
destroy -- never during a standalone plan of an empty account. A plan that
passes clean can therefore hide missing read permissions.

This surfaced in practice. With the scoped policies in place, a full apply
built 44 of 46 resources and then failed on two missing read actions:
- lambda:GetFunctionCodeSigningConfig
- elasticloadbalancing:DescribeListenerAttributes

The identity could create the Lambda function and the ALB listener but
could not read them back to record their attributes in state. The same two
missing reads then blocked destroy entirely -- because destroy begins with
a refresh, which is all reads. The account was briefly trapped in both
directions: unable to finish building and unable to start tearing down.
## Decision
Grant the two missing read actions to the read-oriented policy
(SecureScaleReadAccess), added explicitly and individually rather than via
wildcards. The permission set stays as tight as the tooling requires; the
failures themselves identify the exact minimum actions to add.

For the immediate operational block, `terraform destroy -refresh=false`
was used to skip the refresh and tear down using the existing, fresh state.
This is a safe emergency lever only when the state file is known to be
current -- it trades drift-detection for the ability to proceed.
## Consequences
### Positive
- apply, plan, and destroy all run clean after adding the two read actions
- Least privilege is preserved -- two specific reads added, no wildcards,
  admin never restored
- The record now reflects that plan-only validation is insufficient
### Negative
- Future new resources or providers may again surface missing read actions
  during apply or destroy that plan did not reveal; these are resolved the
  same way -- add the specific action the failure names
## Alternatives Considered
Wildcard read grants (elasticloadbalancing:Describe*, lambda:Get*) --
rejected. They would prevent future friction but re-expand the blast radius
that ADR-007's scoping was designed to shrink. Explicit minimal actions are
preferred.

Reverting to AdministratorAccess -- rejected outright; it would erase the
least-privilege posture to avoid a two-line policy addition.
## Security Principle Applied
Least privilege includes read actions. Scoping an automation identity down
from admin requires granting not only create and delete actions but also
the describe and get actions the tool uses to verify state. Validation must
exercise apply and destroy, not plan alone.
## Validation
After adding the two read actions, `terraform plan` on the empty account
returned `Plan: 46 to add, 0 to change, 0 to destroy` with zero
AccessDenied errors, and the earlier apply/destroy failures did not recur.
Full apply-and-destroy validation is the standard going forward, not plan
alone.
