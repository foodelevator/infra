job "traefik" {
  type = "service"

  group "traefik" {
    count = 1

    network {
      port "http" {
        static = 80
      }

      port "https" {
        static = 443
      }
    }

    volume "certs" {
      type   = "host"
      source = "ca-certificates"
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:v3.0"
        network_mode = "host"

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
          "local/nomad-agent-ca.pem:/etc/traefik/nomad-agent-ca.pem",
          "local/dynamic-conf.yaml:/etc/traefik/dynamic-conf.yaml"
        ]
      }

      volume_mount {
        volume = "certs"
        destination = "/certificates"
      }

      template {
        data = <<EOF
-----BEGIN CERTIFICATE-----
MIIDDTCCArKgAwIBAgIRAIYjjhWbJ80SG4cXZF6bGVIwCgYIKoZIzj0EAwIwgcgx
CzAJBgNVBAYTAlVTMQswCQYDVQQIEwJDQTEWMBQGA1UEBxMNU2FuIEZyYW5jaXNj
bzEaMBgGA1UECRMRMTAxIFNlY29uZCBTdHJlZXQxDjAMBgNVBBETBTk0MTA1MRcw
FQYDVQQKEw5IYXNoaUNvcnAgSW5jLjEOMAwGA1UECxMFTm9tYWQxPzA9BgNVBAMT
Nk5vbWFkIEFnZW50IENBIDE3ODMwMTE2MzYzOTIwMDg3MDMyMTI4NzQyMTA5ODEy
MTE3MzMzMDAeFw0yMzA4MjAyMDE0MzdaFw0yODA4MTgyMDE0MzdaMIHIMQswCQYD
VQQGEwJVUzELMAkGA1UECBMCQ0ExFjAUBgNVBAcTDVNhbiBGcmFuY2lzY28xGjAY
BgNVBAkTETEwMSBTZWNvbmQgU3RyZWV0MQ4wDAYDVQQREwU5NDEwNTEXMBUGA1UE
ChMOSGFzaGlDb3JwIEluYy4xDjAMBgNVBAsTBU5vbWFkMT8wPQYDVQQDEzZOb21h
ZCBBZ2VudCBDQSAxNzgzMDExNjM2MzkyMDA4NzAzMjEyODc0MjEwOTgxMjExNzMz
MzAwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAQnSx/6sQkxGuL9kaDAyUGoqWYJ
bAzrBrhyNLMkjjYXQ7QrzSOIzGfUGj2A4AzpHbU0t9k+JKaVHaKevcPVFyLMo3sw
eTAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zApBgNVHQ4EIgQgqgrh
OUp/Z5bL0pf20U6mGO57+PdAU88f3U6MbvYPaqMwKwYDVR0jBCQwIoAgqgrhOUp/
Z5bL0pf20U6mGO57+PdAU88f3U6MbvYPaqMwCgYIKoZIzj0EAwIDSQAwRgIhAOuN
l6lMSJW7er6SN22jKxR+oxrk9755eKm0b4GCDscCAiEAjlyxJnwTSF1v23cCS4c+
V435uuYooblwdUaga7fTDkE=
-----END CERTIFICATE-----
EOF
        destination = "local/nomad-agent-ca.pem"
      }

      template {
        data = <<EOF
[entryPoints]
    [entryPoints.http]
        address = ":80"
        [entryPoints.http.http.redirections.entryPoint]
            to = "https"
            scheme = "https"
            permanent = "true"
    [entryPoints.https]
        address = ":443"

[accessLog]
[log]
    level = "INFO"

[api]
    dashboard = true

[certificatesResolvers.default.acme]
    email = "mathias+certs@magnusson.space"
    storage = "/certificates/acme.json"
    [certificatesResolvers.default.acme.httpChallenge]
        entryPoint = "http"

# Enable Consul Catalog configuration backend.
[providers.nomad]
    prefix           = "traefik"
    exposedByDefault = false

    [providers.nomad.endpoint]
        address = "https://127.0.0.1:4646"
        token = "{{ with nomadVar "nomad/jobs/traefik" }}{{ .nomad_token }}{{ end }}"
        [providers.nomad.endpoint.tls]
            ca = "/etc/traefik/nomad-agent-ca.pem"
[providers.file]
    filename = "/etc/traefik/dynamic-conf.yaml"
EOF

        destination = "local/traefik.toml"
      }

      template {
        data = <<YAML
http:
  routers:
    api:
      rule: Host(`traefik.magnusson.space`)
      service: api@internal
      middlewares:
        - auth
      tls:
        certResolver: default
      entrypoints: https
  middlewares:
    auth:
      basicAuth:
        users:
          - mathias:$2y$05$NvMwyf/U2jh9TCYdxj8JbeDhFMGPBDid2IypQPebx4rk5WLOwR1M2
YAML
        destination = "local/dynamic-conf.yaml"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
