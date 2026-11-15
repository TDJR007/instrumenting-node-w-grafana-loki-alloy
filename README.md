## Instructions For App Server

`vagrant ssh app`

## Add Grafana repo (app.sh didn't add it. So:)

```bash sudo apt-get install -y gpg wget
sudo mkdir -p /etc/apt/keyrings
sudo wget -q -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg-full.key
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update -q
sudo apt-get install -y alloy
```

## Setup Alloy

```bash sudo tee /etc/alloy/config.alloy << 'EOF'
loki.source.journal "app_logs" {
  forward_to = [loki.write.local.receiver]
  matches    = "_SYSTEMD_UNIT=my-telemetry-api.service"
  labels     = {
    job  = "my-telemetry-api",
    host = "app-server",
  }
}

loki.write "local" {
  endpoint {
    url = "http://192.168.56.10:3100/loki/api/v1/push"
  }
}
EOF

sudo systemctl restart alloy
sudo systemctl status alloy --no-pager
sudo systemctl enable --now alloy
```