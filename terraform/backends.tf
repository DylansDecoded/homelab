terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    access_key = "TF_VAR_ACCESS_KEY"
    secret_key = "TF_VAR_SECRET_KEY"
    endpoints = { s3 = "https://<YOUR_ACCOUNT_ID>.r2.cloudflarestorage.com" }
  }
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 4"
    }
  }
}
provider "cloudflare" {
  # token pulled from $CLOUDFLARE_API_TOKEN
}