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
  project = "model-parsec-465503-p3"
  region  = "asia-southeast1"
}