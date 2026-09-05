#!/usr/bin/env bash

echo "Waiting for Debezium Connect API at http://localhost:8083 to be ready..."

until curl -s -f http://localhost:8083/connectors > /dev/null; do
  echo "Debezium Connect is starting up..."
  sleep 4
done

echo "Debezium Connect is UP! Registering PostgreSQL connector..."

curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
  http://localhost:8083/connectors/ \
  -d @debezium/register-postgres.json

echo ""
echo "Connector registered! Current connectors:"
curl -s http://localhost:8083/connectors
echo ""
