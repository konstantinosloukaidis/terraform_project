#!/bin/bash

echo "Waiting for PostgreSQL to be ready..."

echo "DB_PASSWORD: $DB_PASSWORD"
until PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" --set=sslmode=require -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 5
done

echo "Postgres is up - running init.sql"
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -p "$DB_PORT" --set=sslmode=require -f /app/init.sql

echo "Starting the application..."
uvicorn main:app --host 0.0.0.0 --port 8000
echo "Application started successfully."