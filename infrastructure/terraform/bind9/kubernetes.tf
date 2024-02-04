resource "dns_a_record_set" "k3s_01" {
  zone = "robsonhome.cloud."
  name = "k3s-01"
  addresses = ["10.1.33.11"]
  ttl = 3600
}

resource "dns_a_record_set" "k3s_02" {
  zone = "robsonhome.cloud."
  name = "k3s-02"
  addresses = ["10.1.33.12"]
  ttl = 3600
}

resource "dns_a_record_set" "k3s_03" {
  zone = "robsonhome.cloud."
  name = "k3s-03"
  addresses = ["10.1.33.13"]
  ttl = 3600
}

resource "dns_a_record_set" "k3s_04" {
  zone = "robsonhome.cloud."
  name = "k3s-04"
  addresses = ["10.1.33.14"]
  ttl = 3600
}

resource "dns_a_record_set" "k3s_05" {
  zone = "robsonhome.cloud."
  name = "k3s-05"
  addresses = ["10.1.33.15"]
  ttl = 3600
}

resource "dns_a_record_set" "k3s_06" {
  zone = "robsonhome.cloud."
  name = "k3s-06"
  addresses = ["10.1.33.16"]
  ttl = 3600
}

