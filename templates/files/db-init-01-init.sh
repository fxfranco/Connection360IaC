#!/bin/bash
# Este script SOLO se ejecuta automaticamente la primera vez que el contenedor de Postgres
# levanta con un volumen de datos vacio (mismo script que Connection360DataBase/postgres_db/db-init).
# Docker ya crea la base de datos POSTGRES_DB antes de correr esto.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- ROL de aplicacion (agrupa permisos, no hace login directo)
    CREATE ROLE connection360apicore;

    -- Usuario final con el que se conectan las aplicaciones .NET
    CREATE USER apicore_user WITH PASSWORD '${APICORE_USER_PASSWORD}';

    GRANT connection360apicore TO apicore_user;
EOSQL

echo "Rol y usuario de aplicacion creados correctamente."
