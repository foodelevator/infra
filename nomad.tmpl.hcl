data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"

advertise {
  http = "127.0.0.1"
  rpc  = "127.0.0.1"
  serf = "127.0.0.1"
}

server {
  enabled          = true
  bootstrap_expect = 1

  encrypt = "{{ .secret }}" # why not?
}

client {
  enabled = true
  servers = ["127.0.0.1"]

  host_volume "ca-certificates" {
    path = "/var/local/ca-certificates"
  }

  host_volume "static-files" {
    path = "/var/www/files"
  }

  host_volume "faktura-settings" {
    path = "/var/www/faktura"
  }

  host_volume "syncthing" {
    path = "/var/local/syncthing"
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
