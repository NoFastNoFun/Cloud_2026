terraform {
  backend "s3" {
    bucket         = "nf2-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "nf2-terraform-lock"
    encrypt        = true
  }
}
