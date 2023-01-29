resource "oci_core_virtual_network" "vcn" {
  cidr_block     = "10.1.0.0/16"
  is_ipv6enabled = true
  compartment_id = var.compartment_ocid
}

locals {
  ipv6_cidr_block    = oci_core_virtual_network.vcn.ipv6cidr_blocks[0] // this ends in 0::/56
  ipv6_cidr_prefix   = substr(local.ipv6_cidr_block, 0, length(local.ipv6_cidr_block) - 6)
  ipv6_public_subnet = "${local.ipv6_cidr_prefix}0::/64"
}

resource "oci_core_subnet" "main_subnet" {
  cidr_block        = "10.1.0.0/24"
  ipv6cidr_block    = local.ipv6_public_subnet
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_virtual_network.vcn.id
  security_list_ids = [oci_core_security_list.security_list.id]
  route_table_id    = oci_core_route_table.main_route_table.id
  dhcp_options_id   = oci_core_virtual_network.vcn.default_dhcp_options_id
}

resource "oci_core_internet_gateway" "internet_gateway" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
}

resource "oci_core_route_table" "main_route_table" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id

  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.internet_gateway.id
  }
}

resource "oci_core_security_list" "security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id

  egress_security_rules {
    protocol    = "all"
    destination = "::/0"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # SSH

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "::/0"

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Kubernetes API

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "::/0"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  # HTTP

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "::/0"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 80
      max = 80
    }
  }

  # HTTPS

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "::/0"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }

  # NodePort

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "::/0"

    tcp_options {
      min = 30000
      max = 32767
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"

    tcp_options {
      min = 30000
      max = 32767
    }
  }
}
