yc = {
    cloud = {
        id = "b1gk2uh1jv4i27fikj4f"
    }
    folder = {
        name = "otus-lab"
        id   = "b1g5h8d28qvg63eps3ms" #otus-lab
    }
    zone   = "ru-central1-d"
    region = "ru-central1"
}

network = {
    name = "k8s-network"
}

subnet = {
    name = "k8s-subnet"
    cidr = ["10.10.0.0/16"]
}

k8s = {
    version = {
        current = "1.33"
        upgrade = "1.34"
    }
}

vm = {
    master = {
        name          = "master"
        count         = 1
        cpu           = 2
        memory        = 8
        core_fraction = 100
        platform_id   = "standard-v3"
        disk          = {
          size = 10
          type = "network-ssd"
        }
        # yc compute image list --folder-id standard-images
        image         = {
          name = "ubuntu-24-04-lts-v20251006"
          id   = "fd84mnbiarffhtfrhnog"
        }
        nat                       = true
        ip_address                = null
        nat_ip_address            = null
        allow_stopping_for_update = true
    }
    worker = {
        name          = "worker"
        count         = 3
        cpu           = 2
        memory        = 8
        core_fraction = 100
        platform_id   = "standard-v3"
        disk          = {
          size = 10
          type = "network-ssd"
        }
        # yc compute image list --folder-id standard-images
        image         = {
          name = "ubuntu-24-04-lts-v20251006"
          id   = "fd84mnbiarffhtfrhnog"
        }
        nat                       = false
        ip_address                = null
        nat_ip_address            = null
        allow_stopping_for_update = true
    }
}

user = {
    name = "ubuntu"
    ssh = {
        public_key  = "~/.ssh/otus.pub"
        private_key = "~/.ssh/otus"
    }
}