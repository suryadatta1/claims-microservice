terraform {
  backend "s3" {
    bucket         = "claims-service-tf-state-surya-dev" # Ensure this matches infra/remote-state/main.tf
    key            = "claims-service/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
