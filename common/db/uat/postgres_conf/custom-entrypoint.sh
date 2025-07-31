#!/bin/bash
set -e 

# Check if the environment variable is set
if [ -z "${BACKEND_VM_IP}" ]; then
  echo "ERROR: The BACKEND_VM_IP environment variable is not set."
  exit 1
fi

# Substitute the IP address in the template and create the final pg_hba.conf
# Note: Using a different delimiter for sed to avoid issues with '/' in the IP
sed "s|__BACKEND_VM_IP__|${BACKEND_VM_IP}|g" /etc/postgresql/pg_hba.conf.template > /etc/postgresql/pg_hba.conf

# Set correct permissions for the generated file
chown postgres:postgres /etc/postgresql/pg_hba.conf
chmod 600 /etc/postgresql/pg_hba.conf


echo "Successfully generated pg_hba.conf with IP ${BACKEND_VM_IP}"

# Now, execute the original postgres command
# `exec` is important as it replaces the shell process with the postgres process
exec /usr/local/bin/docker-entrypoint.sh "$@"
