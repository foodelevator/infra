job "syncthing" {
  group "syncthing" {
    count = 1

    network {
      port "http" {
        to = 8384
      }
      port "sync" {
        static = 22000
      }
      port "discovery" {
        static = 21027
      }
    }

    service {
      name     = "syncthing-web"
      port     = "http"
      provider = "nomad"

      tags = [
        "nginx.hostname=syncthing.magnusson.space",
        "nginx.certname=magnusson.space",
      ]
    }

    volume "syncthing" {
      type   = "host"
      source = "syncthing"
    }

    task "syncthing" {
      driver = "docker"

      resources {
        cpu    = 100
        memory = 150
      }

      volume_mount {
        volume      = "syncthing"
        destination = "/config"
      }

      config {
        image = "linuxserver/syncthing:1.24.0"
        ports = ["sync", "discovery", "http"]
      }
    }
  }
}
