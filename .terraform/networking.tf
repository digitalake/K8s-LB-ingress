resource "google_compute_network" "vpc_network" {
  name                    = "${var.project_alias}-default-net"
  auto_create_subnetworks = false
  routing_mode            = var.net_rt_mode
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = "${var.project_alias}-default-subnet"
  ip_cidr_range = var.subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.vpc_network.id
}