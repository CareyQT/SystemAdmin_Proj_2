#!/bin/bash
# run.sh — provisions and configures the Minecraft server end to end.
# Usage: ./scripts/run.sh

set -e  # exit immediately if any command fails


NC='\033[0m' # no colour
 
log()  { echo -e "${NC}[+]${NC} $1"; }
warn() { echo -e "${NC}[!]${NC} $1"; }
fail() { echo -e "${NC}[x]${NC} $1"; exit 1; }

log "Checking dependencies..."
command -v terraform >/dev/null 2>&1 || fail "terraform is not installed"
command -v ansible-playbook >/dev/null 2>&1 || fail "ansible is not installed"
command -v aws >/dev/null 2>&1 || fail "aws cli is not installed"
command -v nmap >/dev/null 2>&1 || warn "nmap is not installed — skipping final verification"

# Check Aws Cred
log "Verifying AWS credentials..."
aws sts get-caller-identity >/dev/null 2>&1 || fail "AWS credentials are not configured. Set them in ~/.aws/credentials"

#Terraform
log "Initialising Terraform..."
cd "$(dirname "$0")/../Terraform"
terraform init -upgrade

log "Planning infrastructure..."
#Use terraform plan to check for any issues before applying
terraform plan

log "Applying infrastructure "
terraform apply -auto-approve

# Grab the server IP from Terraform output
SERVER_IP=$(terraform output -raw public_ip)
log "EC2 instance provisioned at $SERVER_IP"

# Wait for SSH to become available
log "Waiting for SSH to become available..."
RETRIES=15
for i in $(seq 1 $RETRIES); do
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
    -i ~/.ssh/minecraft_key ubuntu@"$SERVER_IP" exit 2>/dev/null; then
    log "SSH is ready"
    break
  fi
  if [ "$i" -eq "$RETRIES" ]; then
    fail "SSH did not become available after $RETRIES attempts"
  fi
  warn "SSH not ready yet, retrying in 10s... ($i/$RETRIES)"
  sleep 10
done

# Run the yml scriptof Tasks 
log "Running Ansible playbook..."
cd "../ansible"
ansible-playbook \
  -i "$SERVER_IP," \
  --private-key ~/.ssh/minecraft_key \
  -u ubuntu \
  playbook.yml

# Use nmap to check if the Minecraft port is open afer waiting
log "Waiting 30 seconds for Minecraft to finish starting up..."
sleep 30

if command -v nmap >/dev/null 2>&1; then
  log "Verifying Minecraft server is reachable..."
  nmap -sV -Pn -p T:25565 "$SERVER_IP"
else
  warn "nmap not found — verify manually with:"
  echo "  nmap -sV -Pn -p T:25565 $SERVER_IP"
fi

echo ""
log "Done! Your Minecraft server is running at $SERVER_IP:25565"
log "Connect in Minecraft using server address: $SERVER_IP"