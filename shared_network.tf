module "shared_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  name                 = "shared-vpc"
  cidr                 = "10.107.0.0/16"
  azs                  = ["ap-northeast-1a", "ap-northeast-1c"]
  private_subnets      = ["10.107.1.0/24", "10.107.2.0/24"]
  public_subnets       = ["10.107.3.0/24", "10.107.4.0/24"]
  enable_nat_gateway   = true
  enable_dns_hostnames = true
}

resource "aws_ec2_transit_gateway" "main" {
  default_route_table_association    = "disable"
  default_route_table_propagation    = "disable"
  auto_accept_shared_attachments     = "enable"
  dns_support = "enable"

  tags = {
    Name = "shared-nat-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "shared" {
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = module.shared_vpc.vpc_id
  subnet_ids                                      = module.shared_vpc.private_subnets
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_route_table_association" "shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_route_table.id
}

################################################################################
# tgwルートテーブル
################################################################################
resource "aws_ec2_transit_gateway_route_table" "shared_route_table" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
}

# shared-vpcのTransit Gatewayルートテーブルからservice1への戻りルート
resource "aws_ec2_transit_gateway_route" "shared_vpc_to_service1_return" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_route_table.id
  destination_cidr_block         = module.service1.vpc_cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.service1.id
}

# shared-vpcのTransit Gatewayルートテーブルからservice2への戻りルート
resource "aws_ec2_transit_gateway_route" "shared_vpc_to_service2_return" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_route_table.id
  destination_cidr_block         = module.service2.vpc_cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.service2.id
}

################################################################################
# shared-vpcルートテーブル
################################################################################
# shared-vpcのpublic subnetのルートテーブルにservice1へのルートを追加
# (NAT Gatewayを含むpublic subnetからservice1へのトラフィックをTransit Gatewayに流す)
resource "aws_route" "shared_vpc_public_to_service1" {
  count =  length(module.shared_vpc.public_route_table_ids)
  route_table_id         = module.shared_vpc.public_route_table_ids[count.index]
  destination_cidr_block = module.service1.vpc_cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}

# shared-vpcのpublic subnetのルートテーブルにservice2へのルートを追加
# (NAT Gatewayを含む public subnetからservice2へのトラフィックをTransit Gatewayに流す)
resource "aws_route" "shared_vpc_public_to_service2" {
  count =  length(module.shared_vpc.public_route_table_ids)
  route_table_id         = module.shared_vpc.public_route_table_ids[count.index]
  destination_cidr_block = module.service2.vpc_cidr_block
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}
