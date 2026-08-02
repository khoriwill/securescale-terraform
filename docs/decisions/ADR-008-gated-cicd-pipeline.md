# ADR-008: Gated CI/CD Pipeline with Required Human Approval
## Date
2026-08-02
## Status
Accepted
## Context
The GitHub Actions pipeline runs Terraform on every push to main. The
terraform-apply job was configured with `terraform apply -auto-approve`,
meaning any commit merged to main deployed infrastructure automatically
with no human in the loop.

This risk was demonstrated in production. A push containing only a
`terraform fmt` formatting fix -- a cosmetic change touching two files --
triggered an auto-approve apply that provisioned the full stack, including
a billable Application Load Balancer and RDS instance. A change with zero
infrastructure intent silently incurred cost. Auto-approve makes every
commit a potential deployment, which is unacceptable for a stack that
provisions paid resources.
## Decision
Split the pipeline into two jobs and gate the apply behind human approval.

terraform-plan runs automatically on every push and pull request. It runs
init, fmt -check, validate, and plan. It is read-only and safe to run
continuously -- it reports what would change without modifying AWS.

terraform-apply depends on terraform-plan succeeding and is bound to a
GitHub Environment named `production` protected by a required reviewer.
The job pauses at "Waiting" until a human explicitly approves the
deployment. No approval means no apply, which means no cost.
## Consequences
### Positive
- Infrastructure is previewed automatically but never deploys without
  an explicit human decision -- standard enterprise gated-deploy pattern
- Cost is controlled at the source; the meter only starts on approval
- A formatting or documentation push can never again build paid resources
- The plan output gives the reviewer a concrete diff to approve or reject,
  making approval a real control rather than a rubber stamp
### Negative
- Deployments require a manual approval step, adding latency -- which for
  this workload is the intended behavior, not a drawback
## Alternatives Considered
apply -auto-approve on every push -- rejected after it caused a formatting
commit to deploy billable infrastructure unattended.

Branch-only gating (apply only from main) -- necessary but insufficient,
because main still receives trivial commits. Human approval on the
environment is the actual safeguard.

Local-only apply with no CI apply -- safe, but discards the value of an
automated pipeline. The gated approach retains automation and control.
## Implementation Note
The workflow already referenced `environment: production`, but the gate
was inert because the environment had no required reviewers configured.
A GitHub Environment with no protection rules does nothing -- the job runs
straight through. The fix was a repository settings change (add a required
reviewer to the production environment), not a code change. The lock was
present in the workflow; no guard was posted until a reviewer was assigned.
## Security Principle Applied
Separation of duties and change control -- infrastructure changes are
proposed automatically but require explicit human authorization before
execution.
## Validation
After assigning a required reviewer to the production environment, the
terraform-apply job pauses at "Waiting for review" and does not touch AWS
until approved. Rejecting the review leaves the account unchanged.
