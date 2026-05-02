import boto3
import json
import os
from datetime import datetime, timedelta

cloudwatch = boto3.client('cloudwatch', region_name='us-east-1')
bedrock = boto3.client('bedrock-runtime', region_name='us-east-1')
s3 = boto3.client('s3', region_name='us-east-1')
sns = boto3.client('sns', region_name='us-east-1')


def get_metric(namespace, metric_name, dimensions, stat='Average', hours=6):
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=hours)
    response = cloudwatch.get_metric_statistics(
        Namespace=namespace,
        MetricName=metric_name,
        Dimensions=dimensions,
        StartTime=start_time,
        EndTime=end_time,
        Period=3600,
        Statistics=[stat]
    )
    datapoints = response.get('Datapoints', [])
    if not datapoints:
        return 0
    return round(sum(d[stat] for d in datapoints) / len(datapoints), 2)


def collect_metrics():
    asg_name = os.environ.get('ASG_NAME', 'SecureScale-ASG')
    alb_arn_suffix = os.environ.get('ALB_ARN_SUFFIX', '')
    tg_arn_suffix = os.environ.get('TG_ARN_SUFFIX', '')

    metrics = {}

    metrics['cpu_avg'] = get_metric(
        'AWS/EC2',
        'CPUUtilization',
        [{'Name': 'AutoScalingGroupName', 'Value': asg_name}]
    )

    metrics['alb_latency'] = get_metric(
        'AWS/ApplicationELB',
        'TargetResponseTime',
        [{'Name': 'LoadBalancer', 'Value': alb_arn_suffix}]
    )

    metrics['unhealthy_hosts'] = get_metric(
        'AWS/ApplicationELB',
        'UnHealthyHostCount',
        [
            {'Name': 'LoadBalancer', 'Value': alb_arn_suffix},
            {'Name': 'TargetGroup', 'Value': tg_arn_suffix}
        ],
        stat='Maximum'
    )

    metrics['http_5xx'] = get_metric(
        'AWS/ApplicationELB',
        'HTTPCode_ELB_5XX_Count',
        [{'Name': 'LoadBalancer', 'Value': alb_arn_suffix}],
        stat='Sum'
    )

    return metrics


def analyze_with_bedrock(metrics):
    prompt = f"""You are a cloud infrastructure expert analyzing AWS metrics for SecureScale, a production web application.

Here are the infrastructure metrics from the last 6 hours:
- Average CPU Utilization: {metrics['cpu_avg']}%
- Average ALB Response Time: {metrics['alb_latency']} seconds
- Maximum Unhealthy Hosts: {metrics['unhealthy_hosts']}
- Total 5XX Errors: {metrics['http_5xx']}

Please provide:
1. HEALTH ASSESSMENT: Overall infrastructure health (Healthy/Warning/Critical)
2. KEY OBSERVATIONS: What these metrics indicate
3. COST OPTIMIZATION: Any cost saving opportunities
4. PERFORMANCE RECOMMENDATIONS: Specific actions to improve performance
5. SECURITY OBSERVATIONS: Any security concerns based on the metrics

Keep your response concise and actionable. Format with clear sections."""

    response = bedrock.invoke_model(
        modelId='amazon.nova-lite-v1:0',
        body=json.dumps({
            'messages': [
                {
                    'role': 'user',
                    'content': [{'text': prompt}]
                }
            ],
            'inferenceConfig': {
                'maxTokens': 800,
                'temperature': 0.3,
            }
        })
    )

    result = json.loads(response['body'].read())
    return result['output']['message']['content'][0]['text']


def save_report(metrics, analysis):
    bucket = os.environ.get('REPORT_BUCKET', '')
    timestamp = datetime.utcnow().strftime('%Y-%m-%d-%H-%M')

    report = {
        'timestamp': timestamp,
        'metrics': metrics,
        'analysis': analysis
    }

    s3.put_object(
        Bucket=bucket,
        Key=f'ai-reports/{timestamp}-report.json',
        Body=json.dumps(report, indent=2),
        ContentType='application/json'
    )

    return f'ai-reports/{timestamp}-report.json'


def send_alert(analysis, report_key):
    topic_arn = os.environ.get('SNS_TOPIC_ARN', '')

    message = f"""
SecureScale AI Ops Report
Generated: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}

{analysis}

Full report saved to S3: {report_key}
    """

    sns.publish(
        TopicArn=topic_arn,
        Subject='SecureScale AI Ops Advisor Report',
        Message=message
    )


def lambda_handler(event, context):
    print("Starting SecureScale AI Ops Advisor...")

    metrics = collect_metrics()
    print(f"Metrics collected: {metrics}")

    analysis = analyze_with_bedrock(metrics)
    print("AI analysis complete")

    report_key = save_report(metrics, analysis)
    print(f"Report saved: {report_key}")

    send_alert(analysis, report_key)
    print("Alert sent")

    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': 'AI Ops Advisor completed successfully',
            'report': report_key,
            'metrics': metrics
        })
    }