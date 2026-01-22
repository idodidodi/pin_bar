provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "ansible_key" {
  key_name   = "ansible-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "win_sg" {
  name = "windows-ansible-sg"

  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "WinRM for Ansible"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "local_file" "inventory" {
  content = templatefile("${path.module}/../ansible-setup/inventory.tpl", {
    public_ip = aws_instance.windows.public_ip
    password  = aws_instance.windows.password_data
  })
  filename = "${path.module}/../ansible-setup/inventory.ini"
}

resource "aws_instance" "windows" {
  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.ansible_key.key_name
  vpc_security_group_ids = [aws_security_group.win_sg.id]
  get_password_data      = true

  user_data = <<EOF
<powershell>
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="false"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow
</powershell>
EOF

  tags = {
    Name = "windows-for-ansible"
  }
}
