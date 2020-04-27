
resource "aws_vpc_endpoint" "ec2" {

  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "elasticloadbalancing" {

  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.elasticloadbalancing"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "secretsmanager" {

  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}


resource "aws_vpc_endpoint" "ec2messages" {

  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "ssm" {

  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "ssmmessages" {

  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "sts" {

  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "ecr_dkr" {

  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "ecr_api" {

  vpc_id              = data.aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnet.*.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.infrastructure_security_group.id]
}

resource "aws_vpc_endpoint" "s3" {

  vpc_id            = data.aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  # policy = data.aws_iam_policy_document.cds-endpoint-policy.json
}

resource "aws_main_route_table_association" "main_route_table_association" {
  vpc_id         = data.aws_vpc.vpc.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_main_route_table_association" {
  route_table_id  = aws_route_table.main_route_table.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_route_table" "main_route_table" {
  vpc_id = data.aws_vpc.vpc.id
}