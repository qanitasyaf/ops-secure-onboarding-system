# providers.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" 
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0" 
    }
  }
  required_version = ">= 1.0.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
  credentials = file(var.gcp_sa_key_file_path)
}