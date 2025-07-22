# variables.tf

variable "project_id" {
  description = "Google Cloud Project ID"
  type        = string
  default     = "model-parsec-465503-p3" 
}

variable "region" {
  description = "Region to Deploy Google Kubernetes Engine"
  type        = string
  default     = "asia-southeast1" 
}

# --- GKE Cluster Variables ---
variable "gke_cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
  default     = "cicd-gke-cluster"
}

variable "gke_machine_type" {
  description = "The machine type for GKE nodes."
  type        = string
  default     = "e2-medium"
}

variable "gke_node_count" {
  description = "The number of nodes in the default node pool."
  type        = number
  default     = 2
}

variable "gke_disk_size_gb" {
  description = "Disk size in GB for the GKE nodes."
  type        = number
  default     = 50
}

variable "gke_release_channel" {
  description = "The release channel for the GKE cluster (e.g., REGULAR, STABLE, RAPID)."
  type        = string
  default     = "REGULAR"
}

variable "enable_workload_identity" {
  description = "Whether to enable Workload Identity on the GKE cluster."
  type        = bool
  default     = true
}

# --- Network Variables ---
variable "vpc_network_name" {
  description = "The name of the custom VPC network."
  type        = string
  default     = "cicd-vpc-network"
}

variable "subnet_name" {
  description = "The name of the custom subnet."
  type        = string
  default     = "cicd-subnet"
}

variable "subnet_cidr" {
  description = "The IP CIDR range for the main subnet."
  type        = string
  default     = "10.0.0.0/19"
}

variable "pod_ip_range_name" {
  description = "The name for the secondary IP range for pods."
  type        = string
  default     = "gke-pods-range"
}

variable "pod_ip_range_cidr" {
  description = "The IP CIDR range for pods."
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_ip_range_name" {
  description = "The name for the secondary IP range for services."
  type        = string
  default     = "gke-services-range"
}

variable "services_ip_range_cidr" {
  description = "The IP CIDR range for services."
  type        = string
  default     = "10.2.0.0/20"
}

# --- Cloud SQL Variables ---
variable "db_instance_name" {
  description = "The name of the Cloud SQL PostgreSQL instance."
  type        = string
  default     = "cicd-sonarqube-db"
}

variable "db_name" {
  description = "The name of the database to create on Cloud SQL."
  type        = string
  default     = "sonarqube_db"
}

variable "db_user" {
  description = "The username for the database user."
  type        = string
  default     = "sonarqube_user"
}

variable "app_image" {
  description = "Full Docker image path for the application to be deployed to GKE"
  type = string
  
}
# variables.tf

# ... (your other variable declarations like project_id, region, etc.) ...

# Cloud SQL variables
variable "db_tier" {
  description = "The machine type (tier) for the Cloud SQL instance. Example: db-f1-micro, db-g1-small, db-standard-4."
  type        = string
  default     = "db-g1-small" 
}

variable "db_disk_size_gb" {
  description = "The disk size in GB for the Cloud SQL instance."
  type        = number
  default     = 20 
}

# db_password akan digenerate secara acak untuk keamanan
# Pastikan Anda mengelola Secret ini di Kubernetes atau Secret Manager!

# --- Service Account Variables ---
variable "gke_node_sa_id" {
  description = "The ID for the GKE node service account."
  type        = string
  default     = "gke-node-sa"
}

variable "cloudbuild_sa_id" {
  description = "The ID for the Cloud Build service account."
  type        = string
  default     = "cloudbuild-sa"
}

