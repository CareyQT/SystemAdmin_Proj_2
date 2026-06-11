variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix applied to all resource names and tags"
  type        = string
  default     = "minecraft"
}

variable "instance_type" {
  description = "EC2 instance type. t3.small (2 vCPU, 2 GB) is the recommended minimum for a small server"
  type        = string
  default     = "t3.small"

  validation {
    condition     = contains(["t3.small", "t3.medium", "t3.large", "t3a.small", "t3a.medium"], var.instance_type)
    error_message = "Choose an instance type appropriate for a Minecraft server (t3.small or larger)."
  }
}

variable "root_volume_size_gb" {
  description = "Size in GB of the EC2 root EBS volume (world data is stored here)"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size_gb >= 10
    error_message = "Root volume must be at least 10 GB."
  }
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key to install on the instance (used by Ansible)"
  type        = string
  default     = "~/.ssh/minecraft_key.pub"
}

variable "ssh_allowed_cidr" {
  description = "CIDR block(s) allowed to SSH into the instance. Restrict to your IP for security"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
