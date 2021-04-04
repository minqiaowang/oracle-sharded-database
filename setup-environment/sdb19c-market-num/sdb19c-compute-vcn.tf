variable "tenancy_ocid" {}
variable "region" {}
// variable "display_name" { default = "workshop" }
variable "AD" { default = 1 }
//variable "Image-Id" {default="ocid1.image.oc1..aaaaaaaafc323nq572bujhzwja7e6df532ioqq7qididhmnujpgbshm2zrzq"}
variable "catadb_shape" {
  default = "VM.Standard2.4"
}
variable "shard_shape" {
  default = "VM.Standard2.1"
}
variable "compartment_ocid" {}
variable "ssh_public_key" {}

//variable "num_instances" {
//  default = "1"
//}

terraform {
  required_version = ">= 0.12.0"
}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}

provider "oci" {
  tenancy_ocid = "${var.tenancy_ocid}"
  region       = "${var.region}"
}


variable "VCN-example" { default = "10.0.0.0/16" }
resource "oci_core_virtual_network" "example-vcn" {
  cidr_block     = "${var.VCN-example}"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "primary-vcn"
  dns_label      = "primaryvcn"
}

# --- Create a new Internet Gateway
resource "oci_core_internet_gateway" "example-ig" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "primary-internet-gateway"
  vcn_id         = "${oci_core_virtual_network.example-vcn.id}"
}
#---- Create Route Table
resource "oci_core_route_table" "example-rt" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.example-vcn.id}"
  display_name   = "primary-route-table"
  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.example-ig.id}"
  }
}

#--- Create a public Subnet 1 in AD1 in the new vcn
resource "oci_core_subnet" "example-public-subnet1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1], "name")}"
  cidr_block          = "10.0.1.0/24"
  display_name        = "primary-public-subnet1"
  dns_label           = "subnet1"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.example-vcn.id}"
  route_table_id      = "${oci_core_route_table.example-rt.id}"
  dhcp_options_id     = "${oci_core_virtual_network.example-vcn.default_dhcp_options_id}"
}


#--- Defualt  Network Security List

resource "oci_core_default_security_list" "default-security-list" {
  manage_default_resource_id = "${oci_core_virtual_network.example-vcn.default_security_list_id}"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }


  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 1521
      max = 1521
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 1522
      max = 1522
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 8081
      max = 8081
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 443
      max = 443
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }

  }
}

##
# Found image id from Marketplace and get signature
##
resource "oci_core_app_catalog_subscription" "generated_oci_core_app_catalog_subscription" {
	compartment_id = "ocid1.compartment.oc1..aaaaaaaahnn5lmnbuqbbyddbtpd5ixrvi5kuibzbeksokn2nm6ar6zcc5d7q"
	eula_link = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.eula_link}"
	listing_id = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.listing_id}"
	listing_resource_version = "Oracle_Database_19.10.0.0.210119_-_OL7U9"
	oracle_terms_of_use_link = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.oracle_terms_of_use_link}"
	signature = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.signature}"
	time_retrieved = "${oci_core_app_catalog_listing_resource_version_agreement.generated_oci_core_app_catalog_listing_resource_version_agreement.time_retrieved}"
}

resource "oci_core_app_catalog_listing_resource_version_agreement" "generated_oci_core_app_catalog_listing_resource_version_agreement" {
	listing_id = "ocid1.appcataloglisting.oc1..aaaaaaaaheuwo4wunrr4eqn6hab36sgeur5xb25nbs5v4f4w3cytjcqysurq"
	listing_resource_version = "Oracle_Database_19.10.0.0.210119_-_OL7U9"
}

##
# Create Compute Instance
##
resource "oci_core_instance" "cata_instance" {
  //count               = "${var.num_instances}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "cata"
  shape               = "${var.catadb_shape}"

  create_vnic_details {
    subnet_id = "${oci_core_subnet.example-public-subnet1.id}"
    display_name     = "cata"
    assign_public_ip = true
    hostname_label   = "cata"
  }

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1..aaaaaaaae27qas3nmkx2pjngxacb7jj5yhxop7nxego2pfjen47xjtrjucqa"

  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("cata-db.sh"))}"
  }
  depends_on = [
		oci_core_app_catalog_subscription.generated_oci_core_app_catalog_subscription
	]
}

resource "oci_core_instance" "shd1_instance" {
  //count               = "${var.num_instances}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "shd1"
  shape               = "${var.shard_shape}"

  create_vnic_details {
    subnet_id = "${oci_core_subnet.example-public-subnet1.id}"
    display_name     = "shd1"
    assign_public_ip = true
    hostname_label   = "shd1"
  }

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1..aaaaaaaae27qas3nmkx2pjngxacb7jj5yhxop7nxego2pfjen47xjtrjucqa"

  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("shd1-db.sh"))}"
  }
  depends_on = [
		oci_core_app_catalog_subscription.generated_oci_core_app_catalog_subscription
	]
}

resource "oci_core_instance" "shd2_instance" {
  //count               = "${var.num_instances}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "shd2"
  shape               = "${var.shard_shape}"

  create_vnic_details {
    subnet_id = "${oci_core_subnet.example-public-subnet1.id}"
    display_name     = "shd2"
    assign_public_ip = true
    hostname_label   = "shd2"
  }

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1..aaaaaaaae27qas3nmkx2pjngxacb7jj5yhxop7nxego2pfjen47xjtrjucqa"

  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("shd2-db.sh"))}"
  }
  depends_on = [
		oci_core_app_catalog_subscription.generated_oci_core_app_catalog_subscription
	]
}

resource "oci_core_instance" "shd3_instance" {
  //count               = "${var.num_instances}"
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[var.AD - 1], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "shd3"
  shape               = "${var.shard_shape}"

  create_vnic_details {
    subnet_id = "${oci_core_subnet.example-public-subnet1.id}"
    display_name     = "shd3"
    assign_public_ip = true
    hostname_label   = "shd3"
  }

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1..aaaaaaaae27qas3nmkx2pjngxacb7jj5yhxop7nxego2pfjen47xjtrjucqa"

  }

  metadata = {
    ssh_authorized_keys = "${var.ssh_public_key}"
    user_data           = "${base64encode(file("shd3-db.sh"))}"
  }
  depends_on = [
		oci_core_app_catalog_subscription.generated_oci_core_app_catalog_subscription
	]
}

output "cata_public_ips" {
  value = ["${oci_core_instance.cata_instance.public_ip}"]
}

output "cata_private_ips" {
  value = ["${oci_core_instance.cata_instance.private_ip}"]
}

output "shd1_public_ips" {
  value = ["${oci_core_instance.shd1_instance.public_ip}"]
}

output "shd1_private_ips" {
  value = ["${oci_core_instance.shd1_instance.private_ip}"]
}

output "shd2_public_ips" {
  value = ["${oci_core_instance.shd2_instance.public_ip}"]
}

output "shd2_private_ips" {
  value = ["${oci_core_instance.shd2_instance.private_ip}"]
}

output "shd3_public_ips" {
  value = ["${oci_core_instance.shd3_instance.public_ip}"]
}

output "shd3_private_ips" {
  value = ["${oci_core_instance.shd3_instance.private_ip}"]
}