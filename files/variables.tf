###cloud vars
variable "default_zone" {
  type        = string
  default     = "ru-central1-b"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "vpc_name" {
  type        = string
  default     = "network1"
  description = "VPC network & subnet name"
}

variable "vm_resources" { 
  type         = map(map(number))
  default      = {
    nat_res = {
      cores = 2
      memory = 4
      core_fraction = 20
      disk_size = 20
    }
    priv_res = {
      cores = 2
      memory=2
      core_fraction=20
      disk_size = 20
    }
  }
}
