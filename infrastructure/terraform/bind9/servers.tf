resource "dns_a_record_set" "truenas_01" {
  zone = "robsonhome.cloud."
  name = "truenas"
  addresses = ["10.1.10.210"]
  ttl = 3600
}

resource "dns_a_record_set" "pve_01" {
  zone = "robsonhome.cloud."
  name = "pve-01"
  addresses = ["10.1.10.52"]
  ttl = 3600
}


resource "dns_a_record_set" "omada_controller" {
  zone = "robsonhome.cloud."
  name = "omada"
  addresses = ["10.1.10.200"]
  ttl = 3600
}


