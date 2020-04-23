resource "aws_iam_role" "control-plane" {
  name = "control-plane.cluster-api-provider-aws.sigs.k8s.io"

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "control-plane-control-plane" {
  role       = aws_iam_role.control-plane.name
  policy_arn = aws_iam_policy.control-plane.arn
}

resource "aws_iam_role_policy_attachment" "control-plane-controllers" {
  role       = aws_iam_role.control-plane.name
  policy_arn = aws_iam_policy.controllers.arn
}

resource "aws_iam_role_policy_attachment" "control-plane-nodes" {
  role       = aws_iam_role.control-plane.name
  policy_arn = aws_iam_policy.nodes.arn
}

resource "aws_iam_instance_profile" "control-plane" {
  name = "control-plane.cluster-api-provider-aws.sigs.k8s.io"
  role = aws_iam_role.control-plane.name

}

resource "aws_iam_role" "controllers" {
  name = "controllers.cluster-api-provider-aws.sigs.k8s.io"

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "controllers-controllers" {
  role       = aws_iam_role.controllers.name
  policy_arn = aws_iam_policy.controllers.arn
}


resource "aws_iam_instance_profile" "controllers" {
  name = "controllers.cluster-api-provider-aws.sigs.k8s.io"
  role = aws_iam_role.controllers.name

}

resource "aws_iam_role" "nodes" {
  name = "nodes.cluster-api-provider-aws.sigs.k8s.io"

  lifecycle {
    create_before_destroy = true
  }

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "nodes-nodes" {
  role       = aws_iam_role.nodes.name
  policy_arn = aws_iam_policy.nodes.arn
}


resource "aws_iam_instance_profile" "nodes" {
  name = "nodes.cluster-api-provider-aws.sigs.k8s.io"
  role = aws_iam_role.nodes.name

}
