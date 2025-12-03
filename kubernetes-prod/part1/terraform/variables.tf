variable "yc" {
  type = object({
    cloud  = object({
      id   = string
    })
    folder = object({
      name = string
      id   = string
    })
    zone = string
    region = string
  })
  description = "Yandex Cloud Parameters"
  # default = {
  #   vm = {
  #   cloud  = {
  #     id = ""
  #   }
  #   folder = {
  #     id   = ""
  #     name = "k8s-folder"
  #   }
  #   zone = "ru-central1-d"
  #   region = "ru-central1"
  # }}
}

variable "k8s" {
  type = object({
    version  = object({
      current = string
      upgrade = string
    })
  })
  description = "K8s version"
  default = {
    version  = {
      current = "1.33"
      upgrade = "1.34"
    }
  }
}

variable "network" {
  type = object({
    name  = string
  })
  description = "VPC network name"
  default = {
    name  = "k8s-network"
  }
}

variable "subnet" {
  type = object({
    name = string
    cidr = list(string)
  })
  description = "VPC subnet name and CIDR"
  default = {
    name  = "k8s-subnet"
    cidr = ["10.10.0.0/16"]
  }
}

# variable "network_interface" {
#   description = "Additional network interface to attach to the instance"
#   type        = map(map(string))
#   default     = {}
# }

## VM parameters
variable "vm" {
  type = map(object({
    name          = string
    count         = number
    cpu           = number
    memory        = number
    core_fraction = number
    platform_id   = string
    disk          = object({
      size = number
      type = string
    })
    image         = object({
      name = string
      id   = string
    })
    nat                       = bool
    ip_address                = string
    nat_ip_address            = string
    allow_stopping_for_update = bool
  }))
  description = "VM parameters"
  # default = {
  #   name          = ""
  #   count         = 1
  #   cpu           = 2
  #   memory        = 8
  #   core_fraction = 100
  #   platform_id   = "standard-v3"
  #   disk          = {
  #     size = 10
  #     type = "network-ssd"
  #   }
  #   # yc compute image list --folder-id standard-images
  #   image         = {
  #     name = "ubuntu-24-04-lts-v20251006"
  #     id   = "fd84mnbiarffhtfrhnog"
  #   }
  #   nat                       = true
  #   ip_address                = null
  #   nat_ip_address            = null
  #   allow_stopping_for_update = true
  # }
}

variable "user" {
  type = object({
    name = string
    ssh = object({
      public_key  = string  #cloud-config ssh public key
      private_key = string  #cloud-config ssh private key
    })
  })
  description = "VM User Parameters"
  sensitive = true
  default = {
    name  = ""
    ssh = {
      public_key  = ""
      private_key = ""
    }
  }
}

