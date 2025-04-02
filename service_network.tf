module "service1" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  name                 = "service1"
  cidr                 = "10.105.0.0/16"
  azs                  = ["ap-northeast-1a", "ap-northeast-1c"]
  private_subnets      = ["10.105.1.0/24", "10.105.2.0/24"]
  public_subnets       = ["10.105.3.0/24", "10.105.4.0/24"]
  enable_nat_gateway   = false
  enable_dns_hostnames = true
}

module "service2" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  name                 = "service2"
  cidr                 = "10.106.0.0/16"
  azs                  = ["ap-northeast-1a", "ap-northeast-1c"]
  private_subnets      = ["10.106.1.0/24", "10.106.2.0/24"]
  public_subnets       = ["10.106.3.0/24", "10.106.4.0/24"]
  enable_nat_gateway   = false
  enable_dns_hostnames = true
}

################################################################################
# tgw attachment
################################################################################
resource "aws_ec2_transit_gateway_vpc_attachment" "service1" {
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = module.service1.vpc_id
  subnet_ids                                      = module.service1.private_subnets
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "service2" {
  transit_gateway_id                              = aws_ec2_transit_gateway.main.id
  vpc_id                                          = module.service2.vpc_id
  subnet_ids                                      = module.service2.private_subnets
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
}

resource "aws_ec2_transit_gateway_route_table_association" "service1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.service1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.service.id
}

resource "aws_ec2_transit_gateway_route_table_association" "service2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.service2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.service.id
}

################################################################################
# tgwルートテーブル
################################################################################

resource "aws_ec2_transit_gateway_route_table" "service" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
}

# アウトバウンドトラフィックをshared-vpcに流す
resource "aws_ec2_transit_gateway_route" "service_last_resort" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.service.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.shared.id
}

# service間のルートをブロックする
resource "aws_ec2_transit_gateway_route" "block_inter_services" {
  for_each = toset([module.service1.vpc_cidr_block, module.service2.vpc_cidr_block])
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.service.id
  destination_cidr_block = each.key
  blackhole = true
}

################################################################################
# serviceのルートテーブル
################################################################################
# private subnetのアウトバウンドトラフィックをtgwに流す
resource "aws_route" "service1_to_tgw" {
  count = length(module.service1.private_route_table_ids)
  route_table_id         = module.service1.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}
# private subnetのアウトバウンドトラフィックをtgwに流す
resource "aws_route" "service2_to_tgw" {
  count = length(module.service2.private_route_table_ids)
  route_table_id         = module.service2.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.main.id
}
