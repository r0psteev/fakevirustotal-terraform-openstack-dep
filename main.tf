# Define required providers
terraform {
required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform.local/st11/openstack"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "admin"
  tenant_name = "admin"
  password    = "your_password"
  // this provider supports openstack v2, but microstack comes with v3.0
  auth_url    = "https://10.1.1.211:5000/v3.0"
  // prevents ssl verification
  insecure =  true
}

# Create a keypair so that we and ansible can ssh to our deployment server
resource "openstack_compute_keypair_v2" "terraform" {
    name = "terraform"
    public_key = file("./faketotal.pem.pub")
}

# Create a deployment server
resource "openstack_compute_instance_v2" "jammy_prod" {
  # Check: https://github.com/terraform-provider-openstack/terraform-provider-openstack/blob/main/examples/multiple-vm-with-floating-ip/main.tf
  key_pair = openstack_compute_keypair_v2.terraform.name
  name  = "jammy_prod"
  image_id = "c7d0ebb4-580f-4acb-959c-13515bd520bb"
  flavor_id = "3" # m1.medium
  network {
    # internal private network in microstack
    name = "test"
  }
}

# attach floating ip address to instance
resource "openstack_networking_floatingip_v2" "fip" {
    # Name of the floating ip pool
    # it is called external in microstack
    pool  = "external"
}

resource "openstack_compute_floatingip_associate_v2" "fip" {
  instance_id = openstack_compute_instance_v2.jammy_prod.id
  floating_ip = openstack_networking_floatingip_v2.fip.address
}

output "instance_floating_ip" {
    value = openstack_networking_floatingip_v2.fip.address
    description = "Where to reach the production instance"
}