resource "yandex_iam_service_account" "bucket_sa" {
  # folder_id = var.yc_folder_id
  name        = "bucket-sa"
  description = "Service account for service account to access S3"
}

resource "yandex_resourcemanager_folder_iam_member" "bucket_storage_admin" {
  folder_id = var.yc_folder_id
  # folder_id = yandex_resourcemanager_folder.yc_folder.id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.bucket_sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "bucket_sa_keys" {
  service_account_id = yandex_iam_service_account.bucket_sa.id
  description        = "Static access keys for bucket S3 access"
  depends_on         = [yandex_resourcemanager_folder_iam_member.bucket_storage_admin]
}

resource "yandex_storage_bucket" "bucket_s3" {
  folder_id = var.yc_folder_id
  # folder_id = yandex_resourcemanager_folder.yc_folder.id
  # bucket    = "bucket-logs-${random_id.bucket_suffix.hex}"
  bucket     = "bucket-s3-01"
  access_key = yandex_iam_service_account_static_access_key.bucket_sa_keys.access_key
  secret_key = yandex_iam_service_account_static_access_key.bucket_sa_keys.secret_key

  anonymous_access_flags {
    read        = false
    list        = false
    config_read = false
  }
  depends_on = [yandex_iam_service_account_static_access_key.bucket_sa_keys]
}

# resource "random_id" "bucket_suffix" {
#   byte_length = 8
# }

output "bucket_s3_name" {
  value = yandex_storage_bucket.bucket_s3.bucket
}

# output "bucket_access_key" {
#   value     = yandex_iam_service_account_static_access_key.bucket_sa_keys.access_key
#   sensitive = true
# }

# output "bucket_secret_key" {
#   value     = yandex_iam_service_account_static_access_key.bucket_sa_keys.secret_key
#   sensitive = true
# }
