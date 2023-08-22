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
        "nginx.hostname=.xn--srskildakommandorrelsegruppen-0pc88c.se",
        "nginx.certname=xn--srskildakommandorrelsegruppen-0pc88c.se",
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
