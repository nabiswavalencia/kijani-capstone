terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

# Step 1. Connect Terraform to the local minikube cluster.
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

# Step 2. Create the staging namespace. Production uses the default namespace that already exists.
resource "kubernetes_namespace" "staging" {
  metadata {
    name = "kijani-staging"
  }
}

output "staging_namespace" {
  value = kubernetes_namespace.staging.metadata[0].name
}
