job "certificates" {
  type = "batch"

  periodic {
    crons = ["@monthly"]
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

    network {
      port "http" {
        # static = 80
      }
    }

    service {
      name     = "certificates"
      port     = "http"
      provider = "nomad"

      tags = [
        "nginx.acme-challenge",
      ]
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

function cert() {
    # --server "https://acme-staging-v02.api.letsencrypt.org/directory"
    /local/lego \
        --accept-tos \
        --path /lego \
        --email mathias+certs@magnusson.space \
        "$@"
}

function dns() {
    [ -f "/lego/certificates/$1.key" ] && cmd="renew --no-random-sleep --days 45" || cmd=run
    cert --dns cloudflare $${@/#/-d=} $cmd
}

function http() {
    [ -f "/lego/certificates/$1.key" ] && cmd="renew --no-random-sleep --days 45" || cmd=run
    cert --http --http.port ":$NOMAD_PORT_http" $${@/#/-d=} $cmd
}

dns magnusson.space *.magnusson.space
dns magnusson.wiki *.magnusson.wiki
dns xn--srskildakommandorrelsegruppen-0pc88c.se *.xn--srskildakommandorrelsegruppen-0pc88c.se
dns xn--hvd-sna.ing *.xn--hvd-sna.ing
dns xn--frskr-ira7j.ing *.xn--frskr-ira7j.ing
dns besiktn.ing *.besiktn.ing
http dinlugnastund.se www.dinlugnastund.se
http transfer.zip www.transfer.zip
CLOUDFLARE_DNS_API_TOKEN=$CTFTAJM_TOKEN dns ctftajm.se *.ctftajm.se
EOF
        destination = "local/certs.sh"
      }

      template {
        data = <<EOF
{{ with nomadVar "nomad/jobs/certificates" }}
CLOUDFLARE_DNS_API_TOKEN={{ .cloudflare_dns_api_token }}
CTFTAJM_TOKEN={{ .cloudflare_dns_api_token_ctftajm }}
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
