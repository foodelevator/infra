job "försäkr.ing" {
  group "web" {
    count = 1

    network {
      port "http" {
        to = 80
      }
    }

    service {
      name     = "forsakring"
      port     = "http"
      provider = "nomad"

      tags = [
        "nginx.hostname=.xn--frskr-ira7j.ing",
        "nginx.certname=xn--frskr-ira7j.ing",
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
        data = file("jobs/försäkr.ing/index.html")
        destination = "local/html/index.html"
      }
    }
  }
}
