
locals {
  freetier_shapes = [
    "VM.Standard.A1.Flex",
    "VM.Standard.E2.1.Micro"
  ]
}

# Source Images (Data Source)
# Source from: https://search.opentofu.org/provider/oracle/oci/latest/docs/data-sources/core_images

data "oci_core_images" "ubuntu_images" {
  #Required
  for_each                 = toset(local.freetier_shapes)
  compartment_id           = oci_identity_compartment.tf-compartment.id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = each.key
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
  state                    = "AVAILABLE"
}

# Output the OCID of the latest Ubuntu image
output "latest_ubuntu_image_arm" {
  value = data.oci_core_images.ubuntu_images["${local.freetier_shapes[0]}"].images[0]
}

output "latest_ubuntu_image_amd" {
  value = data.oci_core_images.ubuntu_images["${local.freetier_shapes[1]}"].images[0]
}


# Compute Instances
# Source from: https://search.opentofu.org/provider/oracle/oci/latest/docs/resources/core_instance

resource "oci_core_instance" "compute_instance" {
  for_each = var.instances
  # Required
  availability_domain = each.value.shape == "VM.Standard.E2.1.Micro" ? data.oci_identity_availability_domains.ads.availability_domains[0].name : data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = oci_identity_compartment.tf-compartment.id
  # Shape
  shape = each.value.shape
  shape_config {
    ocpus         = each.value.ocpus
    memory_in_gbs = each.value.memory_in_gbs
  }
  # Image details
  source_details {
    source_id   = data.oci_core_images.ubuntu_images[each.value.shape].images[0].id
    source_type = "image"
    boot_volume_size_in_gbs =50
  }

  # Optional
  display_name = each.key
  create_vnic_details {
    # Assign a public IP to the instance
    assign_public_ip = true
    subnet_id        = oci_core_subnet.tf-subnets[each.value.subnet_type].id
    hostname_label   = each.key
  }
  metadata = {
    ssh_authorized_keys = file(each.value.ssh_key_path)
  }
  preserve_boot_volume = false

  lifecycle {
    ignore_changes = [
      # Ignore changes to OCI source Image (Prevent updates when a new image is available).
      source_details[0].source_id    ]
  }
}

