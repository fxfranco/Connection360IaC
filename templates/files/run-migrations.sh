#!/bin/bash
# Vuelve a ejecutar las migraciones Alembic ("alembic upgrade head") contra el PostgreSQL de esta instancia.
# Es idempotente: si no hay migraciones nuevas no cambia nada.
# Uso:  sudo /opt/connection360/run-migrations.sh
set -euo pipefail
cd /opt/connection360
docker compose pull migrations
docker compose run --rm migrations
