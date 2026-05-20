#!/bin/bash
set -e

rm -f /app/tmp/pids/server.pid

until pg_isready -h "${DATABASE_HOST}" -U "${DATABASE_USERNAME}" -q; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done

bundle exec rails db:prepare

exec "$@"
