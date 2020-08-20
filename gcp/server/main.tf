provider "google" {
  project = "general-hackery"
  region  = var.zone
}

// Instance ID
resource "random_id" "instance_id" {
  byte_length = 8
}

// Create a static ip
resource "google_compute_address" "ip_addr" {
  name   = "${var.instance_name}-addr"
  region = var.ip_addr_region
}

// Compute Engine instance
resource "google_compute_instance" "default" {
  name         = "${var.instance_name}-${random_id.instance_id.hex}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Bind the external IP
      nat_ip = google_compute_address.ip_addr.address
    }
  }

  metadata = {
    ssh-keys = "${var.username}:${file("~/.ssh/id_rsa.pub")}"
  }

  scheduling {
    preemptible = var.preemptible
  }
}

// Setup any firewall rules
resource "google_compute_firewall" "default" {
  name    = "${var.instance_name}-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

// Setup the DNS
resource "google_dns_managed_zone" "default" {
  name     = var.dns_zone_name
  dns_name = var.dns_name
}

// The A record 
resource "google_dns_record_set" "A" {
  managed_zone = google_dns_managed_zone.default.name
  name         = google_dns_managed_zone.default.dns_name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_instance.default.network_interface.0.access_config.0.nat_ip]
}

// The CNAME for the www
resource "google_dns_record_set" "CNAME" {
  managed_zone = google_dns_managed_zone.default.name
  name         = "www.${google_dns_managed_zone.default.dns_name}"
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["www.beavers.app."]
}

// Save the external IP to an output variable
output "ip" {
  value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}
