resource "cloudflare_account" "main" {
  name              = "homelab account"
  enforce_twofactor = true
  lifecycle {
    prevent_destroy = true
  }
}
