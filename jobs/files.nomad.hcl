job "files" {
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
      name     = "files"
      port     = "http"
      provider = "nomad"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.files.rule=Host(`files.magnusson.space`)",
        "traefik.http.routers.files.entrypoints=https",
        "traefik.http.routers.files.tls.certresolver=default",
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

  add_header X-Robots-Tag "noindex";
  autoindex on;
  root /var/www;
  location ~ /\. {
    autoindex off;
  }
}
EOF
        destination = "local/website.conf"
      }
    }
  }
}
