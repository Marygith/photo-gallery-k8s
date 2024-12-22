terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token = "t1.9euelZqUnZyVkZWNjJKRi87KkJGPzO3rnpWamp2Lz8vPyMiPkZOLz5OZno_l8_cLR2xF-e8SE3Q-_d3z90t1aUX57xITdD79zef1656VmsnJj4mYy5nGjczHk47KjZ7H7_zN5_XrnpWakpWWl4nJmo-Jm57PlcuXjcvv_cXrnpWaycmPiZjLmcaNzMeTjsqNnsc.Q8j_oJaNHmfszukw38apSXJyZlfFNgYnBXM4Q4Q0FdUn-vF2LJvPP3KiMzQp0lKqpZO74twocs5TdBdr1dmWCQ"
  zone = "ru-central1-a"
  folder_id = "b1gjrgvil6pq5ah7547d"
}


resource "yandex_compute_disk" "boot-disk" {
  name     = "devops-boot-disk"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  size     = "50"
  image_id = "fd8h3lua68396l7s9lac"
}

resource "yandex_compute_instance" "vm-1" {
  name                      = "linux-vm"
  allow_stopping_for_update = true
  platform_id               = "standard-v1"
  zone                      = "ru-central1-a"

  resources {
    cores  = "2"
    memory = "2"
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    nat       = true
  }

  metadata = {
    ssh-keys = "devopsovna:${file("~/.ssh/id_rsa_devops.pub")}"
    user-data = <<EOF
#cloud-config
package_update: true
package_upgrade: true
packages:
  - docker.io
EOF
  }
}

resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = "${yandex_vpc_network.network-1.id}"
}