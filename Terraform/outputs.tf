output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.minecraft.id
}

output "public_ip" {
  description = "Elastic IP address of the Minecraft server — use this to connect"
  value       = aws_eip.minecraft.public_ip
}

output "public_dns" {
  description = "Public DNS hostname of the instance"
  value       = aws_eip.minecraft.public_dns
}

output "ami_id" {
  description = "AMI used for the instance"
  value       = data.aws_ami.ubuntu.id
}

output "instance_type" {
  description = "EC2 instance type"
  value       = aws_instance.minecraft.instance_type
}

output "security_group_id" {
  description = "ID of the Minecraft security group"
  value       = aws_security_group.minecraft.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance (for debugging only)"
  value       = "ssh -i ~/.ssh/minecraft_key ubuntu@${aws_eip.minecraft.public_ip}"
}

output "nmap_command" {
  description = "nmap command to verify the Minecraft server is reachable"
  value       = "nmap -sV -Pn -p T:25565 ${aws_eip.minecraft.public_ip}"
}
