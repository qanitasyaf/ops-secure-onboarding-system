terraform {
  backend "gcs" {
    bucket  = "xmen-terraform-state"
    prefix  = "vm/simple"
  }
}
