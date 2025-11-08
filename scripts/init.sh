#!/bin/bash

set -e

# Najdi root repozitáře relativně k tomuto skriptu
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Když už existuje bench appka, nic nedělej (Codespace restart apod.)
if [[ -f "$WORKDIR/frappe-bench/apps/frappe" ]]; then
    echo "Bench already exists, skipping init"
    exit 0
fi

# (Volitelné) Nesahal bych na .git, ale pokud chceš čistý workspace, nech:
# rm -rf "$WORKDIR/.git"

# Node verze přes nvm
if [[ -f "/home/frappe/.nvm/nvm.sh" ]]; then
    # shellcheck source=/dev/null
    source /home/frappe/.nvm/nvm.sh
    nvm alias default 18
    nvm use 18
    echo "nvm use 18" >> ~/.bashrc
fi

cd "$WORKDIR"

# Inicializuj bench (nevytváří site)
bench init \
  --ignore-exist \
  --skip-redis-config-generation \
  frappe-bench

cd "$WORKDIR/frappe-bench"

# Nastav kontejnery jako hosty
bench set-mariadb-host mariadb
bench set-redis-cache-host redis-cache:6379
bench set-redis-queue-host redis-queue:6379
bench set-redis-socketio-host redis-socketio:6379

# Vyhoď redis z Procfile (řeší kontejnery)
if [[ -f "./Procfile" ]]; then
  sed -i '/redis/d' ./Procfile || true
fi

# Vytvoř neinteraktivně site (tady se to dřív sekalo)
bench new-site dev.localhost \
  --mariadb-root-password 123 \
  --db-root-username root \
  --admin-password admin \
  --no-mariadb-socket \
  --force

bench --site dev.localhost set-config developer_mode 1
bench --site dev.localhost clear-cache
bench use dev.localhost

echo "✅ Init complete. You can now run: bench start"
