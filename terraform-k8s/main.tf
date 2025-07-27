provider "kubernetes" {
  config_path = var.kubeconfig_path
}

resource "null_resource" "apply_kustomize" {
  provisioner "local-exec" {
    command = "kubectl apply -k ../k8s"
  }
}
