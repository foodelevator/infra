job "sh" {
  group "web" {
    network {
      port "http" {
        to = 80
      }
    }

    service {
      name     = "sh"
      port     = "http"
      provider = "nomad"

      tags = [
        "nginx.hostname=sh.magnusson.space",
        "nginx.certname=magnusson.space",
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
          "local/www:/var/www",
        ]
      }

      template {
        data = <<EOF
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  http2 on;

  root /var/www;
  location / {
    index index.txt;
  }
}
EOF
        destination = "local/config/website.conf"
      }

      template {
        data = <<EOF
echo "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEdUe7mxGdV/Q37RKndPzDHisFb7q/xm+L97jcGluSDOA8MGt/+wTxpyGxfyEqaMvwV2bakaMVHTB3711dDu5kE=" >> ~/.ssh/authorized_keys
systemctl enable ssh
systemctl enable sshd
command -v curl >/dev/null && S=curl || S=wget
S "sh.magnusson.space/$(whoami)" -O /dev/null
EOF
        destination = "local/www/index.txt"
      }
    }
  }
}
