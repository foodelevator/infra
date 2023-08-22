job "rr" {
  group "web" {
    network {
      port "http" {
        to = 80
      }
    }

    volume "files" {
      type      = "host"
      source    = "static-files"
      read_only = true
    }

    service {
      name     = "rr"
      port     = "http"
      provider = "nomad"

      tags = [
        "nginx.hostname=rr.magnusson.space",
        "nginx.certname=magnusson.space",
      ]
    }

    task "web" {
      driver = "docker"

      resources {
        cpu    = 50
        memory = 20
      }

      volume_mount {
        volume      = "files"
        destination = "/var/www"
      }

      config {
        image = "nginx:1.25-alpine"
        ports = ["http"]

        volumes = [
          "local:/etc/nginx/conf.d",
        ]
      }

      template {
        data = <<EOF
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  http2 on;

  autoindex off;
  root /var/www/sites/rr;
  index index.mp4;
}
EOF
        destination = "local/website.conf"
      }
    }
  }
}
