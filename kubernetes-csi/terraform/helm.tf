# resource "helm_release" "ingress_nginx" {
#   name             = "ingress-nginx"
#   repository       = "https://kubernetes.github.io/ingress-nginx"
#   chart            = "ingress-nginx"
#   # version          = "4.13.3"
#   namespace        = "ingress-nginx"
#   create_namespace = true
#   atomic           = true

#   # set {
#   #   name  = "configs.params.server\\.insecure"
#   #   value = "true"
#   # }

#   depends_on = [
#     yandex_kubernetes_cluster.k8s_cluster,
#   ]
# }

# resource "helm_release" "contour" {
#   name             = "contour"
#   repository       = "https://projectcontour.github.io"
#   chart            = "helm-charts"
#   # version          = "v1.33.0"
#   namespace        = "projectcontour"
#   create_namespace = true
#   atomic           = true

#   depends_on = [
#     yandex_kubernetes_cluster.k8s_cluster,
#   ]
# }
