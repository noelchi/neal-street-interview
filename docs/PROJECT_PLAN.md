# Project Plan

## Phase 1: Foundation

- Extract assignment requirements.
- Choose a low-cost AWS architecture that still satisfies the security and scale constraints.
- Define repository structure for Terraform, Ansible, CI, and documentation.

Status: complete.

## Phase 2: Terraform Dev Web Tier

- Create VPC, public subnets, protected subnets, route tables, and internet gateway.
- Create ALB, target group, and listener.
- Create EC2 launch template and Auto Scaling Group.
- Create security groups with no public ingress to instances.
- Create IAM role, instance profile, SSM endpoints, S3 transfer bucket, and S3 gateway endpoint.
- Add CloudWatch alarms for unhealthy targets and high CPU.
- Output health URL and Ansible SSM bucket name.

Status: complete.

## Phase 3: Ansible Configuration

- Use AWS EC2 dynamic inventory with tag discovery.
- Connect through AWS Systems Manager instead of SSH.
- Install a minimal Python health service managed by systemd.
- Consume `APP_SECRET` from SSM Parameter Store.
- Apply lightweight Linux hardening.

Status: complete.

## Phase 4: CI/CD

- Run Terraform formatting, validation, and plan on pull requests.
- Run Ansible syntax validation on pull requests.
- Apply Terraform to dev through a manual workflow stage.
- Run Ansible through a manual workflow stage after Terraform apply.
- Prevent overlapping dev deployments.

Status: complete.

## Phase 5: Validation And Demo

- Run local formatting and syntax checks where tools are available.
- Document any commands that require AWS credentials and cannot be run offline.
- Record a 5-10 minute walkthrough showing the repository, plan/apply, Ansible run, health endpoint, alarms, and cleanup.

Status: in progress.
