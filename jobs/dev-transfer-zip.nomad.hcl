job "dev-transfer-zip" {
  group "web" {
    network {
      port "http" {
        to = 80
      }
      port "ws" {
        to = 8001
      }
    }

    service {
      name     = "dev-transfer-zip"
      port     = "http"
      provider = "nomad"

      tags = [
        "nginx.hostname=dev.transfer.zip",
        "nginx.certname=dev.transfer.zip",
      ]
    }

    task "web-server" {
      driver = "docker"

      resources {
        memory = 30
      }

      config {
        image = "localhost/transfer.zip-web:61c33eb"
        ports = ["http"]
        command = "sh"
        args = ["local/start.sh"]
      }

      template {
        data = <<EOF
sed -i "s/signaling-server:8001/$NOMAD_ADDR_ws/" /etc/nginx/conf.d/nginx.conf
run-server
EOF
        destination = "local/start.sh"
      }
    }

    task "signaling-server" {
      driver = "docker"

      resources {
        memory = 50
      }

      config {
        image = "localhost/transfer.zip-signal:61c33eb"
        ports = ["ws"]
      }
    }
  }
}
