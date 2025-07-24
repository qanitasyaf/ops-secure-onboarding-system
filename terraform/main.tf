resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!@#$%^&*()-_=+"
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
}

# --------------------------------------------------------------------------
# Local Variables
# Digunakan untuk nilai-nilai yang digenerate atau dikombinasikan
locals {
  # Menggunakan random_id untuk membuat nama bucket yang unik.
  # Ini mengatasi error "Variables not allowed" yang muncul sebelumnya.
  generated_cicd_bucket_name = "cicd-artifacts-${random_id.bucket_suffix.hex}"
}
# --------------------------------------------------------------------------


# --------------------------------------------------------------------------
# 1. Jaringan (VPC dan Subnet)
# --------------------------------------------------------------------------
resource "google_compute_network" "vpc_network" {
  project                 = var.project_id
  name                    = var.vpc_network_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "gke_subnet" {
  project                  = var.project_id
  name                     = var.subnet_name
  ip_cidr_range            = var.subnet_cidr
  region                   = var.region
  network                  = google_compute_network.vpc_network.name
  private_ip_google_access = true

  secondary_ip_range {
    range_name  = var.pod_ip_range_name
    ip_cidr_range = var.pod_ip_range_cidr
  }

  secondary_ip_range {
    range_name  = var.services_ip_range_name
    ip_cidr_range = var.services_ip_range_cidr
  }
}

# Firewall rules
resource "google_compute_firewall" "allow_internal" {
  project       = var.project_id
  name          = "${var.gke_cluster_name}-allow-internal"
  network       = google_compute_network.vpc_network.name
  source_ranges = [var.subnet_cidr, var.pod_ip_range_cidr, var.services_ip_range_cidr]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow_external_gke_access" {
  project = var.project_id
  name    = "${var.gke_cluster_name}-allow-external-gke"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "30000-32767"] # HTTP/HTTPS dan NodePort range
  }
  source_ranges = ["0.0.0.0/0"] # WARNING: Untuk produksi, batasi ke IP yang terpercaya
  target_tags   = ["gke-node"]
}

# --------------------------------------------------------------------------
# 2. Service Accounts dan IAM
# --------------------------------------------------------------------------
resource "google_service_account" "gke_node_sa" {
  project      = var.project_id
  account_id   = var.gke_node_sa_id
  display_name = "Service Account for GKE Nodes"
}

resource "google_project_iam_member" "gke_node_sa_roles" {
  project = var.project_id
  for_each = toset([
    "roles/container.nodeServiceAccount",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/compute.viewer",
    "roles/iam.serviceAccountUser",
  ])
  role   = each.value
  member = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_service_account" "cloudbuild_sa" {
  project      = var.project_id
  account_id   = var.cloudbuild_sa_id
  display_name = "Service Account for Cloud Build"
}

resource "google_project_iam_member" "cloudbuild_sa_roles" {
  project = var.project_id
  for_each = toset([
    "roles/cloudbuild.builds.editor",
    "roles/container.developer",
    "roles/storage.admin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.writer",
  ])
  role   = each.value
  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

resource "google_project_iam_member" "cloudbuild_sa_project_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.cloudbuild_sa.email}"
}

# --------------------------------------------------------------------------
# 3. Cluster GKE
# --------------------------------------------------------------------------
resource "google_container_cluster" "primary_gke" {
  project                  = var.project_id
  name                     = var.gke_cluster_name
  location                 = var.region
  network                  = google_compute_network.vpc_network.name
  subnetwork               = google_compute_subnetwork.gke_subnet.name
  initial_node_count       = 1
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  release_channel {
    channel = var.gke_release_channel
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.gke_subnet.secondary_ip_range[0].range_name
    services_secondary_range_name = google_compute_subnetwork.gke_subnet.secondary_ip_range[1].range_name
  }

  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? ["enabled"] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }

  # Menonaktifkan default node pool untuk mengelola node pool secara terpisah
  remove_default_node_pool = true
  node_locations           = ["${var.region}-b"] # Contoh: satu zona, sesuaikan jika ingin multi-zone

  # Master authorized networks (penting untuk keamanan)
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "0.0.0.0/0" # WARNING: SANGAT TIDAK AMAN UNTUK PRODUKSI. Batasi ke IP Anda.
      display_name = "Allow all for testing"
    }
  }

  # Aktifkan akses private endpoint untuk control plane (lebih aman)
  private_cluster_config {
    enable_private_endpoint = false # Set ke true jika Anda ingin private endpoint
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28" # Contoh CIDR untuk control plane
  }

  # Fitur GKE (opsional)
  addons_config {
    http_load_balancing {
      disabled = false
    }
    network_policy_config {
      disabled = false # Aktifkan Network Policy
    }
  }
}

resource "google_container_node_pool" "primary_node_pool" {
  project    = var.project_id
  location   = var.region
  cluster    = google_container_cluster.primary_gke.name
  name       = "${var.gke_cluster_name}-node-pool"
  node_count = var.gke_node_count

  node_config {
    machine_type    = var.gke_machine_type
    disk_size_gb    = var.gke_disk_size_gb
    image_type      = "COS_CONTAINERD"
    service_account = google_service_account.gke_node_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = 1
    max_node_count = 5 # Sesuaikan batas autoscaling
  }
}

# Removed node_labels attribute as it is not expected here

# --------------------------------------------------------------------------
# 4. Cloud SQL (PostgreSQL)
# --------------------------------------------------------------------------
# MENGHAPUS DEFINISI VPC DAN SUBNET DUPLIKAT DI SINI.
# VPC dan Subnet GKE yang sudah ada akan digunakan untuk Cloud SQL.
/*
resource "google_compute_network" "vpc_network_name" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet_name" {
  name                     = "gke-subnet"
  region                   = var.region
  network                  = google_compute_network.vpc_network_name.id
  ip_cidr_range            = "10.10.0.0/16"
  private_ip_google_access = true
}
*/

# Alokasi IP range untuk Cloud SQL private service access
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "sql-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 20
  # Menggunakan VPC yang sama dengan GKE
  network       = google_compute_network.vpc_network.id
}


# Koneksi peering VPC untuk private service access (Cloud SQL)
resource "google_service_networking_connection" "private_vpc_connection" {
  # Menggunakan VPC yang sama dengan GKE
  network                   = google_compute_network.vpc_network.id
  service                   = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]
}

resource "google_sql_database_instance" "postgres_instance" {
  name             = var.db_instance_name
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier        = var.db_tier
    disk_size   = var.db_disk_size_gb
    disk_type   = "PD_SSD"
    # Pastikan ini sudah diatur ke false untuk memungkinkan penghapusan/modifikasi
    deletion_protection_enabled = false

    ip_configuration {
      ipv4_enabled    = false
      # Menggunakan VPC yang sama dengan GKE
      private_network = google_compute_network.vpc_network.id
    }

    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "mydb" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres_instance.name
}

resource "google_sql_user" "db_user" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres_instance.name
  password = random_password.db_password.result
}
# --------------------------------------------------------------------------
# 5. Cloud Storage Bucket (untuk Artifacts CI/CD)
# --------------------------------------------------------------------------
resource "google_storage_bucket" "cicd_artifacts_bucket" {
  project                     = var.project_id
  name                        = local.generated_cicd_bucket_name # <-- Menggunakan local variable yang baru didefinisikan
  location                    = var.region
  storage_class               = "STANDARD" # Atau "REGIONAL", "NEARLINE", "COLDLINE", "ARCHIVE"
  uniform_bucket_level_access = true # Rekomendasi keamanan
  force_destroy               = false # Set ke true jika ingin bucket terhapus saat terraform destroy
}