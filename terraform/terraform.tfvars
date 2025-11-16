compartment_name = "terraform"

vcn_name       = "vcn"
vcn_cidr_block = "10.0.0.0/16"

subnet_config = {
  public = {
    cidr_block    = "10.0.0.0/24"
    public_subnet = true
    additional_tags = {
      Public = "True"
    }
  }
}
#   private = {
#     cidr_block = "10.1.1.0/24"
#     public_subnet = false
#     additional_tags = {
#       Public = "False"
#     }
#   }
instances = {
  oci-arm-1 = {
    name          = "oci-arm-1"
    shape         = "VM.Standard.A1.Flex"
    ocpus         = 2
    memory_in_gbs = 12
    subnet_type   = "public"
    ssh_key_path  = "~/.ssh/id_rsa.pub"
  }
  oci-amd-1 = {
    name          = "oci-amd-1"
    shape         = "VM.Standard.E2.1.Micro"
    ocpus         = 1
    memory_in_gbs = 1
    subnet_type   = "public"
    ssh_key_path  = "~/.ssh/id_rsa.pub"
  }
  oci-amd-2 = {
    name          = "oci-amd-2"
    shape         = "VM.Standard.E2.1.Micro"
    ocpus         = 1
    memory_in_gbs = 1
    subnet_type   = "public"
    ssh_key_path  = "~/.ssh/id_rsa.pub"
  }
}