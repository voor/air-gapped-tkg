data "aws_iam_policy_document" "packer" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CopyImage",
      "ec2:CreateImage",
      "ec2:CreateKeypair",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteKeyPair",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSnapshot",
      "ec2:DeleteVolume",
      "ec2:DeregisterImage",
      "ec2:DescribeImageAttribute",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume",
      "ec2:GetPasswordData",
      "ec2:ModifyImageAttribute",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifySnapshotAttribute",
      "ec2:RegisterImage",
      "ec2:RunInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "s3:GetEncryptionConfiguration"
    ]
    resources = [
      "*"
    ]
    effect = "Allow"

  }

  statement {
    actions = [
      "s3:*"
    ]
    resources = [
      "*"
    ]
    effect = "Allow"

  }
}

resource "aws_iam_policy" "packer" {
  name   = "packer.image-builder.sigs.k8s.io"
  policy = data.aws_iam_policy_document.packer.json
}

resource "aws_iam_role" "packer" {
  name = "packer.image-builder.sigs.k8s.io"

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "packer-packer" {
  role       = aws_iam_role.packer.name
  policy_arn = aws_iam_policy.packer.arn
}

resource "aws_iam_instance_profile" "packer" {
  name = "packer.image-builder.sigs.k8s.io"
  role = aws_iam_role.packer.name

  lifecycle {
    ignore_changes = [name]
  }
}
