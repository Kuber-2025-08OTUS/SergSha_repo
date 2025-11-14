# # Установка Consul с помощью Helm
# resource "helm_release" "consul" {
#   name             = "consul"
#   repository       = "https://helm.releases.hashicorp.com"
#   chart            = "consul"
#   # version          = "1.22.0"
#   namespace        = "consul"
#   create_namespace = true
#   # atomic           = true

#   values = [
#     file("${path.module}/charts/consul-values.yaml")
#   ]

#   # # Or, provide values directly
#   # set {
#   #   name  = "global.name"
#   #   value = "consul"
#   # }
#   # set {
#   #   name  = "server.replicas"
#   #   value = "3"
#   # }

#   depends_on = [
#     yandex_kubernetes_cluster.k8s_cluster,
#     yandex_kubernetes_node_group.vault_nodes,
#   ]
# }

# # Установка Vault с помощью Helm
# resource "helm_release" "vault" {
#   name             = "vault"
#   repository       = "https://helm.releases.hashicorp.com"
#   chart            = "vault"
#   # version          = "1.20.4"
#   namespace        = "vault"
#   create_namespace = true
#   # atomic           = true

#   values = [
#     file("${path.module}/charts/vault-values.yaml")
#   ]

#   depends_on = [
#     yandex_kubernetes_cluster.k8s_cluster,
#     yandex_kubernetes_node_group.vault_nodes,
#   ]
# }

# # Установка External Secrets Operator с помощью Helm
# resource "helm_release" "external_secrets" {
#   name             = "external-secrets"
#   repository       = "https://charts.external-secrets.io"
#   chart            = "external-secrets"
#   # version          = "v0.20.4"
#   namespace        = "external-secrets"
#   create_namespace = true
#   # atomic           = true

#   values = [
#     file("${path.module}/charts/external-secrets-values.yaml")
#   ]

#   depends_on = [
#     yandex_kubernetes_cluster.k8s_cluster,
#     yandex_kubernetes_node_group.vault_nodes,
#   ]
# }