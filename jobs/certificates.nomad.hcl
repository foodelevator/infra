job "certificates" {
  type = "batch"

  periodic {
    cron = "@monthly"
  }

  group "lego" {
    restart {
      attempts = 1
      delay    = "1h"
    }

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
        command = "certs.sh"
      }

      template {
        data = <<EOF
#!/usr/bin/env bash
function dns() {
    [ -f "/lego/certificates/$1.key" ] && cmd="renew --days 45" || cmd=run
    /local/lego \
        --accept-tos \
        --path /lego \
        --email mathias+certs@magnusson.space \
        --dns cloudflare \
        $${@/#/-d=} \
        $cmd
}
dns magnusson.space *.magnusson.space
dns magnusson.wiki *.magnusson.wiki
dns xn--srskildakommandorrelsegruppen-0pc88c.se *.xn--srskildakommandorrelsegruppen-0pc88c.se
EOF
        destination = "local/certs.sh"
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

      artifact {
        source = "https://github.com/go-acme/lego/releases/download/v4.13.3/lego_v4.13.3_linux_amd64.tar.gz"
      }
    }
  }
}
