variable "project_name" {
  type        = string
  description = "Project name for tagging purposes"
  default     = "oci-infra"
}

variable "project_owner" {
  type        = string
  description = "Project owner for tagging purposes"
  default     = "unknown"
}


variable "compartment_name" {
  type        = string
  description = "Compartment name to be created containing all resources"
  default     = "terraform"
}


variable "tenancy_ocid" {
  type        = string
  description = "Tenancy OCID where resources will be created"
}

variable "additional_tags" {
  type        = map(string)
  description = "Additional tags to be added to all resources"
  default     = {}
}

variable "vcn_name" {
  type        = string
  description = "Name of the VCN to be created"
  default     = "vcn"
}

# VCN CIDR block variable
variable "vcn_cidr_block" {
  type = string

  # Ensure that the provided CIDR block is valid.
  validation {
    condition     = can(cidrnetmask(var.vcn_cidr_block))
    error_message = "The provided VCN CIDR block is not valid."
  }
}


# Subnet configuration variable
variable "subnet_config" {
  type = map(object({
    cidr_block      = string
    additional_tags = optional(map(string))
    public_subnet   = bool
  }))
  description = "Subnet configuration"
  # Ensure that all provided CIDR blocks are valid.
  validation {
    condition = alltrue([
      for config in values(var.subnet_config) : can(cidrnetmask(config.cidr_block))
    ])
    error_message = "At least one of the provided CIDR blocks is not valid."
  }
}

# Compute Instances
variable "instances" {
  type = map(object({
    name          = string
    shape         = string
    ocpus         = number
    memory_in_gbs = number
    subnet_type   = string
    ssh_key_path  = string
  }))
  description = "Compute instance configuration"
  validation {
    condition = alltrue([
      for instance in values(var.instances) : contains(local.freetier_shapes, instance.shape)
    ])
    error_message = "Not allowed shape for Always Free resources"
  }
}