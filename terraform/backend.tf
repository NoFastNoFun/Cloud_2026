terraform {
  backend "s3" {
    bucket         = "[to-rename-bucket]"
    key            = "[to-rename-key]"
    region         = "eu-west-1" 
    dynamodb_table = "[to-rename-dynamodb-table]"
    encrypt        = true
  }
}
