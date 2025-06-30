terraform {
  required_providers {
    alicloud = {
      source = "aliyun/alicloud"
      version = "1.244.0"
    }
  }
}

provider "alicloud" {
  access_key = "xxxx"
  secret_key = "xxxx"
  region     = "me-central-1"
}
