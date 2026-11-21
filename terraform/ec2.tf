data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_ssm_parameter" "ubuntu2404_ami" {
  name = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

locals {
  instances = {
    "sbom-al2023-php84-vuln" = {
      ami       = data.aws_ssm_parameter.al2023_ami.value
      user_data = <<-EOT
        #!/bin/bash
        set -euxo pipefail
        dnf install -y php8.4-cli-${var.al2023_php84_version}
      EOT
    }
    "sbom-ubuntu2404-php83-backport" = {
      ami       = data.aws_ssm_parameter.ubuntu2404_ami.value
      user_data = <<-EOT
        #!/bin/bash
        set -euxo pipefail
        apt-get -o DPkg::Lock::Timeout=300 update
        DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 install -y php8.3-cli
      EOT
    }
    "sbom-al2023-nophp" = {
      ami       = data.aws_ssm_parameter.al2023_ami.value
      user_data = null
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${var.name_prefix}-ec2"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.name_prefix}-ec2"
  role = aws_iam_role.ec2.name
}

resource "aws_instance" "this" {
  for_each = local.instances

  ami                         = each.value.ami
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  user_data                   = each.value.user_data
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = each.key
  }

  lifecycle {
    ignore_changes = [ami]
  }

  depends_on = [
    aws_inspector2_enabler.this,
    aws_vpc_security_group_egress_rule.ec2_all,
    aws_route_table_association.public,
  ]
}
