# service1のインスタンスからservice2の接続テスト
resource "aws_ec2_network_insights_path" "service1_to_service2_path" {
  source      = module.service1_instance.id
  destination = module.service2_instance.primary_network_interface_id
  protocol = "tcp"

  tags = {
    Name = "service1-to-service2-path"
  }
}


# service1のインスタンスからshared-vpcのigwへの接続テスト
resource "aws_ec2_network_insights_path" "service1_to_shared_vpc_internetgateway_path" {
  source      = module.service1_instance.id
  destination = module.shared_vpc.igw_id
  protocol = "tcp"

  tags = {
    Name = "service1-to-shared-vpc-internetgateway-path"
  }
}