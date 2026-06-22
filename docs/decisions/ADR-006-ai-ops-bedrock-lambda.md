# ADR-006: AI Ops Layer Using Lambda and Amazon Bedrock

## Date
2024-11-01

## Status
Accepted

## Context
SecureScale generates CloudWatch metrics continuously -- CPU utilization, ALB response times, unhealthy host counts, and 5XX error rates. Manual review requires human intervention on a scheduled basis. Modern cloud operations are moving toward AI-assisted analysis that can surface cost optimization opportunities, performance anomalies, and security observations without waiting for a human to check a dashboard.

## Decision
Implement an automated AI Ops Advisor using three AWS services: EventBridge triggers a Lambda function on a rate(6 hours) schedule. Lambda pulls real CloudWatch metrics and formats them into a structured prompt. The prompt is sent to Amazon Bedrock Nova Lite, which returns a structured analysis covering health assessment, cost optimization opportunities, performance recommendations, and security observations. The report is stored in S3 and delivered via SNS email notification.

## Consequences

### Positive
- Infrastructure analyzes itself without human scheduling
- AI surfaces cost rightsizing opportunities (flagged 0.48% CPU utilization)
- Security observations generated automatically every 6 hours
- Demonstrates AWS-native AI integration without external dependencies
- Serverless -- zero cost when not running, no servers to manage

### Negative
- Bedrock API calls incur per-token cost (minimal at current scale)
- AI analysis quality depends on prompt engineering quality
- No retrieval accuracy metrics yet -- recommendations not yet validated
- Lambda cold start adds latency to first analysis of each cycle

## Alternatives Considered
AWS Trusted Advisor -- requires Business support plan for full recommendations. Rejected to avoid support tier cost dependency.

Third-party tools (Datadog, New Relic AI) -- rejected to keep the stack AWS-native and avoid external service dependencies and costs.

CloudWatch Anomaly Detection -- does not generate natural language recommendations. Used alongside Bedrock rather than as a replacement.

## Lessons Learned
Real AI output confirmed in testing -- Bedrock flagged 0.48% CPU utilization and recommended rightsizing to a smaller instance type. This is the same pattern used by AWS Trusted Advisor and commercial AIOps platforms, implemented natively at near-zero cost.
