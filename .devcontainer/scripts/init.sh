#!/bin/bash
set -e

WORKDIR="/workspace"
BENCH_DIR="$WORKDIR/frappe-bench"

echo "Initializing Frappe bench in $BENCH_DIR"

if [[ -f "$BENCH_DIR/apps/frappe/frappe/__init__.py" ]]; then
  echo "Bench already exists, skipping init"
  exit 0
fi

cd "$WORKDIR"

echo "bench init..."
bench init \
  --skip-redis-config-generation \
  --frappe-branch version-15 \
  frappe-bench

cd "$BENCH_DIR"

echo "Configure hosts for Docker services..."
bench set-config -g db_host mariadb
bench set-config -g redis_cache redis://redis-cache:6379
bench set-config -g redis_queue redis://redis-queue:6379
bench set-config -g redis_socketio redis://redis-socketio:6379

echo "Creating dev.localhost site..."
bench new-site dev.localhost \
  --mariadb-root-password 123 \
  --db-root-username root \
  --admin-password admin \
  --mariadb-user-host-login-scope='%' \
  --force

bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost

echo "Init done."
echo "In terminal run: cd frappe-bench && bench start"
