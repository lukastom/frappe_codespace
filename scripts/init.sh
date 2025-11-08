#!/bin/bash
set -e

WORKDIR="/workspace"
BENCH_DIR="$WORKDIR/frappe-bench"

echo "🚀 Running init.sh (WORKDIR: $WORKDIR)"

# Idempotentní: když už bench existuje, nic neřešíme
if [[ -f "$BENCH_DIR/apps/frappe/frappe/__init__.py" ]]; then
  echo "✅ Bench already exists, skipping init"
  exit 0
fi

cd "$WORKDIR"

echo "📦 bench init..."
bench init \
  --skip-redis-config-generation \
  frappe-bench

cd "$BENCH_DIR"

echo "🔧 Configure hosts for Docker services..."
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# (volitelné) vyhoď redis procesy z Procfile, řeší je kontejnery
if [[ -f Procfile ]]; then
  sed -i '/redis/d' Procfile || true
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

echo "✅ Init done."
echo "👉 In terminal run:"
echo "cd /workspace/frappe-bench"
echo "bench start"
