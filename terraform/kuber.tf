terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token = "t1.9euelZqUlovKzJfInM6YyIrInM6Tm-3rnpWamp2Lz8vPyMiPkZOLz5OZno_l8_coaApF-e8xSUF6_d3z92gWCEX57zFJQXr9zef1656VmpmXkJPOyo-Si5HJmseQxpKM7_zN5_XrnpWakpWWl4nJmo-Jm57PlcuXjcvv_cXrnpWamZeQk87Kj5KLkcmax5DGkow.E-5EkLtH1VFxj4PuzAICtjyRktrZLJLWE-rJ29Hm7dlMVrmqVV74w-grYsoU5Mu9zAT96UT_RlCfzpPxu5CEBw"
  folder_id = "b1gjrgvil6pq5ah7547d"
}

resource "yandex_kubernetes_cluster" "kuber_cluster" {
 network_id = yandex_vpc_network.network-1.id
 master {
   master_location {
     zone      = yandex_vpc_subnet.subnet1.zone
     subnet_id = yandex_vpc_subnet.subnet1.id
   }
   security_group_ids = [yandex_vpc_security_group.k8s-public-services.id]
   public_ip = true
 }
 service_account_id      = data.yandex_iam_service_account.devops-service-account.id
 node_service_account_id = data.yandex_iam_service_account.devops-service-account.id
   depends_on = [
     yandex_resourcemanager_folder_iam_member.editor,
     yandex_resourcemanager_folder_iam_member.images-puller,
	 yandex_resourcemanager_folder_iam_member.vpc-public-admin
   ]
}
resource "yandex_vpc_network" "network-1" { name = "network-1" }

resource "yandex_vpc_subnet" "subnet1" {
 v4_cidr_blocks = ["192.168.10.0/24"]
 zone           = "ru-central1-a"
 network_id     = yandex_vpc_network.network-1.id
}
data "yandex_iam_service_account" "devops-service-account" {
  name = "devops-service-account"  
}
resource "yandex_resourcemanager_folder_iam_member" "editor" {
 # Сервисному аккаунту назначается роль "editor".
 folder_id = "b1gjrgvil6pq5ah7547d"
 role      = "editor"
 member    = "serviceAccount:${data.yandex_iam_service_account.devops-service-account.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "images-puller" {
 # Сервисному аккаунту назначается роль "container-registry.images.puller".
 folder_id = "b1gjrgvil6pq5ah7547d"
 role      = "container-registry.images.puller"
 member    = "serviceAccount:${data.yandex_iam_service_account.devops-service-account.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "vpc-public-admin" {
  # Сервисному аккаунту назначается роль "vpc.publicAdmin".
  folder_id = "b1gjrgvil6pq5ah7547d"
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${data.yandex_iam_service_account.devops-service-account.id}"
}

resource "yandex_vpc_security_group" "k8s-public-services" {
  name        = "k8s-public-services"
  description = "Правила группы разрешают подключение к сервисам из интернета. Примените правила только для групп узлов."
  network_id  = yandex_vpc_network.network-1.id
  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает проверки доступности с диапазона адресов балансировщика нагрузки. Нужно для работы отказоустойчивого кластера Managed Service for Kubernetes и сервисов балансировщика."
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие мастер-узел и узел-узел внутри группы безопасности."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ANY"
    description       = "Правило разрешает взаимодействие под-под и сервис-сервис. Укажите подсети вашего кластера Managed Service for Kubernetes и сервисов."
    v4_cidr_blocks    = concat(yandex_vpc_subnet.subnet1.v4_cidr_blocks)
    from_port         = 0
    to_port           = 65535
  }
  ingress {
    protocol          = "ICMP"
    description       = "Правило разрешает отладочные ICMP-пакеты из внутренних подсетей."
    v4_cidr_blocks    = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  ingress {
    protocol          = "TCP"
    description       = "Правило разрешает входящий трафик из интернета на диапазон портов NodePort. Добавьте или измените порты на нужные вам."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 30000
    to_port           = 32767
  }
  egress {
    protocol          = "ANY"
    description       = "Правило разрешает весь исходящий трафик. Узлы могут связаться с Yandex Container Registry, Yandex Object Storage, Docker Hub и т. д."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }
}