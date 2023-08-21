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
