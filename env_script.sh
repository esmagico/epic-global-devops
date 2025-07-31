#!/bin/bash

ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
  echo "$ENV_FILE not found!"
  exit 1
fi

echo "Checking passwords in $ENV_FILE..."

grep -Ei '(PASSWORD|SECRET|TOKEN)' "$ENV_FILE" | while IFS='=' read -r key value; do
  value=$(echo "$value" | tr -d '"') # remove quotes
  echo "$value" | cracklib-check | grep -q 'OK' || echo "⚠️ Weak: $key"
done
