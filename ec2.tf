module "service1_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.1"
  name                 = "service1-instance"
  ami                  = "ami-0599b6e53ca798bb2"  
  instance_type        = "t2.micro"
  vpc_security_group_ids = [module.service1_instance_sg.security_group_id]
  subnet_id            = module.service1.private_subnets[0]
  create_iam_instance_profile = true
  iam_role_policies = { 
    SSMAccess =  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    S3FAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  }
}

module "service1_instance_sg" {
  source          = "terraform-aws-modules/security-group/aws"
  version         = "v5.1.0"
  name            = "service1-instance-sg"
  use_name_prefix = false
  vpc_id          = module.service1.vpc_id
  description     = "Managed by Terraform"
  egress_rules = ["all-all"]
}

output "instance1_id" {
  value = module.service1_instance.id
}


module "service2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.1"
  name                 = "service2-instance"
  ami                  = "ami-0599b6e53ca798bb2"  
  instance_type        = "t2.micro"
  vpc_security_group_ids = [module.service2_instance_sg.security_group_id]
  subnet_id            = module.service2.private_subnets[0]
  create_iam_instance_profile = true
}

module "service2_instance_sg" {
  source          = "terraform-aws-modules/security-group/aws"
  version         = "v5.1.0"
  name            = "service2-instance-sg"
  use_name_prefix = false
  vpc_id          = module.service2.vpc_id
  description     = "Managed by Terraform"
  egress_rules = ["all-all"]
  ingress_cidr_blocks      = ["0.0.0.0/0"]
  ingress_rules    = ["https-443-tcp"]
}

output "instance2_id" {
  value = module.service2_instance.id
}

