#!/bin/bash
set -e

WORKDIR="/workspace"
BENCH_DIR="$WORKDIR/frappe-bench"

echo "🚀 Init Frappe bench in $BENCH_DIR"

# Pokud už bench existuje (třeba při restartu Codespacu), nic nedělej
if [[ -f "$BENCH_DIR/apps/frappe/frappe/__init__.py" ]]; then
  echo "✅ Bench already exists, skipping init"
  exit 0
fi

# NVM (pokud je k dispozici v image)
if [[ -f "/home/frappe/.nvm/nvm.sh" ]]; then
  # shellcheck disable=SC1091
  source /home/frappe/.nvm/nvm.sh
  nvm alias default 18 || true
  nvm use 18 || true
  echo "nvm use 18" >> /home/frappe/.bashrc
fi

cd "$WORKDIR"

echo "📦 Running bench init..."
bench init \
  --skip-redis-config-generation \
  --frappe-branch version-15 \
  frappe-bench

cd "$BENCH_DIR"

echo "🔧 Configure hosts for Docker services..."
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# ochrana: kdyby náhodou Procfile nebyl, vytvoříme základ
if [[ ! -f Procfile ]]; then
  cat > Procfile <<EOF
web: bench serve --port 8000
worker-short: bench worker --queue short
worker-long: bench worker --queue long
worker-default: bench worker --queue default
schedule: bench schedule
socketio: node apps/frappe/socketio.js
EOF
fi

echo "🌐 Creating dev.localhost site..."
bench new-site dev.localhost \
  --mariadb-root-password 123 \
  --db-root-username root \
  --admin-password admin \
  --no-mariadb-socket \
  --force

bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost

echo "✅ Init complete. In terminal run:"
echo "cd /workspace/frappe-bench"
echo "bench start"
