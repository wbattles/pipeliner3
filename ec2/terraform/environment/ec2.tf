terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

resource "aws_security_group" "public_traffic" {
  name_prefix = "EC2-Public-SecGrp-"
  description = "Allow inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "EC2-Public-SecGrp"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web" {
  security_group_id = aws_security_group.public_traffic.id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.public_traffic.id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
}

resource "aws_vpc_security_group_egress_rule" "web" {
  security_group_id = aws_security_group.public_traffic.id
  cidr_ipv4         = "0.0.0.0/0"

  ip_protocol = -1
  from_port   = -1
  to_port     = -1
}


resource "aws_iam_role" "ec2_role" {
  name = "ec2-secrets-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_access_policy" {
  name_prefix = "ec2-access-policy-"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssm:ListInstanceAssociations",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetParameter*",
          "ssm:StartSession",
          "ssm:DescribeParameters",
          "ssmmessages:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Add AWS SSM Managed Policy for Amazon EC2 Role
resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_access_policy.arn
}
  
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name_prefix = "ec2_instance_profile-"
  role = aws_iam_role.ec2_role.name
}


resource "aws_eip" "instance_eip" {
  instance = aws_instance.this.id
}

resource "aws_instance" "this" {
  instance_type = var.instance_type
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [aws_security_group.public_traffic.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  key_name = var.key_name
  
  dynamic "launch_template" {
    for_each = var.launch_template_id != null ? [1] : []
    content {
      id      = var.launch_template_id
    }
  }

  ami       = var.launch_template_id != null ? null: var.ami_id
  user_data = var.launch_template_id != null ? null: <<-EOF
    #!/bin/bash

    sudo apt-get update

    sudo apt-get install docker.io -y
    sudo systemctl start docker

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt-get install -y unzip
    unzip -o -q awscliv2.zip
    sudo ./aws/install --update

    sudo apt-get install -y snapd unzip
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOF

  tags = {
    Name = var.instance_name
  }
}
