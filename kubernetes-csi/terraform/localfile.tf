resource "local_file" "secret_yaml" {
  # for_each = var.vm
  content = templatefile("${path.module}/templates/secret.yaml.tftpl",
    {
      keys = yandex_iam_service_account_static_access_key.bucket_sa_keys
    }
  )
  filename = "${path.module}/../kubernetes/secret.yaml"
}