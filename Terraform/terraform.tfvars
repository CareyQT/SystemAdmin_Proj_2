# Copy this file to terraform.tfvars and fill in your values.
# terraform.tfvars is gitignored — never commit credentials or personal paths.

aws_region          = "us-east-1"
project_name        = "minecraft"
instance_type       = "t3.small"
root_volume_size_gb = 20
ssh_public_key_path = "/home/quinn_t/.ssh/minecraft_key.pub"

ssh_allowed_cidr = ["0.0.0.0/0"]
