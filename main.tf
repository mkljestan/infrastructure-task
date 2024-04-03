terraform {
    required_providers {
      google = {
        source = "hashicorp/google"
        version = "5.23.0"
      }
    }
}

provider "google" {
  project     = "devops-t1-t2"
  region      = "europe-west1"
  credentials = file("./devops-t1-t2-b34668f5d49f.json")
}

resource "google_compute_network" "vpc_network" {
  name = "test-vpc"
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
}

resource "google_compute_subnetwork" "private_subnet" {
  name = "private-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network = google_compute_network.vpc_network.id
  region = "europe-west1"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "public_subnet" {
  name = "public-subnet"
  ip_cidr_range = "10.0.2.0/24"
  network = google_compute_network.vpc_network.id
  region = "europe-west1"
}

resource "google_compute_firewall" "allow-ssh" {
  name = "test-vpc-fw-allow-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}

resource "google_service_account" "default" {
  account_id   = "my-custom-sa"
  display_name = "Custom SA for VM Instance"
}

resource "google_compute_instance" "private_instance" {
  project     = "devops-t1-t2"
  name         = "private-instance"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.private_subnet.name
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_instance" "public_instance" {
  project     = "devops-t1-t2"
  name         = "public-instance"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }
}

data "google_compute_default_service_account" "default" {
}
