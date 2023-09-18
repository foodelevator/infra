job "virtual-hosting" {
  group "nginx" {
    count = 1

    network {
      port "http" {
        static = 80
      }
      port "https" {
        static = 443
      }
    }

    volume "certs" {
      type      = "host"
      source    = "ca-certificates"
      read_only = true
    }

    task "nginx" {
      driver = "docker"

      resources {
        cpu    = 50
        memory = 20
      }

      volume_mount {
        volume      = "certs"
        destination = "/var/local/certs"
      }

      config {
        image = "nginx:1.25-alpine"
        ports = ["http", "https"]

        volumes = [
          "local:/etc/nginx/conf.d",
        ]
      }

      template {
        data = <<EOF
{{- range nomadServices -}}

{{- $hostname := "" -}}
{{- $certname := "" -}}
{{- $default := "" -}}
{{- range $tag := .Tags -}}
  {{- if $tag | regexMatch "nginx.hostname=" -}}
    {{- $hostname = $tag | replaceAll "nginx.hostname=" "" -}}
  {{- end -}}
  {{- if $tag | regexMatch "nginx.certname=" -}}
    {{- $certname = $tag | replaceAll "nginx.certname=" "" -}}
  {{- end -}}
  {{- if $tag | regexMatch "nginx.default_server" -}}
    {{- $default = "default_server" -}}
  {{- end -}}
{{- end -}}
{{- if eq $hostname "" -}}
  {{- continue -}}
{{- end -}}

{{- $upstream := .Name | toLower | regexReplaceAll "[^a-z0-9\\-._]" "" -}}

################################################
upstream {{ $upstream }} {
  {{- range nomadService .Name }}
  server {{ .Address }}:{{ .Port }};
  {{- end }}
}

server {
  listen 80 {{ $default }};
  listen [::]:80 {{ $default }};
  http2 on;
  server_name {{ $hostname }};

  location / {
    proxy_pass http://{{ $upstream }};

    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_set_header Upgrade $http_upgrade;
  }
}

{{ if ne $certname "" -}}
server {
  listen 443 ssl {{ $default }};
  listen [::]:443 ssl {{ $default }};
  http2 on;
  server_name {{ $hostname }};

  ssl_certificate /var/local/certs/certificates/{{ $certname }}.crt;
  ssl_certificate_key /var/local/certs/certificates/{{ $certname }}.key;
  ssl_trusted_certificate /var/local/certs/certificates/{{ $certname }}.issuer.crt;

  location / {
    proxy_pass http://{{ $upstream }};

    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_set_header Upgrade $http_upgrade;
  }
}
{{ end -}}

{{ end -}}
EOF

        destination   = "local/virtual-hosting.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}
