provider "aws" {
  default_tags {
    tags = {
      description = "aws_community_day_demo_2021"
      webinar     = "5_pilares_WA"
      # date = "28_10_2021"

    }
  }
}

terraform {
  required_version = ">= 0.13"

  backend "s3" {
    bucket = "willoverwritten"
    key    = "willoverwritten"


    encrypt = true

  }
}