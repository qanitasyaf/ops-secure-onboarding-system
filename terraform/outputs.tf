# outputs.tf

output "gke_cluster_name" {
  description = "Name of the GKE cluster."
  value       = google_container_cluster.primary_gke.name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster API server."
  value       = google_container_cluster.primary_gke.endpoint
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig for the GKE cluster."
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary_gke.name} --region ${var.region} --project ${var.project_id}"
}

output "db_connection_name" {
  description = "The connection name for the Cloud SQL instance (used by Cloud SQL Proxy or direct connection)."
  value       = google_sql_database_instance.sonarqube_db_instance.connection_name
}

output "db_private_ip_address" {
  description = "The private IP address of the Cloud SQL instance."
  value       = google_sql_database_instance.sonarqube_db_instance.private_ip_address
}

output "db_username" {
  description = "The username for the Cloud SQL database."
  value       = google_sql_user.sonarqube_db_user.name
}

output "db_password" {
  description = "The randomly generated password for the Cloud SQL database user."
  value       = random_password.db_password.result
  sensitive   = true # Tandai sebagai sensitif agar tidak ditampilkan di console secara default
}

output "gcs_bucket_name" {
  description = "The name of the created Cloud Storage bucket."
  value       = google_storage_bucket.cicd_artifacts_bucket.name
}

output "gke_node_service_account_email" {
  description = "The email of the GKE node service account."
  value       = google_service_account.gke_node_sa.email
}

output "cloudbuild_service_account_email" {
  description = "The email of the Cloud Build service account."
  value       = google_service_account.cloudbuild_sa.email
}