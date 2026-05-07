#!/usr/bin/env sh
set -eu

NODE_EXPORTER_VERSION="${NODE_EXPORTER_VERSION:-1.8.2}"
ARCH="${ARCH:-linux-amd64}"
INSTALL_DIR="/usr/local/bin"
SERVICE_FILE="/etc/systemd/system/node_exporter.service"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script with sudo or as root."
  exit 1
fi

cd "$TMP_DIR"
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
tar xzf "node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}.tar.gz"
install -m 0755 "node_exporter-${NODE_EXPORTER_VERSION}.${ARCH}/node_exporter" "$INSTALL_DIR/node_exporter"

cat > "$SERVICE_FILE" <<'EOF'
[Unit]
Description=Prometheus Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=nobody
Group=nogroup
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl restart node_exporter
systemctl status node_exporter --no-pager
