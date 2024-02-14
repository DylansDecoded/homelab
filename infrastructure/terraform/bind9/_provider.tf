terraform {
  required_version = ">= 0.13.0"

  required_providers {
    dns = {
      source  = "hashicorp/dns"
      version = "3.4.0"
    }
  }
  cloud {
    organization = "DylansDecoded"

    workspaces {
      name = "homelab-dns"
    }
  }
}

variable "TSIG_HOME_KEY" {
  type      = string
  sensitive = true
}

provider "dns" {
  update {
    server        = "10.1.10.53"
    key_name      = "tsig-key."
    key_algorithm = "hmac-sha256"
    key_secret    = var.TSIG_HOME_KEY
  }
}
