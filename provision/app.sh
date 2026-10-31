#!/bin/bash
set -e

apt-get update -q
apt-get install -y -q curl

# Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y -q nodejs

# App
mkdir -p /opt/telemetry-api
cat > /opt/telemetry-api/package.json << 'EOF'
{
  "name": "telemetry-api",
  "version": "1.0.0",
  "type": "module",
  "main": "index.js",
  "dependencies": {
    "express": "^4.18.2",
    "pino": "^8.21.0"
  }
}
EOF

cat > /opt/telemetry-api/index.js << 'EOF'
import express from 'express'
import os from 'os'
import { execSync } from 'child_process'
import pino from 'pino'

const app = express()
const logger = pino({
  level: 'info',
  base: { service: 'telemetry-api', host: os.hostname() },
  timestamp: pino.stdTimeFunctions.isoTime
})

const PORT = process.env.PORT || 8080

const gb = bytes => (bytes / 1024 / 1024 / 1024).toFixed(2)

app.use((req, res, next) => {
  const start = process.hrtime.bigint()
  logger.info({ event: 'http.request.received', method: req.method, path: req.path }, 'Request received')
  res.on('finish', () => {
    const durationMs = Number(process.hrtime.bigint() - start) / 1e6
    logger.info({ event: 'http.request.completed', method: req.method, path: req.path, statusCode: res.statusCode, durationMs: Number(durationMs.toFixed(2)) }, 'Request completed')
  })
  next()
})

app.get('/', (req, res) => {
  const totalMem = os.totalmem()
  const freeMem = os.freemem()
  const disk = execSync('df -h / | tail -1').toString().trim().split(/\s+/)
  res.json({ uptime: `${(os.uptime() / 3600).toFixed(1)}h`, load: os.loadavg()[0].toFixed(2), memory: `${gb(totalMem - freeMem)} / ${gb(totalMem)} GB`, disk: `${disk[2]} / ${disk[1]} (${disk[4]})` })
})

app.get('/test-error', (req, res) => {
  const err = new Error('Synthetic error for log pipeline testing')
  logger.error({ event: 'test.error', err }, 'Test error generated')
  res.status(500).json({ message: 'Synthetic test error logged' })
})

app.listen(PORT, () => {
  logger.info({ event: 'server.started', port: PORT }, 'Telemetry API listening')
})
EOF

cd /opt/telemetry-api && npm install --omit=dev

# systemd service
cat > /etc/systemd/system/my-telemetry-api.service << 'EOF'
[Unit]
Description=Telemetry API Demo
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/telemetry-api
ExecStart=/usr/bin/node /opt/telemetry-api/index.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production PORT=8080
StandardOutput=journal
StandardError=journal
SyslogIdentifier=my-telemetry-api

[Install]
WantedBy=multi-user.target
EOF

# Persist journal to disk so Alloy can read it
mkdir -p /etc/systemd/journald.conf.d
echo -e '[Journal]\nStorage=persistent' > /etc/systemd/journald.conf.d/persistent.conf
systemctl restart systemd-journald

systemctl daemon-reload
systemctl enable --now my-telemetry-api