provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro" # Burstable instance type

  user_data = file("user-data.sh")
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids = [data.aws_security_group.web_server_sg.id]

  tags = {
    Name = "Example Instance (Ubuntu)"
  }
}

resource "aws_iam_role" "ssm_role" {
  name               = "ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ssm_assume_role_policy.json
}

data "aws_iam_policy_document" "ssm_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_caller_identity" "current" {}
resource "aws_iam_role_policy_attachment" "ssm_managed_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "ssm_parameter_store_read_policy" {
  name        = "SSMParameterStoreReadPolicy"
  description = "Policy to allow reading from AWS Systems Manager Parameter Store"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssm_custom_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/SSMParameterStoreReadPolicy"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm-profile"
  role = aws_iam_role.ssm_role.name
}

data "aws_security_group" "web_server_sg" {
  filter {
    name   = "group-name"
    values = ["web-server-sg*"]
  }
}
