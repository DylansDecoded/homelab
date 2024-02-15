resource "dns_a_record_set" "pfs_01" {
  zone = "robsonhome.cloud."
  name = "pfs"
  addresses = ["10.1.1.1"]
  ttl = 3600
}


