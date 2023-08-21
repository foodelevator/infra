job "certificates" {
  type = "batch"

  periodic {
    cron = "@monthly"
  }

  group "lego" {
    volume "certs" {
      type   = "host"
      source = "ca-certificates"
    }

    task "lego" {
      driver = "exec"

      volume_mount {
        volume      = "certs"
        destination = "/lego"
      }

      config {
        command = "lego"
        args = [
          "--accept-tos",
          "--path", "/lego",
          "--email", "mathias+certs@magnusson.space",
          "--dns", "cloudflare",
          "-d", "magnusson.wiki", "-d", "*.magnusson.wiki",
          "run"
        ]
      }

      artifact {
        source = "https://github.com/go-acme/lego/releases/download/v4.13.3/lego_v4.13.3_linux_amd64.tar.gz"
      }

      template {
        data = <<EOF
{{ with nomadVar "nomad/jobs/certificates" }}
CLOUDFLARE_DNS_API_TOKEN={{ .cloudflare_dns_api_token }}
{{ end }}
EOF
        destination = "local/.env"
        env         = true
      }
    }
  }
}
