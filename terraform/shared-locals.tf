locals {
  managed_by = "Terraform"
}

locals {
  common_tags = {
    project       = var.project_name
    project_owner = var.project_owner
    managed_by    = local.managed_by
  }
}

