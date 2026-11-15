# Ship Node.js Logs to Grafana Loki with Alloy

Demo environment for the [UnitOfWork video](https://youtube.com/@UnitOfWork).

Three VMs, three IPs — simulating a real multi-server setup:

| VM | IP | What runs |
|---|---|---|
| loki | 192.168.56.10 | Grafana Loki 3.7.9 |
| grafana | 192.168.56.11 | Grafana OSS 13.x |
| app | 192.168.56.20 | Node.js telemetry API + Alloy |

## Prerequisites

- VirtualBox
- Vagrant 2.4.1+

## Start the environment

```bash
vagrant up
```

Grafana is available at `http://localhost:3000` (admin/admin).

## App server — Alloy setup

Alloy is intentionally **not** provisioned automatically. Installing it on camera is the point of the video.

SSH in:

```bash
vagrant ssh app
# or with key: ssh -i $(vagrant ssh-config app | grep IdentityFile | awk '{print $2}') vagrant@192.168.56.20
```

Add the Grafana repo and install Alloy:

```bash
sudo apt-get install -y gpg wget
sudo mkdir -p /etc/apt/keyrings
sudo wget -q -O /etc/apt/keyrings/grafana.asc https://apt.grafana.com/gpg-full.key
echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update -q
sudo apt-get install -y alloy
```

Write the config:

```bash
sudo tee /etc/alloy/config.alloy << 'EOF'
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
```

Start and enable Alloy (`enable` survives reboots — easy thing to miss):

```bash
sudo systemctl restart alloy
sudo systemctl enable alloy
sudo systemctl status alloy --no-pager
```

## Generate test traffic

```bash
curl http://192.168.56.20:8080/
curl http://192.168.56.20:8080/test-error
```

## Query logs in Grafana

Add a Loki datasource pointing at `http://192.168.56.10:3100`, then in Explore:

```logql
{job="my-telemetry-api"}
{job="my-telemetry-api"} | json | level >= `50`
```

## Stop / resume

```bash
vagrant halt   # free RAM
vagrant up     # resume — no reprovisioning needed
```