terraform {
  required_version = ">= 1.5.6"

  backend "s3" {
    bucket         = "nti-project-terraform-state"
    key            = "nonprod/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "nti-project-locks"
    encrypt        = true
  }
}

