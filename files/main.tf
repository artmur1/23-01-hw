terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

resource "yandex_vpc_network" "murchin-net" {
  name = local.network_name
}

resource "yandex_vpc_subnet" "public" {
  name           = local.subnet_name1
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone           = var.default_zone
  network_id     = yandex_vpc_network.murchin-net.id
}

resource "yandex_compute_disk" "vm-disk-public" {
  name     = local.disk1_name
  zone     = var.default_zone
  size     = var.vm_resources.nat_res.disk_size
  image_id = "fd80mrhj8fl2oe87o4e1"
}

resource "yandex_compute_instance" "nat-instance" {
  name        = local.vm_nat_name
  platform_id = "standard-v3"
  zone        = var.default_zone

  resources {
    core_fraction = var.vm_resources.nat_res.core_fraction
    cores         = var.vm_resources.nat_res.cores
    memory        = var.vm_resources.nat_res.memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.vm-disk-public.id
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    index     = 1
    subnet_id = yandex_vpc_subnet.public.id
    ip_address = "192.168.10.254"
    nat       = true
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}

resource "yandex_vpc_subnet" "private" {
  name           = local.subnet_name2
  v4_cidr_blocks = ["192.168.20.0/24"]
  zone           = var.default_zone
  network_id     = yandex_vpc_network.murchin-net.id
  route_table_id = yandex_vpc_route_table.nat-instance-route.id
}

resource "yandex_vpc_route_table" "nat-instance-route" {
  name       = local.route_table_name
  network_id = yandex_vpc_network.murchin-net.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = yandex_compute_instance.nat-instance.network_interface.0.ip_address
  }
}

resource "yandex_compute_disk" "vm-disk-private" {
  name     = local.disk2_name
  zone     = var.default_zone
  size     = var.vm_resources.priv_res.disk_size
  image_id = "fd80mrhj8fl2oe87o4e1"
}

resource "yandex_compute_instance" "vm-private" {
  name        = local.vm_private_name
  platform_id = "standard-v3"
  zone        = var.default_zone

  resources {
    core_fraction = var.vm_resources.priv_res.core_fraction
    cores         = var.vm_resources.priv_res.cores
    memory        = var.vm_resources.priv_res.memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.vm-disk-private.id
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    index     = 1
    subnet_id = yandex_vpc_subnet.private.id
    ip_address = "192.168.20.250"
    nat       = false
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }
}