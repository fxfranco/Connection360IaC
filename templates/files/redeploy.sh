#!/bin/bash
# Descarga las imagenes y recrea los contenedores de esta instancia con la configuracion actual (.env).
# Uso:  sudo /opt/connection360/redeploy.sh
set -euo pipefail
cd /opt/connection360
docker compose pull
docker compose up -d
docker compose ps
