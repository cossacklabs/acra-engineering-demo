#!/bin/sh

files=(
  "/certs/node.key"
  "/certs/client.root.key"
)

# explicitly specify permissions for mounted key files
for file in "${files[@]}"; do
  chmod 600 "$file"
done

exec "$@"