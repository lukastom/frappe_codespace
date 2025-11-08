#!/bin/bash
set -e

# V Codespaces máme /workspace = root repozitáře
WORKDIR="/workspace"
BENCH_DIR="$WORKDIR/frappe-bench"

echo "🚀 Initializing Frappe bench in $BENCH_DIR"

# Když už bench existuje (třeba při restartu Codespace), skonči
if [[ -f "$BENCH_DIR/apps/frappe/frappe/__init__.py" ]]; then
  echo "✅ Bench already exists, skipping init"
  exit 0
fi

cd "$WORKDIR"

echo "📦 bench init..."
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
echo "➡️  Run in terminal: cd frappe-bench && bench start"
