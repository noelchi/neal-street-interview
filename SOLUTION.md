# Solution

## Summary

This project implements a production-shaped dev slice for the `rewards` web tier:

- Public endpoint: AWS Application Load Balancer.
- Compute: Amazon Linux EC2 instances in protected subnets.
- Scale path: Auto Scaling Group with desired capacity set to 1 for dev.
- Configuration: Ansible over AWS Systems Manager.
- Secret source: AWS SSM Parameter Store SecureString, provisioned outside the repo.
- Observability: CloudWatch alarms for ALB target health and EC2 CPU load.
- Delivery: GitHub Actions plan on PR and manual staged dev operations.

## AWS Design

The VPC contains two public subnets for the Application Load Balancer and two protected subnets for EC2. Instances do not receive public IP addresses. Their security group accepts application traffic only from the ALB security group on port `8080`.

The Auto Scaling Group spans the protected subnets. Dev starts with one instance to minimize cost, while the layout can scale by changing `desired_capacity`, `min_size`, and `max_size`.

There is no NAT Gateway. This keeps cost lower and reduces outbound exposure. Instance management happens through VPC interface endpoints for Systems Manager:

- `ssm`
- `ssmmessages`
- `ec2messages`

This keeps Ansible access private and avoids opening SSH to the internet.

## Application Design

The app is a minimal Python HTTP service managed by systemd. It serves:

```json
{"service":"rewards","status":"ok","commit":"","region":""}
```

The service requires `APP_SECRET` at startup but never returns it from the health endpoint. This demonstrates that the app consumes a secret provisioned outside source control without exposing the value.

For a larger service, I would replace the static Python handler with the real application package and keep the same systemd, secret, and ALB patterns.

## Ansible Design

Ansible uses the `amazon.aws.aws_ec2` dynamic inventory plugin to discover instances by tags. Connections use `amazon.aws.aws_ssm`, so replacement instances can be configured without public IPs, bastions, or SSH security group rules.

The playbook:

- Creates an unprivileged service user.
- Installs the app under `/opt/rewards`.
- Reads `/rewards/dev/APP_SECRET` from SSM Parameter Store.
- Writes a systemd environment file with the secret and deployment metadata.
- Enables and starts the service.
- Applies a lightweight Linux baseline through sysctl settings and restrictive file permissions.

## State Handling

For local experimentation, Terraform can use local state. For a small team, the recommended approach is an S3 backend with native S3 lockfile locking:

- S3 provides shared durable state and version history.
- S3 lockfiles prevent overlapping applies without requiring a DynamoDB table.
- Access can be controlled through IAM.

The trade-off is that the backend bucket must be bootstrapped once before the main stack can use it. `terraform/versions.tf` contains the backend configuration.

## Observability Choice

The mandatory observability path is basic CloudWatch metrics and alarms:

- ALB unhealthy target count answers “Is it up?”
- EC2 CPU utilization answers “Is it overloaded?”

Centralized logs are left as a stretch goal. In production I would add CloudWatch Agent or application-native log shipping with retention, structured JSON logs, and alarm routing to the team’s incident channel.

## CI/CD

GitHub Actions is used because it is lightweight and visible for a GitHub repository.

Pull requests to `main`:

- Check Terraform formatting.
- Initialize Terraform without applying.
- Validate Terraform.
- Run a dev Terraform plan.
- Run Ansible syntax checks.

Manual workflow dispatch stages:

- `plan`: run the dev Terraform plan and Ansible syntax checks outside a pull request.
- `import-existing`: import selected pre-existing dev resources into the S3-backed Terraform state.
- `apply`: apply Terraform to dev.
- `configure`: run the Ansible playbook against discovered dev instances.

The workflow pins Terraform to `1.10.0` because the S3 backend uses native lockfile locking. It uses GitHub OIDC to assume an AWS role. Dev and prod credentials should be separate roles with separate trust and permission boundaries.

## Promotion to Prod

Prod would use the same Terraform and Ansible code with separate variable files, state, AWS role, and SSM secret path:

- `terraform/prod.tfvars`
- S3 state key such as `rewards/prod/terraform.tfstate`
- GitHub environment `prod`
- AWS role `GitHubRewardsProdDeployRole`
- Secret path `/rewards/prod/APP_SECRET`

Promotion procedure:

1. Merge and validate the change in dev.
2. Open a prod promotion pull request changing only prod variables or release metadata.
3. Generate and review the prod Terraform plan.
4. Require manual approval in the GitHub `prod` environment.
5. Apply prod and run Ansible with `environment=prod`.

## Trade-Offs

Single-region, lightweight dev infrastructure keeps the assignment focused and low cost. The design uses two public subnets because ALB expects multiple Availability Zones, but the ASG desired capacity remains one.

Skipping NAT Gateway reduces cost but means hosts cannot freely download packages from the internet. The app deliberately uses Python already available on Amazon Linux and Ansible copies the service files directly. In production, I would use a private artifact repository, VPC endpoints, or controlled NAT egress depending on compliance and operational needs.

The demo stores the secret in a systemd environment file on the instance after Ansible retrieves it. That is acceptable for this exercise, but for stronger production posture I would retrieve the secret at runtime with a short-lived identity path or use a secret delivery mechanism with rotation and tighter audit controls.

## Demo Outline

1. Show repository layout and explain Terraform, Ansible, and CI boundaries.
2. Show the SSM SecureString parameter exists without exposing the value.
3. Run `terraform plan` or show the GitHub PR plan.
4. Show `terraform apply` outputs, especially `health_url`.
5. Run the Ansible playbook.
6. Curl the health endpoint through the ALB.
7. Show CloudWatch alarms and cleanup command.
