variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-c"
}

variable "vm_name" {
  type    = string
  default = "demo-vm"
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}
