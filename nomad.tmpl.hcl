data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"

advertise {
  http = "{{ ip address }}"
  rpc  = "{{ ip address }}"
  serf = "{{ ip address }}"
}

server {
  enabled          = true
  bootstrap_expect = 1

  encrypt = "{{ base64 }}" # why not?
}

client {
  enabled = true
  servers = ["{{ ip address }}"]

  host_volume "ca-certificates" {
    path = "/var/local/ca-certificates"
  }

  host_volume "static-files" {
    path = "/var/www/files"
  }

  host_volume "faktura-settings" {
    path = "/var/www/faktura"
  }

  host_volume "ctftajm-postgres" {
    path = "/var/local/ctftajm-postgres"
  }

  host_volume "vaultwarden" {
    path = "/var/local/vaultwarden"
  }
}

acl {
  enabled = true
}

tls {
  http = true
  rpc  = true

  verify_https_client = false

  ca_file = "/etc/nomad.d/nomad-agent-ca.pem"
  cert_file = "/etc/nomad.d/global-server-nomad.pem"
  key_file = "/etc/nomad.d/global-server-nomad-key.pem"
}
