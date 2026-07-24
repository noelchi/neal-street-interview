# Neal Street Senior Cloud Engineer Assignment

This repository implements a small AWS dev web tier for the `rewards` service.

The solution uses:

- Terraform for AWS infrastructure.
- Ansible for Linux and application configuration.
- GitHub Actions for PR planning and dev rollout.
- AWS Systems Manager Session Manager for private instance access.
- CloudWatch alarms for the mandatory observability path.

## Architecture

Public traffic enters through an internet-facing AWS Application Load Balancer. The EC2 instances run in protected subnets with no public IPs and only accept HTTP traffic from the load balancer security group. An Auto Scaling Group starts with one instance and can be scaled later by changing `desired_capacity`.

Ansible connects to the instances through AWS Systems Manager, so no SSH ingress is required.

The editable architecture diagram is in `docs/architecture.drawio`.

## Prerequisites

- AWS account access with permission to create VPC, EC2, IAM, SSM Parameter Store, ALB, Auto Scaling, and CloudWatch resources.
- Terraform >= 1.10.
- Python 3.11+.
- Ansible with the `amazon.aws` collection.
- AWS Session Manager plugin installed locally for Ansible SSM connections.
- An S3 bucket for remote Terraform state, if using the team backend described in `docs/SOLUTION.md`.

## One-Time Secret Setup

Create the application secret outside the repo before running Ansible:

```bash
aws ssm put-parameter \
  --name /rewards/dev/APP_SECRET \
  --type SecureString \
  --value "$(openssl rand -base64 32)" \
  --overwrite \
  --region af-south-1
```

The value is consumed by Ansible at deploy time and written into the systemd environment for the app. The health endpoint does not expose it.

## Local Dev Deployment

From the repository root:

```bash
cd terraform
cp dev.tfvars.example dev.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=dev.tfvars -out=tfplan
terraform apply tfplan
```

Install Ansible dependencies:

```bash
cd ../ansible
ansible-galaxy collection install -r requirements.yml
```

Run the playbook:

```bash
export ANSIBLE_AWS_SSM_BUCKET_NAME="$(cd ../terraform && terraform output -raw ansible_ssm_bucket_name)"
AWS_REGION=af-south-1 ansible-playbook -i inventory.aws_ec2.yml playbooks/site.yml
```

Get the endpoint:

```bash
cd ../terraform
terraform output -raw health_url
```

Expected response:

```json
{"service":"rewards","status":"ok","commit":"","region":"af-south-1"}
```

## Cleanup

```bash
cd terraform
terraform destroy -var-file=dev.tfvars
```

The SSM parameter is intentionally created outside Terraform. Delete it separately when the demo is complete:

```bash
aws ssm delete-parameter --name /rewards/dev/APP_SECRET --region af-south-1
```

## CI/CD

The GitHub Actions workflow in `.github/workflows/dev.yml` expects:

- `vars.AWS_REGION`, for example `af-south-1`.
- `secrets.DEV_AWS_ROLE_ARN`, an IAM role GitHub can assume through OIDC.

Pull requests run Terraform checks, initialize the checked-in S3 backend, write the dev plan to the workflow summary, and run Ansible syntax validation.

Merges to `main` apply Terraform to dev and then run Ansible against the discovered dev instances. Manual workflow runs are also available for staged operations:

- `plan`: run the same dev plan checks outside a pull request.
- `import-existing`: import deterministic pre-existing dev resources into the S3-backed Terraform state.
- `apply`: apply Terraform to dev.
- `configure`: run Ansible against the discovered dev instances.
