variable "aws_region" {
  description = "AWS region for the dev environment."
  type        = string
  default     = "af-south-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "service" {
  description = "Service name."
  type        = string
  default     = "rewards"
}

variable "owner" {
  description = "Resource owner tag."
  type        = string
  default     = "candidate"
}

variable "cost_center" {
  description = "Cost center tag."
  type        = string
  default     = "payments"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.40.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public ALB subnets."
  type        = list(string)
  default     = ["10.40.0.0/24", "10.40.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for protected EC2 subnets."
  type        = list(string)
  default     = ["10.40.10.0/24", "10.40.11.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type for the web tier."
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Desired number of web instances."
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of web instances."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of web instances."
  type        = number
  default     = 2
}

variable "app_port" {
  description = "Port where the rewards app listens on each instance."
  type        = number
  default     = 8080
}

variable "app_secret_parameter_name" {
  description = "SSM SecureString parameter containing APP_SECRET."
  type        = string
  default     = "/rewards/dev/APP_SECRET"
}

variable "allowed_health_cidr_blocks" {
  description = "CIDR ranges allowed to call the public ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
