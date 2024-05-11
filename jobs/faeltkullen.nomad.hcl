job "faeltkullen" {
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
      name     = "faeltkullen"
      port     = "http"
      provider = "nomad"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.faeltkullen.rule=Host(`xn--fltkullen-v2a.magnusson.space`)||Host(`www.xn--fltkullen-v2a.magnusson.space`)",
        "traefik.http.routers.faeltkullen.entrypoints=https",
        "traefik.http.routers.faeltkullen.tls.certresolver=default",
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
  root /var/www/sites/fältkullen;
}
EOF
        destination = "local/website.conf"
      }
    }
  }
}
