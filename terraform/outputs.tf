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

output "db_private_ip_address" {
  value = google_sql_database_instance.postgres_instance.private_ip_address
}

output "db_connection_name" {
  value = google_sql_database_instance.postgres_instance.connection_name
}

output "db_password" {
  value     = random_password.db_password.result
  sensitive = true
}

output "vpc_network_name" {
  value = google_compute_network.vpc_network.name
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