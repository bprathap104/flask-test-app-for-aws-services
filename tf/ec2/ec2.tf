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

resource "aws_iam_role_policy_attachment" "ssm_managed_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm-profile"
  role = aws_iam_role.ssm_role.name
}