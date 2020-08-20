provider "google" {
  project = var.project
  region  = var.zone
  // We leave out credentials and rely instead on the default GCP auth mechanism
}

// Setup GCS storage for state
terraform {
  backend "gcs" {
    bucket = "tf-state-kit-freddura"
    prefix = "foundry-vtt"
  }
}


// Instance ID
resource "random_id" "instance_id" {
  byte_length = 8
}

// Create a static ip
resource "google_compute_address" "ip_addr" {
  name   = "foundry-vtt-addr"
  region = var.ip_addr_region
}

// A persistent disk
resource "google_compute_disk" "default" {
  name  = "foundry-vtt-disk"
  type  = var.disk_type
  zone  = var.zone
  image = var.image
  size  = var.disk_size
}

// Compute Engine instance
resource "google_compute_instance" "default" {
  name         = "foundry-vtt-${random_id.instance_id.hex}"
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

  scheduling {
    preemptible = var.preemptible
  }

  lifecycle {
    ignore_changes = [attached_disk]
  }
}

// Attack the disk to the instance
resource "google_compute_attached_disk" "default" {
  disk     = google_compute_disk.default.id
  instance = google_compute_instance.default.id
}

// Setup any firewall rules
resource "google_compute_firewall" "default" {
  name    = "foundry-vtt-firewall"
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
  rrdatas      = ["www.${google_dns_managed_zone.default.dns_name}"]
}

// Save the external IP to an output variable
output "ip" {
  value = google_compute_instance.default.network_interface.0.access_config.0.nat_ip
}
