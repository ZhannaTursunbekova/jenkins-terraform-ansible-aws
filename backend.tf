terraform {
  backend "s3" {
    bucket = "ztursunbekova-47475757"
    key    = "terraform.tfstate"
    region = "us-east-2"
  }
}