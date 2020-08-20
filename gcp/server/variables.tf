variable project {
  type        = string
  description = "GCP project for server"
}

variable instance_name {
  type        = string
  description = "name for the compute engine instance"
}

variable zone {
  type    = string
  default = "us-west1-a"
}

variable ip_addr_region {
  type    = string
  default = "us-west1"
}

variable machine_type {
  type        = string
  description = "machine type for the compute engine instance"
}

variable image {
  type        = string
  description = "boot image for the compute engine instance"
}

variable username {
  type        = string
  description = "host username, used for copying SSH keys across"
  default     = "Kit.freddura"
}

variable preemptible {
  type        = bool
  description = "whether this instance should be preemtible or not"
  default     = false
}

variable dns_zone_name {
  type        = string
  description = "name to give DNS zone"
}

variable dns_name {
  type        = string
  description = "name of DNS to attach to instance"
}
