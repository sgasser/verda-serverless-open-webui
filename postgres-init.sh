#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER litellm WITH PASSWORD '${LITELLM_DB_PASSWORD}';
    CREATE USER openwebui WITH PASSWORD '${OPENWEBUI_DB_PASSWORD}';

    CREATE DATABASE litellm OWNER litellm;
    CREATE DATABASE openwebui OWNER openwebui;

    GRANT ALL PRIVILEGES ON DATABASE litellm TO litellm;
    GRANT ALL PRIVILEGES ON DATABASE openwebui TO openwebui;
EOSQL

# Enable pgvector extension in openwebui database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "openwebui" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS vector;
EOSQL
