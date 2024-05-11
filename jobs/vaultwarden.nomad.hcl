job "vaultwarden" {
  group "vaultwarden" {
    count = 1

    network {
      port "http" {
        to = 80
      }
    }

    service {
      name     = "vaultwarden-web"
      port     = "http"
      provider = "nomad"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.vaultwarden.rule=Host(`vaultwarden.magnusson.space`)",
        "traefik.http.routers.vaultwarden.entrypoints=https",
        "traefik.http.routers.vaultwarden.tls.certresolver=default",
      ]
    }

    volume "vaultwarden" {
      type   = "host"
      source = "vaultwarden"
    }

    task "vaultwarden" {
      driver = "docker"

      resources {
        cpu    = 100
        memory = 150
      }

      volume_mount {
        volume      = "vaultwarden"
        destination = "/data"
      }

      config {
        image = "vaultwarden/server:alpine"
        ports = ["http"]
      }

      template {
        data = <<EOF
SIGNUPS_ALLOWED=false
DOMAIN=https://vaultwarden.magnusson.space
PUSH_ENABLED=true
{{ with nomadVar "nomad/jobs/vaultwarden" }}
PUSH_INSTALLATION_ID={{ .installation_id }}
PUSH_INSTALLATION_KEY={{ .installation_key }}
{{ end }}
EOF
        destination = "local/.env"
        env         = true
      }
    }
  }
}
