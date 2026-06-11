# Minecraft Server on AWS
 
Automated provisioning and configuration of a Minecraft 1.21.1 server on AWS EC2 using Terraform and Ansible. Running the single orchestrator script provisions all infrastructure, configures the server, and starts Minecraft — no manual steps required.
 
---
 
## Background
 
### What we are doing
 
This project deploys a Minecraft Java Edition server to AWS EC2 fully automatically. A single script (`scripts/run.sh`) handles the entire pipeline:
 
1. **Terraform** provisions the AWS infrastructure — VPC, subnet, security group, EC2 instance, and an Elastic IP so the server address stays stable across reboots.
2. **Ansible** connects to the new instance over SSH and configures it — installing Java, downloading the Minecraft server jar, and setting up a `systemd` service that starts Minecraft automatically and restarts it cleanly on reboot.
### How it works
 
Terraform and Ansible are complementary tools. Terraform is responsible for creating and managing cloud resources (the *infrastructure*). Ansible is responsible for configuring the software running on those resources (the *configuration*). Together they ensure the server can be recreated identically at any time from a single command.
 
The Minecraft server runs as a `systemd` service under a dedicated `minecraft` system user. Systemd handles auto-start on boot and clean shutdown — sending `SIGTERM` to the Java process so the world is saved before the instance stops.
 
---
 
## Pipeline diagram
 
```
Local machine
     │
     ▼
┌─────────────┐     ┌──────────────────────────────────────────┐
│  run.sh     │────▶│  Terraform                               │
│             │     │  VPC, subnet, IGW, security group,       │
│             │     │  EC2 (Ubuntu 22.04), Elastic IP          │
└─────────────┘     └───────────────────┬──────────────────────┘
                                        │ public IP
                                        ▼
                    ┌──────────────────────────────────────────┐
                    │  Ansible                                 │
                    │  Install Java 21, download server.jar,  │
                    │  write systemd unit, start service       │
                    └───────────────────┬──────────────────────┘
                                        │
                                        ▼
                    ┌──────────────────────────────────────────┐
                    │  Minecraft 1.21.1                        │
                    │  Listening on port 25565                 │
                    └──────────────────────────────────────────┘
```
 
---
 
## Requirements
 
### Tools
 
| Tool | Version | Install |
|---|---|---|
| Terraform | >= 1.5.0 | [developer.hashicorp.com/terraform/downloads](https://developer.hashicorp.com/terraform/downloads) |
| Ansible | >= 2.14 | `pip install ansible` or `sudo apt install ansible` |
| AWS CLI | >= 2.0 | [docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| nmap | any | `sudo apt install nmap` |
 
> **Windows users:** Ansible does not run natively on Windows. Use [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) (Ubuntu) to run all commands in this guide.
 
### AWS credentials
 
This project is designed for use with an **AWS Learner Lab**. Retrieve your credentials from the Learner Lab portal:
 
1. Open your Learner Lab and click **AWS Details**
2. Click **Show** next to AWS CLI
3. Paste the three exported values into `~/.aws/credentials`:
```ini
[default]
aws_access_key_id=YOUR_KEY_ID
aws_secret_access_key=YOUR_SECRET_KEY
aws_session_token=YOUR_SESSION_TOKEN
```
 
> Learner Lab credentials expire when your session ends. Refresh this file at the start of each session.
 
### SSH key pair
 
Generate an SSH key pair for Ansible to connect to the EC2 instance:
 
```bash
ssh-keygen -t ed25519 -f ~/.ssh/minecraft_key -N ""
```
 
This creates `~/.ssh/minecraft_key` (private) and `~/.ssh/minecraft_key.pub` (public). The public key is uploaded to AWS by Terraform.
 
### Configuration
 
Copy the example variables file and edit it if needed:
 
```bash
cd Terraform
cp terraform.tfvars.example terraform.tfvars
```
 
The defaults work out of the box. The only value you may need to change is `ssh_public_key_path` if your key is in a different location:
 
| Variable | Default | Description |
|---|---|---|
| `aws_region` | `us-east-1` | AWS region to deploy into |
| `instance_type` | `t3.small` | EC2 instance size |
| `root_volume_size_gb` | `20` | Disk size in GB |
| `ssh_public_key_path` | `~/.ssh/minecraft_key.pub` | Path to your SSH public key |
| `ssh_allowed_cidr` | `0.0.0.0/0` | IPs allowed to SSH in |
 
---
 
## Running the pipeline
 
### 1. Clone the repository
 
```bash
git clone https://github.com/CareyQT/SystemAdmin_Proj_2.git
cd SystemAdmin_Proj_2
```
 
### 2. Set up credentials and SSH key
 
Configure `~/.aws/credentials` as described above, then generate your SSH key:
 
```bash
ssh-keygen -t ed25519 -f ~/.ssh/minecraft_key -N ""
```
 
### 3. Make the script executable
 
```bash
chmod +x scripts/run.sh
```
 
### 4. Run the pipeline
 
```bash
./scripts/run.sh
```
 
The script will:
- Verify all dependencies and AWS credentials
- Run `terraform init` and `terraform apply` to provision AWS resources
- Wait for the EC2 instance to finish booting
- Run the Ansible playbook to install and configure the server
- Run `nmap` to confirm the server is reachable
The full pipeline takes approximately 3–5 minutes.
 
### 5. Tear down
 
To destroy all AWS resources when you are done:
 
```bash
cd Terraform
terraform destroy
```
 
---
 
## Connecting to the Minecraft server
 
Once the pipeline completes, the server's IP address is printed to the terminal. You can also retrieve it at any time with:
 
```bash
cd Terraform
terraform output public_ip
```
 
### Verify the server is reachable
 
```bash
nmap -sV -Pn -p T:25565 <instance_public_ip>
```
 
A successful response looks like:
 
```
PORT      STATE SERVICE   VERSION
25565/tcp open  minecraft Minecraft 1.21.1
```
 
### Connect in Minecraft
 
1. Open Minecraft Java Edition
2. Click **Multiplayer** → **Add Server**
3. Enter the public IP address as the server address
4. Click **Done**, then join the server
---
 
## Repository structure
 
```
.
├── Terraform/
│   ├── main.tf                    # VPC, EC2, security group, Elastic IP
│   ├── variables.tf               # All configurable variables
│   ├── outputs.tf                 # Outputs including public IP and nmap command
│   └── terraform.tfvars.example   # Example configuration file
├── ansible/
│   ├── playbook.yml               # Installs Java, downloads server jar, sets up systemd
│   └── templates/
│       └── minecraft.service.j2   # systemd service unit template
├── scripts/
│   └── run.sh                     # End-to-end orchestrator script
└── README.md
```
 
---