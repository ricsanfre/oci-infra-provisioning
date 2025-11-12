terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "7.25.0"
    }
  }
}

provider "oci" {
  region = "eu-frankfurt-1"
}