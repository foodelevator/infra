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
          "local/nginx.conf:/etc/nginx/nginx.conf",
          "local/virtual-hosting.conf:/etc/nginx/conf.d/virtual-hosting.conf",
        ]
      }

      template {
        data = <<EOF
user nginx;
worker_processes auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    server_names_hash_bucket_size 128;

    include /etc/nginx/conf.d/*.conf;
}
EOF

        destination   = "local/nginx.conf"
        change_signal = "SIGHUP"
      }
      template {
        data = <<EOF
{{- $hijackUpstream := false -}}
{{- range $s := nomadServices -}}
{{- range $tag := $s.Tags -}}
  {{- if eq $tag "nginx.acme-challenge" -}}
    {{- $hijackUpstream = true -}}
upstream acme-challenge {
  {{- range nomadService $s.Name }}
  server {{ .Address }}:{{ .Port }};
  {{- end }}
}
    {{- break -}}
  {{- end -}}
  {{- if $hijackUpstream -}}
    {{- break -}}
  {{- end -}}
{{- end -}}
{{- end }}
{{ if not $hijackUpstream }}
upstream acme-challenge {
  server magnusson.space:10101;
}
{{ end }}

map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

{{ range nomadServices -}}

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

{{ if eq $certname "" -}}
server {
  listen 80 {{ $default }};
  listen [::]:80 {{ $default }};
  http2 on;
  server_name {{ $hostname }};

  location /.well-known/acme-challenge {
    proxy_pass http://acme-challenge;
    proxy_set_header Host $host;
  }

  location / {
    proxy_pass http://{{ $upstream }};

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
  }
}

{{ else -}}
server {
  listen 80;
  listen [::]:80;
  http2 on;
  server_name http.{{ $hostname | sprig_trimPrefix "." }};

  location / {
    proxy_pass http://{{ $upstream }};

    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
  }
}

server {
  listen 443 ssl;
  listen [::]:443 ssl;
  http2 on;
  server_name http.{{ $hostname | sprig_trimPrefix "." }};

  ssl_certificate /var/local/certs/certificates/{{ $certname }}.crt;
  ssl_certificate_key /var/local/certs/certificates/{{ $certname }}.key;
  ssl_trusted_certificate /var/local/certs/certificates/{{ $certname }}.issuer.crt;

  return 301 http://$host$request_uri;
}

server {
  listen 80 {{ $default }};
  listen [::]:80 {{ $default }};
  http2 on;
  server_name {{ $hostname }};

  location /.well-known/acme-challenge {
    proxy_pass http://acme-challenge;
    proxy_set_header Host $host;
  }

  return 301 https://$host$request_uri;
}

server {
  listen 443 ssl {{ $default }};
  listen [::]:443 ssl {{ $default }};
  http2 on;
  server_name {{ $hostname }};

  ssl_certificate /var/local/certs/certificates/{{ $certname }}.crt;
  ssl_certificate_key /var/local/certs/certificates/{{ $certname }}.key;
  ssl_trusted_certificate /var/local/certs/certificates/{{ $certname }}.issuer.crt;

  location /.well-known/acme-challenge {
    proxy_pass http://acme-challenge;
    proxy_set_header Host $host;
  }

  location / {
    proxy_pass http://{{ $upstream }};

    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
  }
}
{{ end -}}

{{ end -}}
EOF

        destination   = "local/virtual-hosting.conf"
        change_signal = "SIGHUP"
      }
    }
  }
}
