# Create a VCN in the compartment created earlier.
# Source from https://search.opentofu.org/provider/oracle/oci/latest/docs/resources/core_vcn

resource "oci_core_vcn" "tf-vcn" {
  cidr_block     = var.vcn_cidr_block
  compartment_id = oci_identity_compartment.tf-compartment.id
  display_name   = var.vcn_name
  dns_label      = var.vcn_name
  freeform_tags  = merge(local.common_tags, var.additional_tags)
}

# Internet Gateway
# Source from https://search.opentofu.org/provider/oracle/oci/latest/docs/resources/core_internet_gateway
resource "oci_core_internet_gateway" "tf-igw" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  display_name   = "igw"
  vcn_id         = oci_core_vcn.tf-vcn.id
  freeform_tags  = merge(local.common_tags, var.additional_tags)
}

# NAT Gateway - Cannot be created in Free Tier (Always Free) accounts.
# Source from https://search.opentofu.org/provider/oracle/oci/latest/docs/resources/core_nat_gateway

# resource "oci_core_nat_gateway" "tf-nat-gw" {
#   block_traffic  = "false"
#   compartment_id = oci_identity_compartment.tf-compartment.id
#   display_name   = "tf-nat-gw"
#   freeform_tags  = merge(local.common_tags, var.additional_tags)
#   vcn_id         = oci_core_vcn.tf-vcn.id
# }

# Create subnets based on the provided subnet configuration.
# Source from  https://search.opentofu.org/provider/oracle/oci/latest/docs/resources/core_subnet
resource "oci_core_subnet" "tf-subnets" {
  for_each       = var.subnet_config
  cidr_block     = each.value.cidr_block
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_vcn.tf-vcn.id
  display_name   = "subnet-${each.key}"
  dns_label      = each.key
  route_table_id = oci_core_route_table.tf-subnet-rt[each.key].id
  security_list_ids = [
    oci_core_security_list.tf-security-lists[each.key].id
  ]
  freeform_tags = merge(local.common_tags, var.additional_tags, each.value.additional_tags)
}


# Public Subnet - Route Table
# Source from https://search.opentofu.org/provider/oracle/oci/latest/docs/resources/core_route_table
resource "oci_core_route_table" "tf-subnet-rt" {
  for_each       = var.subnet_config
  compartment_id = oci_identity_compartment.tf-compartment.id
  display_name   = "rt-${each.key}-subnet"
  vcn_id         = oci_core_vcn.tf-vcn.id
  route_rules {
    description      = "Deafault route to Gateway"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    # network_entity_id = each.value.public_subnet ? oci_core_internet_gateway.tf-igw.id: oci_core_nat_gateway.tf-nat-gw.id
    network_entity_id = oci_core_internet_gateway.tf-igw.id
    route_type        = "STATIC"
  }
  freeform_tags = merge(local.common_tags, var.additional_tags, each.value.additional_tags)
}
resource "oci_core_security_list" "tf-security-lists" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_vcn.tf-vcn.id
  for_each       = var.subnet_config
  display_name   = "security-list-${each.key}-subnet"
  freeform_tags  = merge(local.common_tags, each.value.additional_tags)
  egress_security_rules {
    description      = "All egress traffic allowed"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
    stateless        = "false"
  }

  ingress_security_rules {
    description = "Allowing SSH incoming traffic"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    description = "Disabling ICMP from any network"
    icmp_options {
      code = "4"
      type = "3"
    }
    protocol    = "1"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }
  # ingress_security_rules {
  #   description = "Enabling ICMP traffic from private network"
  #   icmp_options {
  #     code = "-1"
  #     type = "3"
  #   }
  #   protocol    = "1"
  #   source      = "10.0.0.0/16"
  #   source_type = "CIDR_BLOCK"
  #   stateless   = "false"
  # }

  ingress_security_rules {
    description = "Allowing all protocols from VCN subnet"
    protocol    = "all"
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    stateless   = "false"
  }


  ingress_security_rules {
    description = "Allowing HTTPS incoming traffic from any network"
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = "true"
    tcp_options {
      max = "443"
      min = "443"
    }
  }
}

# Reserve Public IP address
# Source from https://search.opentofu.org/provider/oracle/oci/latest/docs/resources/core_public_ip

resource "oci_core_public_ip" "reserved_public_ip" {
  #Required
  compartment_id = oci_identity_compartment.tf-compartment.id
  lifetime       = "RESERVED"
  display_name   = "tf-rt-public-reserved-ip"
  freeform_tags  = merge(local.common_tags, var.additional_tags)

}

output "reserved-public-ip" {
  value = oci_core_public_ip.reserved_public_ip.ip_address

}