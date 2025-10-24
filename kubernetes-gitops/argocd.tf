# Установка ArgoCD с помощью Helm
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  # version          = "5.46.8"
  namespace        = "argocd"
  create_namespace = true
  # atomic           = true

  values = [
    file("${path.module}/charts/argocd-values.yaml")
  ]

  # set {
  #   name  = "configs.params.server\\.insecure"
  #   value = "true"
  # }

  depends_on = [
    yandex_kubernetes_cluster.k8s_cluster,
  ]
}

# resource "kubernetes_manifest" "argocd_project" {
#   manifest = yamldecode(file("argocd-project.yaml"))

#   depends_on = [
#     helm_release.argocd,
#   ]
# }

# resource "kubernetes_manifest" "app_kubernetes_networks" {
#   manifest = yamldecode(file("app-kubernetes-networks.yaml"))

#   depends_on = [
#     kubernetes_manifest.argocd_project,
#   ]
# }

# resource "kubernetes_manifest" "app_kubernetes_templating" {
#   manifest = yamldecode(file("app-kubernetes-templating.yaml"))

#   depends_on = [
#     kubernetes_manifest.argocd_project,
#   ]
# }
