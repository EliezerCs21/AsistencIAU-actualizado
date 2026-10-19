data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_key_pair" "app" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.public_key_path)
}

# IP fija para el frontend
resource "aws_eip" "frontend" {
  domain = "vpc"
}

# ---------- Security Groups ----------
resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend-sg"
  description = "HTTP para todos, SSH solo desde mi IP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg"
  description = "HTTP solo desde el frontend, SSH solo desde mi IP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP solo desde el frontend"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ---------- VM 2: backend ----------
resource "aws_instance" "backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.app.key_name
  vpc_security_group_ids = [aws_security_group.backend.id]

  user_data = templatefile("${path.module}/user_data_backend.sh", {
    repo_url       = var.repo_url
    db_password    = var.db_password
    admin_password = var.admin_password
    frontend_ip    = aws_eip.frontend.public_ip
    session_secure = var.session_secure
  })
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-backend"
  }
}

# ---------- VM 1: frontend ----------
resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.app.key_name
  vpc_security_group_ids = [aws_security_group.frontend.id]

  user_data = templatefile("${path.module}/user_data_frontend.sh", {
    repo_url   = var.repo_url
    backend_ip = aws_instance.backend.private_ip
    public_ip  = aws_eip.frontend.public_ip
  })
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-frontend"
  }
}

resource "aws_eip_association" "frontend" {
  instance_id   = aws_instance.frontend.id
  allocation_id = aws_eip.frontend.id
}