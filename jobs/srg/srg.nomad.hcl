job "srg" {
  group "web" {
    count = 1

    network {
      port "http" {
        to = 80
      }
    }

    service {
      name     = "srg"
      port     = "http"
      provider = "nomad"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.srg.rule=Host(`xn--srskildakommandorrelsegruppen-0pc88c.se`)||Host(`www.xn--srskildakommandorrelsegruppen-0pc88c.se`)",
        "traefik.http.routers.srg.entrypoints=https",
        "traefik.http.routers.srg.tls.certresolver=default",
      ]
    }

    task "web" {
      driver = "docker"

      resources {
        cpu    = 50
        memory = 20
      }

      config {
        image = "nginx:1.25-alpine"
        ports = ["http"]

        volumes = [
          "local/config:/etc/nginx/conf.d",
          "local/html:/var/www/html",
        ]
      }

      template {
        data = <<EOF
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  http2 on;

  root /var/www/html;
  location / {
    index index.html;
  }
}
EOF
        destination = "local/config/website.conf"
      }

      template {
        data = file("jobs/srg/index.html")
        destination = "local/html/index.html"
      }
    }
  }
}
