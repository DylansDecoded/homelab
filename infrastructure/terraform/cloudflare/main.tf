terraform {
  cloud {
    organization = "DylansDecoded"

    workspaces {
      name = "arpa-home-cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.29.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.2"
    }
  }
  required_version = ">= 1.3.0"
}

# Obtain current home IP address
data "http" "ipv4_lookup_raw" {
  url = "http://ipv4.icanhazip.com"
}

module "onepassword_item_cloudflare" {
  source = "github.com/bjw-s/terraform-1password-item?ref=main"
  vault  = "kubernetes"
  item   = "cloudflare"
}
