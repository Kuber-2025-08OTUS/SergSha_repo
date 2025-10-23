# resource "yandex_iam_service_account" "loki_sa" {
#   name        = "loki-sa"
#   description = "Service account for Loki to access S3"
# }

# resource "yandex_resourcemanager_folder_iam_member" "loki_storage_editor" {
#   folder_id = var.yc_folder_id
#   # folder_id = yandex_resourcemanager_folder.yc_folder.id
#   role      = "storage.editor"
#   member    = "serviceAccount:${yandex_iam_service_account.loki_sa.id}"
# }

# resource "yandex_iam_service_account_static_access_key" "loki_sa_keys" {
#   service_account_id = yandex_iam_service_account.loki_sa.id
#   description        = "Static access keys for Loki S3 access"
# }

# resource "yandex_storage_bucket" "loki_bucket" {
#   # folder_id = yandex_resourcemanager_folder.yc_folder.id
#   # bucket     = "loki-logs-${random_id.bucket_suffix.hex}"
#   bucket     = "loki-logs-bucket"
#   access_key = yandex_iam_service_account_static_access_key.loki_sa_keys.access_key
#   secret_key = yandex_iam_service_account_static_access_key.loki_sa_keys.secret_key

#   anonymous_access_flags {
#     read = false
#     list = false
#   }
# }

# # resource "random_id" "bucket_suffix" {
# #   byte_length = 8
# # }

# # resource "kubernetes_secret" "loki_s3_credentials" {
# #   metadata {
# #     name      = "loki-bucket-creds"
# #     namespace = "loki"
# #   }
# #   data = {
# #     access-key-id     = yandex_iam_service_account_static_access_key.loki_sa_keys.access_key
# #     access-key-secret = yandex_iam_service_account_static_access_key.loki_sa_keys.secret_key
# #   }
# #   type = "Opaque"
# # }

# output "loki_bucket_name" {
#   value = yandex_storage_bucket.loki_bucket.bucket
# }

# output "loki_access_key" {
#   value     = yandex_iam_service_account_static_access_key.loki_sa_keys.access_key
#   sensitive = true
# }

# output "loki_secret_key" {
#   value     = yandex_iam_service_account_static_access_key.loki_sa_keys.secret_key
#   sensitive = true
# }