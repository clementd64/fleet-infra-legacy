data "oci_core_images" "ubuntu" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
}

resource "oci_core_instance" "node" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = var.compartment_ocid
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.main_subnet.id
    assign_public_ip       = false
    private_ip             = "10.1.0.10"
    skip_source_dest_check = true
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0]["id"]
    boot_volume_size_in_gbs = "100"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_key
  }

  lifecycle {
    ignore_changes = [
      metadata,
      source_details[0].source_id,
    ]
  }
}

data "oci_core_vnic_attachments" "node" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
  instance_id         = oci_core_instance.node.id
}

data "oci_core_private_ips" "node" {
  ip_address = oci_core_instance.node.private_ip
  subnet_id  = oci_core_subnet.main_subnet.id
}

resource "oci_core_ipv6" "node" {
  vnic_id    = data.oci_core_vnic_attachments.node.vnic_attachments[0]["vnic_id"]
  ip_address = "${local.ipv6_cidr_prefix}0::cafe"
}

resource "oci_core_public_ip" "node" {
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"

  # Swap the two value before deleting the instance
  private_ip_id = data.oci_core_private_ips.node.private_ips[0]["id"]
  #private_ip_id = ""

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_volume" "node_data" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domain.ad.name
  size_in_gbs         = "100"

  lifecycle {
    prevent_destroy = true
  }
}

resource "oci_core_volume_attachment" "node_data" {
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.node.id
  volume_id       = oci_core_volume.node_data.id
}
