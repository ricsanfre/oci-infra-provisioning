# Compartment Resource
# Source From: https://search.opentofu.org/provider/oracle/oci/latest/docs/resources/identity_compartment
# Important: Unless enable_delete is explicitly set to true, Terraform will not delete compartments on destroy

resource "oci_identity_compartment" "tf-compartment" {
  # Required
  compartment_id = var.tenancy_ocid
  description    = "Compartment created with Terraform"
  name           = var.compartment_name
  freeform_tags  = merge(local.common_tags, var.additional_tags)
}

# Outputs for compartment
output "compartment-name" {
  value = oci_identity_compartment.tf-compartment.name
}

output "compartment-OCID" {
  value = oci_identity_compartment.tf-compartment.id
}