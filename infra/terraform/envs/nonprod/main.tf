module "vpc" {
  source = "../../modules/vpc"

  name       = "voting-app-nonprod-vpc"
  cidr_block = "10.0.0.0/16"

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "voting-app-nonprod"
  private_subnets = module.vpc.private_subnets
}

